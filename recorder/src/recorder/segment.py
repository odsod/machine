"""
Segmenter — split daily transcripts into segments.

Three independent boundary triggers (any one sufficient):
1. Silence gap ≥ SILENCE_THRESHOLD between speech events
2. Meeting identity change (different named meeting)
3. Pin (snapped backwards to nearest silence gap)

Runs periodically as a batch job. Idempotent: same transcript + same `now`
produces the same boundaries every time.
"""

import re
from dataclasses import dataclass
from datetime import datetime
from itertools import pairwise


SILENCE_THRESHOLD = 300  # 5 min gap between speech → boundary
PIN_LOOKBACK = 90  # seconds to search backwards for snap target
PIN_SNAP_GAP = 3  # min gap that qualifies as snap target
DEDUP_WINDOW = 120  # merge boundaries within 2 min of each other

BARE_MEETING_TITLES = {"Meet", "Google Meet", "meet.google.com_/"}


@dataclass
class Event:
    time: datetime
    tag: str
    emoji: str
    text: str


@dataclass
class Boundary:
    time: datetime
    reason: str


@dataclass
class Segment:
    start: datetime
    end: datetime
    events: list[Event]
    id: str  # HHMM of start time


def parse_transcript(path) -> list[Event]:
    events = []
    pattern = re.compile(
        r"^\[(\d{2}:\d{2}:\d{2})\]\s+"
        r"(?:\*\*)?(.+?)(?:\*\*)?\s+"
        r"(?:\*\*)?(\w+)(?:\*\*)?\s*"
        r"(?:\|\s*)?(.*)?$"
    )
    # Handle both `🔊 **sys**` and `🔊 sys |` formats
    pattern2 = re.compile(
        r"^\[(\d{2}:\d{2}:\d{2})\]\s+"
        r"(\S+)\s+(\w+)\s*"
        r"\|\s*(.*)?$"
    )
    with open(path) as f:
        for line in f:
            line = line.rstrip()
            m = pattern2.match(line)
            if not m:
                m = pattern.match(line)
            if not m:
                continue
            time_str, emoji, tag, text = m.groups()
            try:
                t = datetime.strptime(time_str, "%H:%M:%S")
            except ValueError:
                continue
            events.append(Event(time=t, tag=tag, emoji=emoji, text=text or ""))
    return events


def is_speech(event: Event) -> bool:
    return event.tag in ("sys", "mic")


def is_pin(event: Event) -> bool:
    return event.tag == "pin"


def is_seg(event: Event) -> bool:
    return event.tag == "seg"


def is_win(event: Event) -> bool:
    return event.tag == "win"


def _extract_meeting_title(text: str) -> str | None:
    """Extract meeting title from a window event."""
    # "Meet - Weekly Sync" opened
    # "meet.google.com_/" → "Meet - Weekly Sync"
    # "Meet - X" active
    m = re.search(r'"([^"]+)"(?:\s+(?:opened|active))?$', text)
    if m:
        title = m.group(1)
        if title in BARE_MEETING_TITLES:
            return None
        return title
    # Title change: "X" → "Y"
    m = re.search(r'→\s*"([^"]+)"', text)
    if m:
        title = m.group(1)
        if title in BARE_MEETING_TITLES:
            return None
        return title
    return None


def _meeting_events(events: list[Event]) -> list[tuple[datetime, str]]:
    """Extract (time, meeting_title) pairs from window events."""
    meetings = []
    for e in events:
        if not is_win(e):
            continue
        title = _extract_meeting_title(e.text)
        if title:
            meetings.append((e.time, title))
    return meetings


def snap_pin(pin_time: datetime, speech_events: list[Event]) -> datetime:
    """Snap pin backwards to nearest silence gap within lookback window."""
    before = [e for e in speech_events if e.time <= pin_time]
    if len(before) < 2:
        return pin_time

    # Walk backwards through pairs, find most recent qualifying gap
    for i in range(len(before) - 1, 0, -1):
        curr = before[i]
        prev = before[i - 1]
        gap = (curr.time - prev.time).total_seconds()
        lookback = (pin_time - prev.time).total_seconds()
        if lookback > PIN_LOOKBACK:
            break
        if gap >= PIN_SNAP_GAP:
            return prev.time

    return pin_time


def segment(events: list[Event], now: datetime) -> list[Boundary]:
    """Compute boundaries for a day's transcript."""
    boundaries: list[Boundary] = []

    speech = [e for e in events if is_speech(e)]
    meetings = _meeting_events(events)

    # 1. Silence gaps
    for prev, curr in pairwise(speech):
        gap = (curr.time - prev.time).total_seconds()
        if gap >= SILENCE_THRESHOLD:
            boundaries.append(Boundary(time=prev.time, reason=f"silence {gap/60:.0f}m"))

    # Trailing silence
    if speech:
        trailing = (now - speech[-1].time).total_seconds()
        if trailing >= SILENCE_THRESHOLD:
            boundaries.append(
                Boundary(time=speech[-1].time, reason=f"trailing silence {trailing/60:.0f}m")
            )

    # 2. Meeting identity change (back-to-back meetings with no silence gap)
    last_title = None
    for time, title in meetings:
        if last_title and title != last_title:
            boundaries.append(Boundary(time=time, reason=f"meeting change → {title}"))
        last_title = title

    # 3. Pins (snapped)
    for e in events:
        if is_pin(e):
            snapped = snap_pin(e.time, speech)
            boundaries.append(Boundary(time=snapped, reason="pin"))

    return dedupe(sorted(boundaries, key=lambda b: b.time))


def dedupe(boundaries: list[Boundary]) -> list[Boundary]:
    """Remove boundaries within DEDUP_WINDOW of each other, keeping first."""
    if not boundaries:
        return []
    result = [boundaries[0]]
    for b in boundaries[1:]:
        if (b.time - result[-1].time).total_seconds() >= DEDUP_WINDOW:
            result.append(b)
    return result


def split_at_boundaries(
    events: list[Event], boundaries: list[Boundary]
) -> list[Segment]:
    """Split events into segments at boundary points."""
    if not events:
        return []

    speech = [e for e in events if is_speech(e)]
    if not speech:
        return []

    cut_times = [b.time for b in boundaries]
    segments = []

    # Each segment runs from one boundary to the next
    starts = [speech[0].time] + [
        # Find first speech event after each boundary
        next((e.time for e in speech if e.time > ct), ct)
        for ct in cut_times
    ]

    for i, start in enumerate(starts):
        if i < len(starts) - 1:
            end = starts[i + 1]
        else:
            end = speech[-1].time if speech else start

        segment_events = [e for e in events if start <= e.time <= end]
        if any(is_speech(e) for e in segment_events):
            segments.append(
                Segment(
                    start=start,
                    end=end,
                    events=segment_events,
                    id=start.strftime("%H%M"),
                )
            )

    return segments
