import subprocess
import threading
import time
from collections.abc import Callable
from datetime import datetime

from recorder.config import SignalsConfig
from recorder.meet_cdp import CDP_PORT, SpeakerDetector
from recorder.transcript import DailyTranscript, format_message


class SilenceMonitor:
    """Emits silence markers to the transcript. Called from the capture loop."""

    def __init__(self, transcript: DailyTranscript, config: SignalsConfig, log: Callable):
        self._transcript = transcript
        self._threshold = config.silence_threshold_secs
        self._notified = False
        self._log = log

    def tick(self, consecutive_silent_secs: int):
        if consecutive_silent_secs >= self._threshold and not self._notified:
            ts = datetime.now().strftime("%H:%M:%S")
            mins = consecutive_silent_secs // 60
            self._transcript.append(ts, "💤 idl", f"{mins} min")
            self._log(format_message("💤 idl", f"{mins} min"))
            self._notified = True

    def reset(self):
        self._notified = False


class KwinMonitor:
    """Polls KWin window stack for meeting windows. Detects open/close/title change."""

    def __init__(self, transcript: DailyTranscript, config: SignalsConfig, log: Callable):
        self._transcript = transcript
        self._config = config
        self._log = log
        self._stopping = False
        self._thread: threading.Thread | None = None
        self._known_windows: dict[str, str] = {}  # window_id -> title
        self._initialized = False

    def start(self):
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def stop(self):
        self._stopping = True

    def _run(self):
        try:
            subprocess.run(
                ["kdotool", "--version"], capture_output=True, timeout=5
            )
        except (FileNotFoundError, subprocess.TimeoutExpired):
            return

        while not self._stopping:
            self._poll()
            for _ in range(self._config.kwin_poll_interval_secs * 10):
                if self._stopping:
                    return
                time.sleep(0.1)

    def _poll(self):
        try:
            result = subprocess.run(
                ["kdotool", "search", "."],
                capture_output=True, text=True, timeout=5,
            )
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return
        if result.returncode != 0:
            return

        current: dict[str, str] = {}
        for window_id in result.stdout.strip().splitlines():
            window_id = window_id.strip()
            if not window_id:
                continue
            class_name = self._get_prop(window_id, "getwindowclassname")
            if not class_name:
                continue
            if not any(p in class_name for p in self._config.meeting_window_patterns):
                continue
            title = self._get_prop(window_id, "getwindowname") or class_name
            current[window_id] = title

        if self._initialized:
            for wid, title in current.items():
                if wid not in self._known_windows:
                    ts = datetime.now().strftime("%H:%M:%S")
                    msg = f"\"{title}\" opened"
                    self._transcript.append(ts, "\U0001fa9f win", msg)
                    self._log(format_message("\U0001fa9f win", msg))
                elif self._known_windows[wid] != title:
                    old_title = self._known_windows[wid]
                    ts = datetime.now().strftime("%H:%M:%S")
                    msg = f"\"{old_title}\" → \"{title}\""
                    self._transcript.append(ts, "\U0001fa9f win", msg)
                    self._log(format_message("\U0001fa9f win", msg))

            for wid in set(self._known_windows) - set(current):
                title = self._known_windows[wid]
                ts = datetime.now().strftime("%H:%M:%S")
                msg = f"\"{title}\" closed"
                self._transcript.append(ts, "\U0001fa9f win", msg)
                self._log(format_message("\U0001fa9f win", msg))

        if not self._initialized:
            for wid, title in current.items():
                ts = datetime.now().strftime("%H:%M:%S")
                msg = f"\"{title}\" active"
                self._transcript.append(ts, "\U0001fa9f win", msg)
                self._log(format_message("\U0001fa9f win", msg))
        self._initialized = True
        self._known_windows = current

    def _get_prop(self, window_id: str, command: str) -> str | None:
        try:
            result = subprocess.run(
                ["kdotool", command, window_id],
                capture_output=True, text=True, timeout=2,
            )
            return result.stdout.strip() if result.returncode == 0 else None
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return None


class MeetParticipantMonitor:
    """Polls Meet via CDP. Tracks participants (rendered tiles) and speakers (active indicator)."""

    def __init__(self, transcript: DailyTranscript, config: SignalsConfig, log: Callable):
        self._transcript = transcript
        self._config = config
        self._log = log
        self._stopping = False
        self._thread: threading.Thread | None = None
        self._known_participants: set[str] = set()
        self._active_speaker: str | None = None
        self._detector = SpeakerDetector(CDP_PORT)

    def start(self):
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def stop(self):
        self._stopping = True

    def reset_participants(self):
        self._known_participants = set()
        self._active_speaker = None

    def _run(self):
        while not self._stopping:
            self._poll()
            for _ in range(10):
                if self._stopping:
                    return
                time.sleep(0.1)

    def _poll(self):
        states = self._detector.poll()
        if states is None:
            self._active_speaker = None
            return

        # Union of all names ever seen (tiles + speakers)
        current_names = {s.name for s in states}
        new_names = current_names - self._known_participants

        speaker = next((s.name for s in states if s.speaking), None)
        if speaker:
            new_names |= {speaker} - self._known_participants

        if new_names:
            self._known_participants |= new_names
            names = ", ".join(sorted(self._known_participants))
            ts = datetime.now().strftime("%H:%M:%S")
            self._transcript.append(ts, "\U0001f465 ppl", names)
            self._log(format_message("\U0001f465 ppl", names))

        if speaker != self._active_speaker:
            self._active_speaker = speaker
            if speaker:
                ts = datetime.now().strftime("%H:%M:%S")
                self._transcript.append(ts, "\U0001f5e3️ spk", speaker)
                self._log(format_message("\U0001f5e3️ spk", speaker))
