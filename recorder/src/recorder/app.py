"""
Ambient meeting recorder.

Captures mic + system audio via parec (PulseAudio/PipeWire), detects speech
using RMS energy, transcribes via whisper-server, cleans up via llama-server,
appends to daily transcript.

Audio capture pattern from github.com/goodroot/hyprwhspr (parec + .monitor).
Speech detection from the original meeting-recorder.py on this repo's main branch.
"""

import queue
import signal
import subprocess
import sys
import tempfile
import threading
import time
import traceback
from datetime import datetime
from pathlib import Path

import array
import math

from recorder.config import AudioConfig, Config, load_config
from recorder.signals import KwinMonitor, MeetParticipantMonitor, SilenceMonitor
from recorder.transcribe import cleanup_text, make_wav, texts_overlap, transcribe_chunk
from recorder.transcript import DailyTranscript

SAMPLE_RATE = 16000
FRAME_BYTES = SAMPLE_RATE * 2  # 1 second of s16le mono
SPEECH_RMS_THRESHOLD = 0.002  # Permissive per-frame gate; server-side VAD makes the real call
CHUNK_RMS_THRESHOLD = 0.003  # Whole-chunk gate to avoid sending dead silence over HTTP
MIN_CHUNK_SECS = 10  # Short clips cause whisper hallucination
CHUNK_MAX_SECS = 45


def compute_rms(pcm: bytes) -> float:
    if len(pcm) < 2:
        return 0.0
    samples = array.array("h", pcm)
    return math.sqrt(sum(s * s for s in samples) / len(samples)) / 32768.0



class Recorder:
    def __init__(self, config: Config):
        self.config = config
        self.transcript = DailyTranscript(config.transcript.output_dir)
        self._paused = False
        self._stopping = False
        self._last_system_text = ""
        self._chunks_processed = 0
        self._start_time = time.time()
        self._work_dir = Path(tempfile.mkdtemp(prefix="recorder."))
        self._chunk_num = 0
        self._silence_monitor = SilenceMonitor(self.transcript, config.signals, self._log)
        self._signal_monitors: list = []

    def run(self):
        signal.signal(signal.SIGTERM, lambda *_: self._stop())
        signal.signal(signal.SIGINT, lambda *_: self._stop())

        self._transcription_queue: queue.Queue = queue.Queue()

        self._log("started")
        self._log(f"transcript: {self.transcript.path}")
        self._log(f"whisper: {self.config.whisper.url}")
        self._log(f"llm: {self.config.llm.url}")

        ts = datetime.now().strftime("%H:%M:%S")
        self.transcript.append(ts, "🟢 rec", "started")

        transcription_thread = threading.Thread(
            target=self._transcription_worker, daemon=True
        )
        transcription_thread.start()

        input_thread = threading.Thread(target=self._input_loop, daemon=True)
        input_thread.start()

        self._start_signals()

        try:
            self._capture_loop()
        except Exception:
            self._log(f"ERROR: {traceback.format_exc()}")
        finally:
            self._stop_signals()
            self._transcription_queue.put(None)
            transcription_thread.join(timeout=30)
            self._cleanup()

    def _stop(self):
        self._stopping = True

    def _start_signals(self):
        kw = KwinMonitor(self.transcript, self.config.signals, self._log)
        kw.start()
        self._signal_monitors.append(kw)
        mp = MeetParticipantMonitor(self.transcript, self.config.signals, self._log)
        mp.start()
        self._signal_monitors.append(mp)
        self._log("signals started")

    def _stop_signals(self):
        for m in self._signal_monitors:
            m.stop()

    def _capture_loop(self):
        """Record audio continuously, emit chunks on silence boundaries.

        Accumulates audio 1 second at a time. Emits a chunk when:
        - Silence detected after MIN_CHUNK_SECS of speech
        - Max duration (CHUNK_MAX_SECS) reached

        Discards accumulated audio if it never exceeds the RMS threshold.
        """
        audio_cfg = self.config.audio

        monitor = self._get_monitor_source()
        mic_source = self._get_mic_source()
        self._log(f"system: {monitor}")
        self._log(f"mic: {mic_source}")

        # parec streams raw PCM indefinitely — never dies on pause/resume.
        # Pattern from github.com/goodroot/hyprwhspr utils/meeting-recorder.py
        sys_proc = self._start_parec(monitor, audio_cfg)
        mic_proc = self._start_parec(mic_source, audio_cfg)

        sys_buf = bytearray()
        mic_buf = bytearray()
        has_speech = False
        consecutive_silent_secs = 0
        was_speech = False

        self._log("listening")

        try:
            while not self._stopping:
                if self._paused:
                    time.sleep(0.1)
                    continue

                sys_data = sys_proc.stdout.read(FRAME_BYTES)
                mic_data = mic_proc.stdout.read(FRAME_BYTES)
                if not sys_data:
                    self._log("system audio ended")
                    break

                sys_buf.extend(sys_data)
                mic_buf.extend(mic_data or b"\x00" * FRAME_BYTES)

                sys_rms = compute_rms(sys_data)
                mic_rms = compute_rms(mic_data) if mic_data else 0.0
                second_has_speech = (
                    sys_rms >= SPEECH_RMS_THRESHOLD
                    or mic_rms >= SPEECH_RMS_THRESHOLD
                )

                if second_has_speech:
                    if not was_speech:
                        src = []
                        if sys_rms >= SPEECH_RMS_THRESHOLD:
                            src.append(f"sys={sys_rms:.4f}")
                        if mic_rms >= SPEECH_RMS_THRESHOLD:
                            src.append(f"mic={mic_rms:.4f}")
                        self._log(f"speech detected ({', '.join(src)})")
                        was_speech = True
                    has_speech = True
                    consecutive_silent_secs = 0
                    self._silence_monitor.reset()
                else:
                    if was_speech and consecutive_silent_secs == 1:
                        self._log("silence")
                        was_speech = False
                    consecutive_silent_secs += 1
                    self._silence_monitor.tick(consecutive_silent_secs)

                buf_secs = len(sys_buf) / (SAMPLE_RATE * 2)

                # Emit chunk when: silence after enough speech, or max duration
                should_emit = False
                if has_speech and buf_secs >= MIN_CHUNK_SECS:
                    if consecutive_silent_secs >= 1:
                        should_emit = True
                    elif buf_secs >= CHUNK_MAX_SECS:
                        should_emit = True

                # Discard if we've accumulated a lot of silence without speech
                if not has_speech and buf_secs >= 5:
                    sys_buf.clear()
                    mic_buf.clear()
                    consecutive_silent_secs = 0
                    continue

                if should_emit:
                    trim_bytes = max(0, (consecutive_silent_secs - 1)) * FRAME_BYTES
                    if trim_bytes > 0 and trim_bytes < len(sys_buf):
                        sys_pcm = bytes(sys_buf[:-trim_bytes])
                        mic_pcm = bytes(mic_buf[:-trim_bytes])
                    else:
                        sys_pcm = bytes(sys_buf)
                        mic_pcm = bytes(mic_buf)

                    self._emit_chunk(sys_pcm, mic_pcm)
                    sys_buf.clear()
                    mic_buf.clear()
                    has_speech = False
                    consecutive_silent_secs = 0
                    was_speech = False

            # Flush remaining audio on stop
            if has_speech and len(sys_buf) >= MIN_CHUNK_SECS * SAMPLE_RATE * 2:
                self._emit_chunk(bytes(sys_buf), bytes(mic_buf))

        finally:
            self._terminate(sys_proc)
            self._terminate(mic_proc)

    def _emit_chunk(self, sys_pcm: bytes, mic_pcm: bytes):
        self._chunk_num += 1
        timestamp = datetime.now().strftime("%H:%M:%S")
        duration = len(sys_pcm) / (SAMPLE_RATE * 2)
        sys_rms = compute_rms(sys_pcm)
        mic_rms = compute_rms(mic_pcm)

        if sys_rms < CHUNK_RMS_THRESHOLD and mic_rms < CHUNK_RMS_THRESHOLD:
            self._log(
                f"chunk #{self._chunk_num}: {duration:.0f}s "
                f"sys={sys_rms:.4f} mic={mic_rms:.4f} (below chunk threshold, skipped)"
            )
            return

        sys_path = self._work_dir / f"sys_{self._chunk_num}.wav"
        sys_path.write_bytes(make_wav(sys_pcm))

        mic_path = self._work_dir / f"mic_{self._chunk_num}.wav"
        mic_path.write_bytes(make_wav(mic_pcm))

        self._log(
            f"chunk #{self._chunk_num}: {duration:.0f}s "
            f"sys={sys_rms:.4f} mic={mic_rms:.4f}"
        )
        self._transcription_queue.put((sys_path, mic_path, timestamp))

    def _transcription_worker(self):
        while True:
            item = self._transcription_queue.get()
            if item is None:
                break
            sys_path, mic_path, timestamp = item
            self._log("transcribing")
            t0 = time.time()
            self._transcribe_chunk(sys_path, mic_path, timestamp)
            elapsed = time.time() - t0
            self._log(f"transcribed in {elapsed:.1f}s")

    def _transcribe_chunk(self, sys_path: Path, mic_path: Path, timestamp: str):
        try:
            sys_text = transcribe_chunk(sys_path, self.config.whisper)
            mic_text = transcribe_chunk(mic_path, self.config.whisper)

            sys_path.unlink(missing_ok=True)
            mic_path.unlink(missing_ok=True)

            if sys_text:
                cleaned = cleanup_text(sys_text, self.config.llm) or sys_text
                if cleaned:
                    self.transcript.append(timestamp, "\U0001f50a sys", cleaned)
                    self._last_system_text = cleaned
                    self._log(f"sys: {cleaned[:80]}")
                else:
                    self._log("sys: (hallucination removed)")

                if mic_text and not texts_overlap(
                    cleaned or sys_text, mic_text, self.config.dedup.threshold
                ):
                    mic_cleaned = cleanup_text(mic_text, self.config.llm) or mic_text
                    if mic_cleaned:
                        self.transcript.append(timestamp, "\U0001f3a4 mic", mic_cleaned)
                        self._log(f"mic: {mic_cleaned[:80]}")
                    else:
                        self._log("mic: (hallucination removed)")
                elif mic_text:
                    self._log(f"mic: (dedup) {mic_text[:60]}")
            elif mic_text:
                if self._last_system_text and texts_overlap(
                    self._last_system_text, mic_text, self.config.dedup.threshold
                ):
                    self._log(f"mic: (dedup) {mic_text[:60]}")
                else:
                    cleaned = cleanup_text(mic_text, self.config.llm) or mic_text
                    if cleaned:
                        self.transcript.append(timestamp, "\U0001f3a4 mic", cleaned)
                        self._log(f"mic: {cleaned[:80]}")
                    else:
                        self._log("mic: (hallucination removed)")
            else:
                self._log("(no speech detected)")

            self._chunks_processed += 1
            self._log("listening")
        except Exception as e:
            self._log(f"transcription error: {e}")
            self._log("listening")

    def _input_loop(self):
        import tty
        import termios

        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        try:
            tty.setcbreak(fd)
            while not self._stopping:
                ch = sys.stdin.read(1)
                if ch == "q":
                    self._stop()
                elif ch == "p":
                    self._paused = not self._paused
                    self._log("paused" if self._paused else "listening")
                elif ch == "s":
                    timestamp = datetime.now().strftime("%H:%M:%S")
                    self.transcript.append(timestamp, "📍 pin")
                    self._log("split")
                elif ch == "n":
                    sys.stdout.write("\nnote: ")
                    sys.stdout.flush()
                    termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
                    text = sys.stdin.readline().strip()
                    tty.setcbreak(fd)
                    if text:
                        timestamp = datetime.now().strftime("%H:%M:%S")
                        self.transcript.append(timestamp, "\U0001f4dd nfo", text)
                        self._log(f"note: {text}")
        except (EOFError, OSError):
            pass
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

    def _log(self, msg: str):
        ts = datetime.now().strftime("%H:%M:%S")
        print(f"[{ts}] {msg}", flush=True)

    # parec + .monitor: always-on, full digital level regardless of sink volume,
    # outputs silence when nothing plays. Same pattern as hyprwhspr/goodroot.
    def _get_monitor_source(self) -> str:
        result = subprocess.run(
            ["pactl", "get-default-sink"], capture_output=True, text=True, timeout=5
        )
        return f"{result.stdout.strip()}.monitor"

    def _get_mic_source(self) -> str:
        result = subprocess.run(
            ["pactl", "get-default-source"], capture_output=True, text=True, timeout=5
        )
        return result.stdout.strip()

    def _start_parec(self, device: str, audio_cfg: AudioConfig) -> subprocess.Popen:
        # parec streams raw PCM indefinitely (no WAV headers, no EOF on pause).
        # Pattern from github.com/goodroot/hyprwhspr utils/meeting-recorder.py
        return subprocess.Popen(
            [
                "parec",
                f"--device={device}",
                f"--rate={audio_cfg.sample_rate}",
                "--channels=1",
                "--format=s16le",
                "--raw",
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )

    def _terminate(self, proc: subprocess.Popen):
        try:
            proc.terminate()
            proc.wait(timeout=3)
        except (ProcessLookupError, subprocess.TimeoutExpired):
            try:
                proc.kill()
            except ProcessLookupError:
                pass

    def _cleanup(self):
        ts = datetime.now().strftime("%H:%M:%S")
        self.transcript.append(ts, "🔴 rec", "stopped")
        for f in self._work_dir.iterdir():
            f.unlink(missing_ok=True)
        self._work_dir.rmdir()
        self._log("\nstopped")


def main():
    config = load_config()
    recorder = Recorder(config)
    recorder.run()
