"""
Shared segmentation logic for both online (daemon) and offline (CLI) modes.

This module is the bridge between the pure segmentation/summarization functions
and the side effects (writing inbox files, appending seg markers).
"""

from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

from recorder.config import LlmConfig
from recorder.segment import (
    Boundary,
    Segment,
    is_seg,
    parse_transcript,
    segment,
    split_at_boundaries,
)
from recorder.summarize import Summary, summarize_segment, write_inbox_draft


@dataclass
class SegmentEntry:
    segment: Segment
    summary: Summary | None = None
    skipped: bool = False
    written_to: Path | None = None


@dataclass
class SegmentResult:
    boundaries: list[Boundary] = field(default_factory=list)
    segments: list[SegmentEntry] = field(default_factory=list)


def process_transcript(
    transcript_path: Path,
    date: str,
    now: datetime,
    llm_config: LlmConfig,
    inbox_dir: Path,
    summarize: bool = True,
    write: bool = False,
) -> SegmentResult:
    """Segment a transcript and optionally summarize + write inbox drafts.

    This is the shared entry point for both:
    - Online mode: called periodically by the recorder daemon
    - Offline mode: called by the CLI for tuning/backfill
    """
    events = parse_transcript(transcript_path)
    boundaries = segment(events, now)
    segs = split_at_boundaries(events, boundaries)

    # Determine which segments have already been processed
    emitted = {e.text.split()[0] for e in events if is_seg(e) and e.text}

    result = SegmentResult(boundaries=boundaries)

    for seg in segs:
        if seg.id in emitted:
            continue

        entry = SegmentEntry(segment=seg)

        if summarize:
            summary = summarize_segment(seg, llm_config, date)
            if summary:
                entry.summary = summary
                if write:
                    path = write_inbox_draft(summary, seg, date, inbox_dir)
                    entry.written_to = path
                    _append_seg_marker(transcript_path, seg, summary)
            else:
                entry.skipped = True
                if write:
                    _append_seg_marker(transcript_path, seg, None)

        result.segments.append(entry)

    return result


def _append_seg_marker(
    transcript_path: Path, seg: Segment, summary: Summary | None
):
    slug = summary.title.lower().replace(" ", "-")[:40] if summary else "skip"
    line = f"[{datetime.now().strftime('%H:%M:%S')}] ✂️ seg | {seg.id} {slug}\n"
    with open(transcript_path, "a") as f:
        f.write(line)
