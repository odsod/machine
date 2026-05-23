"""
Signal collectors — write to in-memory timelines only.

The transcription worker is the sole writer to the transcript file.
These collectors feed real-time data into timelines that the worker
queries when processing each audio chunk.
"""

import subprocess
import threading
import time
from collections.abc import Callable
from datetime import datetime

from recorder.config import SignalsConfig
from recorder.speaker_cdp import SpeakerDetector
from recorder.timeline import ParticipantSet, SpeakerTimeline, WindowTimeline


class SilenceMonitor:
    """Tracks silence duration. Called from the capture loop."""

    def __init__(self, threshold_secs: int, log: Callable):
        self._threshold = threshold_secs
        self._notified = False
        self._log = log

    @property
    def notified(self) -> bool:
        return self._notified

    def tick(self, consecutive_silent_secs: int) -> bool:
        """Returns True the first time silence crosses threshold."""
        if consecutive_silent_secs >= self._threshold and not self._notified:
            self._notified = True
            return True
        return False

    def reset(self):
        self._notified = False


class SpeakerCollector:
    """Polls CDP for speaker changes, writes to SpeakerTimeline + ParticipantSet."""

    def __init__(
        self,
        speaker_timeline: SpeakerTimeline,
        participant_set: ParticipantSet,
        config: SignalsConfig,
        log: Callable,
    ):
        self._speaker_timeline = speaker_timeline
        self._participant_set = participant_set
        self._config = config
        self._log = log
        self._stopping = False
        self._thread: threading.Thread | None = None
        self._detector = SpeakerDetector(ports=config.cdp_ports)
        self._active_speaker: str | None = None

    def start(self):
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def stop(self):
        self._stopping = True

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
            return

        now = datetime.now()
        current_names = {s.name for s in states}
        self._participant_set.update(current_names)

        speaker = next((s.name for s in states if s.speaking), None)
        if speaker:
            self._participant_set.update({speaker})

        if speaker != self._active_speaker:
            self._active_speaker = speaker
            self._speaker_timeline.append(now, speaker)


class WindowCollector:
    """Polls KWin window stack, writes to WindowTimeline."""

    def __init__(
        self,
        window_timeline: WindowTimeline,
        config: SignalsConfig,
        log: Callable,
    ):
        self._window_timeline = window_timeline
        self._config = config
        self._log = log
        self._stopping = False
        self._thread: threading.Thread | None = None
        self._known_windows: dict[str, str] = {}
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

        now = datetime.now()

        if self._initialized:
            for wid, title in current.items():
                if wid not in self._known_windows:
                    self._window_timeline.append(now, title, "opened")
                elif self._known_windows[wid] != title:
                    self._window_timeline.append(now, title, "renamed")

            for wid in set(self._known_windows) - set(current):
                title = self._known_windows[wid]
                self._window_timeline.append(now, title, "closed")
        else:
            for wid, title in current.items():
                self._window_timeline.append(now, title, "active")

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
