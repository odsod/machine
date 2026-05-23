"""
Ambient meeting recorder.

Captures mic + system audio via parec (PulseAudio/PipeWire), detects speech
using RMS energy, transcribes via whisper-server, cleans up via llama-server,
appends to daily transcript with inline speaker attribution.

Architecture: the transcription worker is the sole writer to the transcript
file. Signal collectors write to in-memory timelines; the worker queries
these when processing each chunk.
"""

import queue
import signal
import subprocess
import sys
import tempfile
import threading
import time
import traceback
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

import array
import math

from recorder.config import AudioConfig, Config, load_config
from recorder.lock import LockError, RecorderLock
from recorder.segmenter import IncrementalSegmenter
from recorder.signals import SilenceMonitor, SpeakerCollector, WindowCollector
from recorder.timeline import ParticipantSet, SpeakerTimeline, WindowTimeline
from recorder.transcribe import cleanup_text, make_wav, texts_overlap, transcribe_chunk
from recorder.transcript import DailyTranscript, format_message

SAMPLE_RATE = 16000
FRAME_BYTES = SAMPLE_RATE * 2  # 1 second of s16le mono
SPEECH_RMS_THRESHOLD = 0.002
CHUNK_RMS_THRESHOLD = 0.0025
MIN_CHUNK_SECS = 10
CHUNK_MAX_SECS = 45


@dataclass
class AudioChunk:
    sys_path: Path
    mic_path: Path
    start_time: datetime
    end_time: datetime


def compute_rms(pcm: bytes) -> float:
    if len(pcm) < 2:
        return 0.0
    samples = array.array("h", pcm)
    return math.sqrt(sum(s * s for s in samples) / len(samples)) / 32768.0


class Recorder:
    def __init__(self, config: Config):
        self.config = config
        self.transcript = DailyTranscript(config.transcript.output_dir)
        self._lock = RecorderLock(config.transcript.output_dir)
        self._paused = False
        self._stopping = False
        self._last_system_text = ""
        self._chunks_processed = 0
        self._start_time = time.time()
        self._work_dir = Path(tempfile.mkdtemp(prefix="recorder."))
        self._chunk_num = 0
        self._capture_procs: list = []

        self._speaker_timeline = SpeakerTimeline()
        self._participant_set = ParticipantSet()
        self._window_timeline = WindowTimeline()

        self._silence_monitor = SilenceMonitor(
            config.signals.silence_threshold_secs, self._log
        )

        inbox_dir = Path.home() / "Vaults/odsod/inbox"
        self._segmenter = IncrementalSegmenter(
            transcript=self.transcript,
            llm_config=config.llm,
            inbox_dir=inbox_dir,
            log=self._log,
        )

        self._speaker_collector = SpeakerCollector(
            self._speaker_timeline, self._participant_set, config.signals, self._log
        )
        self._window_collector = WindowCollector(
            self._window_timeline, config.signals, self._log
        )

        self._last_flushed_time: datetime | None = None
        self._last_ppl_set: set[str] = set()

    def run(self):
        signal.signal(signal.SIGTERM, lambda *_: self._stop())
        signal.signal(signal.SIGINT, self._handle_sigint)

        self._lock.acquire()

        self._transcription_queue: queue.Queue = queue.Queue()

        self._log(format_message("🟢 rec", "started"))
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

        self._speaker_collector.start()
        self._window_collector.start()
        self._log("signals started")

        try:
            self._capture_loop()
        except Exception:
            self._log(f"ERROR: {traceback.format_exc()}")
        finally:
            self._speaker_collector.stop()
            self._window_collector.stop()
            self._transcription_queue.put(None)
            transcription_thread.join(timeout=30)
            self._cleanup()

    def _stop(self):
        self._stopping = True
        self._log("stopping...")
        for proc in self._capture_procs:
            self._terminate(proc)

    def _handle_sigint(self, *_):
        self._stop()

    def _capture_loop(self):
        """Record audio continuously, emit chunks on silence boundaries."""
        audio_cfg = self.config.audio

        monitor = self._get_monitor_source()
        mic_source = self._get_mic_source()
        self._log(f"system: {monitor}")
        self._log(f"mic: {mic_source}")

        sys_proc = self._start_parec(monitor, audio_cfg)
        mic_proc = self._start_parec(mic_source, audio_cfg)
        self._capture_procs = [sys_proc, mic_proc]

        sys_buf = bytearray()
        mic_buf = bytearray()
        has_speech = False
        consecutive_silent_secs = 0
        was_speech = False
        chunk_start_time: datetime | None = None

        self._log("listening")

        try:
            while not self._stopping:
                if self._paused:
                    time.sleep(0.1)
                    continue

                self._lock.heartbeat()

                sys_data = sys_proc.stdout.read(FRAME_BYTES)
                mic_data = mic_proc.stdout.read(FRAME_BYTES)
                if not sys_data:
                    self._log("system audio ended")
                    break

                if not chunk_start_time:
                    chunk_start_time = datetime.now()

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
                    if self._silence_monitor.tick(consecutive_silent_secs):
                        mins = consecutive_silent_secs // 60
                        ts = datetime.now().strftime("%H:%M:%S")
                        self.transcript.append(ts, "💤 idl", f"{mins} min")
                        self._log(format_message("💤 idl", f"{mins} min"))
                    self._segmenter.on_silence(consecutive_silent_secs)

                buf_secs = len(sys_buf) / (SAMPLE_RATE * 2)

                should_emit = False
                if has_speech and buf_secs >= MIN_CHUNK_SECS:
                    if consecutive_silent_secs >= 1:
                        should_emit = True
                    elif buf_secs >= CHUNK_MAX_SECS:
                        should_emit = True

                if not has_speech and buf_secs >= 5:
                    sys_buf.clear()
                    mic_buf.clear()
                    consecutive_silent_secs = 0
                    chunk_start_time = None
                    continue

                if should_emit:
                    trim_bytes = max(0, (consecutive_silent_secs - 1)) * FRAME_BYTES
                    if trim_bytes > 0 and trim_bytes < len(sys_buf):
                        sys_pcm = bytes(sys_buf[:-trim_bytes])
                        mic_pcm = bytes(mic_buf[:-trim_bytes])
                    else:
                        sys_pcm = bytes(sys_buf)
                        mic_pcm = bytes(mic_buf)

                    self._emit_chunk(sys_pcm, mic_pcm, chunk_start_time or datetime.now())
                    sys_buf.clear()
                    mic_buf.clear()
                    has_speech = False
                    consecutive_silent_secs = 0
                    was_speech = False
                    chunk_start_time = None

            if has_speech and len(sys_buf) >= MIN_CHUNK_SECS * SAMPLE_RATE * 2:
                self._emit_chunk(
                    bytes(sys_buf), bytes(mic_buf), chunk_start_time or datetime.now()
                )

        finally:
            self._terminate(sys_proc)
            self._terminate(mic_proc)

    def _emit_chunk(self, sys_pcm: bytes, mic_pcm: bytes, start_time: datetime):
        self._chunk_num += 1
        end_time = datetime.now()
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
        self._transcription_queue.put(AudioChunk(
            sys_path=sys_path,
            mic_path=mic_path,
            start_time=start_time,
            end_time=end_time,
        ))

    def _transcription_worker(self):
        while True:
            item = self._transcription_queue.get()
            if item is None:
                break
            chunk: AudioChunk = item
            self._log("transcribing")
            t0 = time.time()
            self._transcribe_chunk(chunk)
            elapsed = time.time() - t0
            self._log(f"transcribed in {elapsed:.1f}s")

    def _transcribe_chunk(self, chunk: AudioChunk):
        try:
            sys_text = transcribe_chunk(chunk.sys_path, self.config.whisper)
            mic_text = transcribe_chunk(chunk.mic_path, self.config.whisper)

            chunk.sys_path.unlink(missing_ok=True)
            chunk.mic_path.unlink(missing_ok=True)

            timestamp = chunk.start_time.strftime("%H:%M:%S")

            self._flush_signal_events(chunk.start_time, chunk.end_time)

            speakers = self._speaker_timeline.speakers_in(
                chunk.start_time, chunk.end_time
            )

            if sys_text:
                cleaned = cleanup_text(sys_text, self.config.llm) or sys_text
                if cleaned:
                    self.transcript.append(
                        timestamp, "\U0001f50a sys", cleaned,
                        speakers=speakers or None,
                    )
                    self._last_system_text = cleaned
                    speaker_str = f" [{', '.join(speakers)}]" if speakers else ""
                    self._log(format_message("\U0001f50a sys", f"{speaker_str} {cleaned[:80]}"))
                    self._segmenter.on_speech(chunk.start_time, "sys", cleaned)
                else:
                    self._log("sys: (hallucination removed)")

                if mic_text and not texts_overlap(
                    cleaned or sys_text, mic_text, self.config.dedup.threshold
                ):
                    mic_cleaned = cleanup_text(mic_text, self.config.llm) or mic_text
                    if mic_cleaned:
                        self.transcript.append(
                            timestamp, "\U0001f3a4 mic", mic_cleaned,
                            speakers=speakers or None,
                        )
                        self._log(format_message("\U0001f3a4 mic", mic_cleaned[:80]))
                        self._segmenter.on_speech(chunk.start_time, "mic", mic_cleaned)
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
                        self.transcript.append(
                            timestamp, "\U0001f3a4 mic", cleaned,
                            speakers=speakers or None,
                        )
                        self._log(format_message("\U0001f3a4 mic", cleaned[:80]))
                        self._segmenter.on_speech(chunk.start_time, "mic", cleaned)
                    else:
                        self._log("mic: (hallucination removed)")
            else:
                self._log("(no speech detected)")

            self._chunks_processed += 1
            self._log("listening")
        except Exception as e:
            self._log(f"transcription error: {e}")
            self._log("listening")

    def _flush_signal_events(self, start: datetime, end: datetime):
        """Write window and participant events for this chunk's time window."""
        flush_start = self._last_flushed_time or start
        self._last_flushed_time = end

        window_events = self._window_timeline.events_between(flush_start, end)
        for we in window_events:
            ts = we.time.strftime("%H:%M:%S")
            msg = f"\"{we.title}\" {we.action}"
            self.transcript.append(ts, "\U0001fa9f win", msg)
            self._log(format_message("\U0001fa9f win", msg))
            self._segmenter.on_signal(we.time, "win", "\U0001fa9f", msg)

            if we.action in ("opened", "renamed", "active"):
                current = self._window_timeline.current_meeting()
                if current:
                    self._segmenter.on_meeting_change(current, we.time)

        all_participants = self._participant_set.get_all()
        if all_participants and all_participants != self._last_ppl_set:
            self._last_ppl_set = set(all_participants)
            ts = start.strftime("%H:%M:%S")
            names = ", ".join(sorted(all_participants))
            self.transcript.append(ts, "\U0001f465 ppl", names)
            self._log(format_message("\U0001f465 ppl", names))
            self._segmenter.on_signal(start, "ppl", "\U0001f465", names)

    def _input_loop(self):
        import tty
        import termios

        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        try:
            tty.setcbreak(fd)
            while not self._stopping:
                ch = sys.stdin.read(1)
                if ch == "p":
                    self._paused = not self._paused
                    self._log("paused" if self._paused else "listening")
                elif ch == "s":
                    now = datetime.now()
                    timestamp = now.strftime("%H:%M:%S")
                    self.transcript.append(timestamp, "📍 pin")
                    self._log(format_message("📍 pin"))
                    self._segmenter.on_pin(now)
        except (EOFError, OSError):
            pass
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

    def _log(self, msg: str):
        ts = datetime.now().strftime("%H:%M:%S")
        print(f"[{ts}] {msg}", flush=True)

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
        self._log("running final segmentation...")
        self._segmenter.flush()
        self._log("shutdown complete")
        self._lock.release()
        for f in self._work_dir.iterdir():
            f.unlink(missing_ok=True)
        self._work_dir.rmdir()
        self._log(format_message("🔴 rec", "stopped"))


def main():
    config = load_config()
    recorder = Recorder(config)
    try:
        recorder.run()
    except LockError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
