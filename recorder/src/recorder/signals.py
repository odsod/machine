import json
import subprocess
import threading
import time
from collections.abc import Callable
from datetime import datetime

from recorder.config import SignalsConfig
try:
    from recorder.meet import get_participants
except (ImportError, ValueError):
    get_participants = None
from recorder.transcript import DailyTranscript


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
            self._transcript.append_event(ts, "⏸", f"Silence: {mins} min")
            self._log(f"⏸ Silence: {mins} min")
            self._notified = True

    def reset(self):
        self._notified = False


class PipewireMonitor:
    """Monitors PipeWire for meeting app mic stream creation/destruction."""

    def __init__(self, transcript: DailyTranscript, config: SignalsConfig, log: Callable):
        self._transcript = transcript
        self._config = config
        self._log = log
        self._stopping = False
        self._thread: threading.Thread | None = None
        self._proc: subprocess.Popen | None = None
        self._stream_to_pid: dict[int, str] = {}  # stream_id -> pid
        self._known_pids: dict[str, str] = {}  # pid -> binary
        self._initialized = False

    def start(self):
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def stop(self):
        self._stopping = True
        if self._proc:
            try:
                self._proc.terminate()
                self._proc.wait(timeout=3)
            except (ProcessLookupError, subprocess.TimeoutExpired):
                try:
                    self._proc.kill()
                except ProcessLookupError:
                    pass

    def _run(self):
        try:
            self._proc = subprocess.Popen(
                ["pw-dump", "--monitor", "--no-colors"],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
            )
        except FileNotFoundError:
            return

        buffer = ""
        depth = 0
        while not self._stopping:
            line = self._proc.stdout.readline()
            if not line:
                break
            buffer += line
            depth += line.count("[") - line.count("]")
            if depth == 0 and buffer.strip():
                self._process_batch(buffer)
                buffer = ""

    def _process_batch(self, raw: str):
        try:
            objects = json.loads(raw)
        except json.JSONDecodeError:
            return

        # pw-dump --monitor emits partial updates (only changed objects).
        # We can only detect new streams, not reliably detect removal from partials.
        # Track additions; detect removal when an object with type "PipeWire:Interface:Node"
        # disappears (has no info/props).
        for obj in objects:
            if not isinstance(obj, dict):
                continue
            obj_id = obj.get("id")

            info = obj.get("info")
            if not isinstance(info, dict):
                # Object removed — check if it was a tracked stream
                if obj_id in self._stream_to_pid:
                    pid = self._stream_to_pid.pop(obj_id)
                    # Only emit destroy if no other streams remain for this PID
                    if pid not in self._stream_to_pid.values():
                        binary = self._known_pids.pop(pid, "?")
                        if self._initialized:
                            ts = datetime.now().strftime("%H:%M:%S")
                            msg = f"PipeWire: {binary} mic stream destroyed"
                            self._transcript.append_event(ts, "\U0001f399", msg)
                            self._log(f"\U0001f399 {msg}")
                continue

            props = info.get("props")
            if not isinstance(props, dict):
                continue
            if props.get("media.class") != "Stream/Input/Audio":
                continue

            binary = props.get("application.process.binary", "")
            if binary in ("pacat", "parec"):
                continue
            if not any(p in binary for p in self._config.meeting_app_patterns):
                continue

            pid = str(props.get("application.process.id", ""))
            self._stream_to_pid[obj_id] = pid

            if pid not in self._known_pids:
                self._known_pids[pid] = binary
                if self._initialized:
                    ts = datetime.now().strftime("%H:%M:%S")
                    msg = f"PipeWire: {binary} mic stream created (pid: {pid})"
                    self._transcript.append_event(ts, "\U0001f399", msg)
                    self._log(f"\U0001f399 {msg}")

        if not self._initialized:
            self._initialized = True
            for pid, binary in self._known_pids.items():
                ts = datetime.now().strftime("%H:%M:%S")
                msg = f"PipeWire: {binary} mic stream active (pid: {pid})"
                self._transcript.append_event(ts, "\U0001f399", msg)
                self._log(f"\U0001f399 {msg}")


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
                    msg = f"KWin: \"{title}\" window opened"
                    self._transcript.append_event(ts, "\U0001fa9f", msg)
                    self._log(f"\U0001fa9f {msg}")
                elif self._known_windows[wid] != title:
                    old_title = self._known_windows[wid]
                    ts = datetime.now().strftime("%H:%M:%S")
                    msg = f"KWin: \"{old_title}\" → \"{title}\""
                    self._transcript.append_event(ts, "\U0001fa9f", msg)
                    self._log(f"\U0001fa9f {msg}")

            for wid in set(self._known_windows) - set(current):
                title = self._known_windows[wid]
                ts = datetime.now().strftime("%H:%M:%S")
                msg = f"KWin: \"{title}\" window closed"
                self._transcript.append_event(ts, "\U0001fa9f", msg)
                self._log(f"\U0001fa9f {msg}")

        if not self._initialized:
            for wid, title in current.items():
                ts = datetime.now().strftime("%H:%M:%S")
                msg = f"KWin: \"{title}\" active"
                self._transcript.append_event(ts, "\U0001fa9f", msg)
                self._log(f"\U0001fa9f {msg}")
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
    """Polls Meet participants via AT-SPI. Emits events on join/leave."""

    def __init__(self, transcript: DailyTranscript, config: SignalsConfig, log: Callable):
        self._transcript = transcript
        self._config = config
        self._log = log
        self._stopping = False
        self._thread: threading.Thread | None = None
        self._known_participants: set[str] = set()

    def start(self):
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def stop(self):
        self._stopping = True

    def _run(self):
        if get_participants is None:
            return
        while not self._stopping:
            self._poll()
            for _ in range(60 * 10):
                if self._stopping:
                    return
                time.sleep(0.1)

    def _poll(self):
        participants = get_participants()
        if participants is None:
            self._known_participants = set()
            return

        current = set(participants)
        if current == self._known_participants:
            return

        self._known_participants = current
        names = ", ".join(sorted(current))
        ts = datetime.now().strftime("%H:%M:%S")
        msg = f"Meet participants: {names}"
        self._transcript.append_event(ts, "\U0001f465", msg)
        self._log(f"\U0001f465 {msg}")
