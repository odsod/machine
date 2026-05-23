"""
Incremental segmenter — detects boundaries and finalizes segments as they complete.

A boundary is *detected* when silence crosses threshold / meeting changes / pin.
A boundary is *finalized* when speech resumes after it — the previous segment is
now complete and can be summarized immediately.
"""

import threading
from collections.abc import Callable
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

from recorder.config import LlmConfig
from recorder.segment import SILENCE_THRESHOLD, Boundary, Event, Segment, snap_pin
from recorder.summarize import summarize_segment, write_inbox_draft
from recorder.transcript import DailyTranscript


@dataclass
class SegmentEvent:
    time: datetime
    tag: str
    emoji: str
    text: str


class IncrementalSegmenter:
    """Detects segment boundaries incrementally as events arrive."""

    def __init__(
        self,
        transcript: DailyTranscript,
        llm_config: LlmConfig,
        inbox_dir: Path,
        log: Callable[[str], None],
    ):
        self._transcript = transcript
        self._llm_config = llm_config
        self._inbox_dir = inbox_dir
        self._log = log
        self._events: list[SegmentEvent] = []
        self._speech_events: list[SegmentEvent] = []
        self._last_speech_time: datetime | None = None
        self._boundary_pending: Boundary | None = None
        self._summarize_threads: list[threading.Thread] = []

    def on_speech(self, time: datetime, tag: str, text: str):
        """Called after each speech line is written to transcript."""
        event = SegmentEvent(time=time, tag=tag, emoji="", text=text)
        self._events.append(event)
        self._speech_events.append(event)

        if self._boundary_pending and self._last_speech_time:
            self._finalize_segment()

        self._last_speech_time = time

    def on_signal(self, time: datetime, tag: str, emoji: str, text: str):
        """Called after non-speech events (win, ppl) are written."""
        self._events.append(SegmentEvent(time=time, tag=tag, emoji=emoji, text=text))

    def on_silence(self, duration_secs: int):
        """Called from capture loop each silent second."""
        if duration_secs >= SILENCE_THRESHOLD and not self._boundary_pending:
            if self._last_speech_time:
                self._boundary_pending = Boundary(
                    time=self._last_speech_time,
                    reason=f"silence {duration_secs // 60}m",
                )
                self._log(f"segmenter: boundary detected (silence {duration_secs // 60}m)")

    def on_meeting_change(self, new_title: str, time: datetime):
        """Called when meeting identity changes."""
        if self._last_speech_time and self._events and not self._boundary_pending:
            self._boundary_pending = Boundary(
                time=time, reason=f"meeting change → {new_title}"
            )
            self._log(f"segmenter: boundary detected (meeting change → {new_title})")

    def on_pin(self, time: datetime):
        """Called when user presses 's'."""
        snapped = snap_pin(
            time,
            [Event(time=e.time, tag=e.tag, emoji="", text=e.text) for e in self._speech_events],
        )
        self._boundary_pending = Boundary(time=snapped, reason="pin")
        self._log("segmenter: boundary detected (pin)")

    def flush(self):
        """Called at shutdown — finalize current segment if it has speech content."""
        if self._boundary_pending and self._speech_events:
            self._finalize_segment()
        elif self._speech_events:
            self._boundary_pending = Boundary(
                time=self._speech_events[-1].time, reason="shutdown"
            )
            self._finalize_segment()

        for t in self._summarize_threads:
            t.join(timeout=120)

    def _finalize_segment(self):
        """Close the previous segment and trigger summarization."""
        if not self._speech_events:
            self._boundary_pending = None
            return

        boundary = self._boundary_pending
        boundary_time = boundary.time if boundary else self._speech_events[-1].time

        seg_events = [
            e for e in self._events if e.time <= boundary_time
        ]
        seg_speech = [e for e in seg_events if e.tag in ("sys", "mic")]

        if not seg_speech:
            self._events = [e for e in self._events if e.time > boundary_time]
            self._speech_events = [e for e in self._speech_events if e.time > boundary_time]
            self._boundary_pending = None
            return

        segment = Segment(
            start=seg_speech[0].time,
            end=seg_speech[-1].time,
            events=[
                Event(time=e.time, tag=e.tag, emoji=e.emoji, text=e.text)
                for e in seg_events
            ],
            id=seg_speech[0].time.strftime("%H%M"),
        )

        self._events = [e for e in self._events if e.time > boundary_time]
        self._speech_events = [e for e in self._speech_events if e.time > boundary_time]
        self._boundary_pending = None

        t = threading.Thread(
            target=self._summarize_and_write, args=(segment,), daemon=True
        )
        t.start()
        self._summarize_threads.append(t)

    def _summarize_and_write(self, segment: Segment):
        try:
            date = segment.start.strftime("%Y-%m-%d")
            summary = summarize_segment(segment, self._llm_config, date)
            if summary:
                path = write_inbox_draft(summary, segment, date, self._inbox_dir)
                slug = summary.title.lower().replace(" ", "-")[:40]
                self._append_seg_marker(segment, slug)
                self._log(f"segmenter: wrote {path.name}")
            else:
                self._append_seg_marker(segment, "skip")
                self._log(f"segmenter: skipped segment {segment.id}")
        except Exception as e:
            self._log(f"segmenter error: {e}")

    def _append_seg_marker(self, segment: Segment, slug: str):
        ts = datetime.now().strftime("%H:%M:%S")
        self._transcript.append(ts, "✂️ seg", f"| {segment.id} {slug}")
