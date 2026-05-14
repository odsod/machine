"""
CLI for the segment subcommand.

Usage:
  recorder segment <transcript>              # dry-run: show boundaries + summaries
  recorder segment <transcript> --write      # write inbox drafts + seg markers
  recorder segment <transcript> --boundaries # only show boundaries, no LLM calls
"""

import argparse
import sys
from datetime import datetime
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(prog="recorder segment")
    parser.add_argument("transcript", type=Path, help="Path to transcript file")
    parser.add_argument(
        "--write", action="store_true", help="Write inbox drafts + seg markers"
    )
    parser.add_argument(
        "--boundaries", action="store_true", help="Only show boundaries, skip LLM"
    )
    parser.add_argument(
        "--inbox",
        type=Path,
        default=Path.home() / "Vaults/odsod/inbox",
        help="Inbox directory for drafts",
    )
    args = parser.parse_args()

    from recorder.config import load_config
    from recorder.segment import is_speech, parse_transcript
    from recorder.segment_run import process_transcript
    from recorder.summarize import _format_transcript

    if not args.transcript.exists():
        print(f"Error: {args.transcript} not found", file=sys.stderr)
        sys.exit(1)

    date = args.transcript.stem[:10]
    if not _is_valid_date(date):
        print(f"Error: cannot extract date from filename: {args.transcript.name}", file=sys.stderr)
        sys.exit(1)

    config = load_config()
    now = datetime.strptime("23:59:59", "%H:%M:%S")

    results = process_transcript(
        transcript_path=args.transcript,
        date=date,
        now=now,
        llm_config=config.llm,
        inbox_dir=args.inbox,
        summarize=not args.boundaries,
        write=args.write,
    )

    events = parse_transcript(args.transcript)
    print(f"Transcript: {args.transcript.name}")
    print(f"Events: {len(events)}, Speech: {sum(1 for e in events if is_speech(e))}")
    print(f"Boundaries: {len(results.boundaries)}")
    for b in results.boundaries:
        print(f"  [{b.time.strftime('%H:%M:%S')}] {b.reason}")
    print(f"Segments: {len(results.segments)}")
    print()

    for r in results.segments:
        duration = (r.segment.end - r.segment.start).total_seconds() / 60
        lines = len(_format_transcript(r.segment).splitlines())
        time_range = f"{r.segment.start.strftime('%H:%M')}–{r.segment.end.strftime('%H:%M')}"
        print(f"  [{time_range}] {duration:.0f}m, {lines} lines")
        if r.summary:
            print(f"    {r.summary.title}")
            print(f"    {r.summary.summary[:200]}")
            if r.written_to:
                print(f"    → {r.written_to}")
        elif r.skipped:
            print(f"    SKIP")
        print()


def _is_valid_date(s: str) -> bool:
    try:
        datetime.strptime(s, "%Y-%m-%d")
        return True
    except ValueError:
        return False
