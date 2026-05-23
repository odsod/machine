"""
Time-indexed ring buffers for signal data.

Signal collectors (CDP, KWin) write to these in real-time. The transcription
worker reads from them when writing each speech line — correlating signals
with the audio chunk's original capture window.
"""

import threading
from collections import deque
from dataclasses import dataclass, field
from datetime import datetime


@dataclass
class SpeakerChange:
    time: datetime
    name: str | None


class SpeakerTimeline:
    """Thread-safe log of speaker changes. Written by CDP poller, read by transcription worker."""

    def __init__(self, max_age_secs: int = 600):
        self._changes: deque[SpeakerChange] = deque()
        self._lock = threading.Lock()
        self._max_age_secs = max_age_secs

    def append(self, time: datetime, name: str | None):
        with self._lock:
            self._changes.append(SpeakerChange(time=time, name=name))
            self._evict()

    def speakers_in(self, start: datetime, end: datetime) -> list[str]:
        """All distinct speakers active during [start, end], ordered by first appearance."""
        with self._lock:
            result: list[str] = []
            seen: set[str] = set()
            active_at_start: str | None = None
            for c in self._changes:
                if c.time <= start:
                    active_at_start = c.name
                elif c.time <= end:
                    if c.name and c.name not in seen:
                        seen.add(c.name)
                        result.append(c.name)
                else:
                    break
            if active_at_start:
                if active_at_start in seen:
                    result.remove(active_at_start)
                result.insert(0, active_at_start)
            return result

    def _evict(self):
        if not self._changes:
            return
        cutoff = self._changes[-1].time
        while self._changes:
            age = (cutoff - self._changes[0].time).total_seconds()
            if age > self._max_age_secs:
                self._changes.popleft()
            else:
                break


class ParticipantSet:
    """Thread-safe accumulating set of participant names."""

    def __init__(self):
        self._names: set[str] = set()
        self._lock = threading.Lock()

    def update(self, names: set[str]) -> set[str] | None:
        """Returns newly added names if set grew, else None."""
        with self._lock:
            new = names - self._names
            if new:
                self._names |= new
                return new
            return None

    def get_all(self) -> set[str]:
        with self._lock:
            return set(self._names)

    def reset(self):
        with self._lock:
            self._names.clear()


@dataclass
class WindowEvent:
    time: datetime
    title: str
    action: str  # "opened" | "closed" | "renamed" | "active"


class WindowTimeline:
    """Thread-safe ring buffer of window events."""

    def __init__(self, max_age_secs: int = 7200):
        self._events: deque[WindowEvent] = deque()
        self._lock = threading.Lock()
        self._max_age_secs = max_age_secs

    def append(self, time: datetime, title: str, action: str):
        with self._lock:
            self._events.append(WindowEvent(time=time, title=title, action=action))
            self._evict()

    def events_between(self, start: datetime, end: datetime) -> list[WindowEvent]:
        """Return window events in [start, end]."""
        with self._lock:
            return [e for e in self._events if start <= e.time <= end]

    def current_meeting(self) -> str | None:
        """Return the most recent open meeting title, or None."""
        with self._lock:
            for e in reversed(self._events):
                if e.action == "closed":
                    return None
                if e.action in ("opened", "renamed", "active"):
                    return e.title
            return None

    def _evict(self):
        if not self._events:
            return
        cutoff = self._events[-1].time
        while self._events:
            age = (cutoff - self._events[0].time).total_seconds()
            if age > self._max_age_secs:
                self._events.popleft()
            else:
                break
