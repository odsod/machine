"""
Summarize a transcript segment via local LLM (Qwen).

Produces an inbox draft for the vault. The vault ingest agent later enriches
it with wikilinks, entity pages, and cross-references.
"""

import importlib.resources
import json
import re
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

import httpx

from recorder.config import LlmConfig
from recorder.segment import Event, Segment, is_speech


def _load_prompt(name: str) -> str:
    return importlib.resources.files("recorder.prompts").joinpath(name).read_text()


SYSTEM_PROMPT = _load_prompt("summarize.md")


@dataclass
class Summary:
    title: str
    summary: str


CHUNK_CHARS = 35000  # chars per chunk (~12k tokens, leaves room for prompt + response)

COMBINE_PROMPT = _load_prompt("combine.md")


def summarize_segment(
    segment: Segment, llm_config: LlmConfig, date: str
) -> Summary | None:
    transcript_text = _format_transcript(segment)
    if not transcript_text.strip():
        return None

    if len(transcript_text) <= CHUNK_CHARS:
        response = _call_llm(SYSTEM_PROMPT, transcript_text, llm_config)
    else:
        response = _summarize_chunked(transcript_text, llm_config)

    if not response or response.get("skip"):
        return None

    return Summary(
        title=response.get("title", "Untitled"),
        summary=response.get("summary", ""),
    )


def _summarize_chunked(transcript: str, config: LlmConfig) -> dict | None:
    """Map-reduce: summarize each chunk with the standard prompt, then combine."""
    chunks = _split_into_chunks(transcript, CHUNK_CHARS)
    chunk_summaries = []

    for chunk in chunks:
        result = _call_llm(SYSTEM_PROMPT, chunk, config)
        if result and not result.get("skip"):
            chunk_summaries.append(result)

    if not chunk_summaries:
        return None
    if len(chunk_summaries) == 1:
        return chunk_summaries[0]

    combined_input = "\n\n---\n\n".join(
        json.dumps(s, ensure_ascii=False, indent=2) for s in chunk_summaries
    )
    return _call_llm(COMBINE_PROMPT, combined_input, config)


def _split_into_chunks(text: str, max_chars: int) -> list[str]:
    """Split text into chunks, preferring silence gaps as split points.

    Looks for the largest time gap between consecutive lines in the second
    half of the chunk — splits there rather than at an arbitrary line.
    """
    lines = text.split("\n")
    if not lines:
        return []

    chunks = []
    start = 0

    while start < len(lines):
        # Find how many lines fit in max_chars
        end = start
        total = 0
        while end < len(lines) and total + len(lines[end]) + 1 <= max_chars:
            total += len(lines[end]) + 1
            end += 1

        if end >= len(lines):
            chunks.append("\n".join(lines[start:]))
            break

        # Look for the best split point: largest time gap in the second half
        split_at = _find_best_split(lines, start, end)
        chunks.append("\n".join(lines[start:split_at]))
        start = split_at

    return chunks


def _find_best_split(lines: list[str], start: int, end: int) -> int:
    """Find the best split point by looking for the largest time gap."""
    # Only search the second half to keep chunks roughly balanced
    search_start = start + (end - start) // 2
    best_gap = 0
    best_idx = end  # default: split at char limit

    time_pattern = re.compile(r"^\[(\d{2}):(\d{2})\]")

    for i in range(search_start, end - 1):
        t1 = time_pattern.match(lines[i])
        t2 = time_pattern.match(lines[i + 1])
        if t1 and t2:
            mins1 = int(t1.group(1)) * 60 + int(t1.group(2))
            mins2 = int(t2.group(1)) * 60 + int(t2.group(2))
            gap = mins2 - mins1
            if gap > best_gap:
                best_gap = gap
                best_idx = i + 1

    return best_idx


def _slugify(title: str) -> str:
    slug = title.lower().strip()
    slug = re.sub(r"[^a-z0-9\s-]", "", slug)
    slug = re.sub(r"[\s]+", "-", slug)
    return slug[:50]


def _extract_participants(segment: Segment) -> list[str]:
    """Extract unique participant names from ppl events."""
    names: set[str] = set()
    for e in segment.events:
        if e.tag != "ppl":
            continue
        # Strip parenthetical annotations before splitting (may contain commas)
        text = re.sub(r"\s*\([^)]*\)", "", e.text)
        text = re.sub(r"\s+joined$", "", text)
        for name in text.split(","):
            name = name.strip()
            if name:
                names.add(name)
    return sorted(names)


def write_inbox_draft(
    summary: Summary, segment: Segment, date: str, inbox_dir: Path
) -> Path:
    duration_min = int((segment.end - segment.start).total_seconds() / 60)
    time_range = f"{segment.start.strftime('%H:%M')}–{segment.end.strftime('%H:%M')}"
    slug = _slugify(summary.title)
    participants = _extract_participants(segment)

    content = f"""---
title: "{summary.title}"
date: {date}
time: "{time_range}"
duration: {duration_min}m
type: segment
source: "[[raw/transcripts/{date}-recorder.md]]"
"""
    if participants:
        content += f"participants: {json.dumps(participants, ensure_ascii=False)}\n"
    content += f"""---

{summary.summary}

---

## Transcript

"""
    content += _format_transcript(segment)

    filename = f"{date}-{segment.id}-{slug}.md"
    path = inbox_dir / filename
    tmp = path.with_suffix(".md.tmp")
    tmp.write_text(content)
    tmp.rename(path)
    return path


def _format_transcript(segment: Segment) -> str:
    lines = []
    for e in segment.events:
        if not is_speech(e):
            continue
        if _is_hallucination(e.text):
            continue
        speaker = "mic" if e.tag == "mic" else "sys"
        lines.append(f"[{e.time.strftime('%H:%M')}] {speaker}: {e.text}")
    return "\n".join(lines)


def _is_hallucination(text: str) -> bool:
    hallucination_patterns = [
        "Thank you for watching",
        "You're welcome",
        "Obrigado",
        "Obrigada",
        "Takk for at du så med",
        "Takk for at du så på",
        "Gracias",
        "Undertexter av",
        "Undertekster av",
        "Nothing meaningful was detected",
        "No meaningful speech was detected",
        "No content to clean",
        "[Empty output]",
        "Empty output",
        "no substantive speech content",
    ]
    text_lower = text.lower().strip()
    if len(text_lower) < 3:
        return True
    for pattern in hallucination_patterns:
        if pattern.lower() in text_lower:
            return True
    return False


MAX_RETRIES = 2


def _call_llm(
    system: str, user: str, config: LlmConfig, max_tokens: int = 4096
) -> dict | None:
    for attempt in range(1 + MAX_RETRIES):
        try:
            resp = httpx.post(
                config.url,
                json={
                    "model": "qwen",
                    "messages": [
                        {"role": "system", "content": system},
                        {"role": "user", "content": user},
                    ],
                    "temperature": 0.3,
                    "max_tokens": max_tokens,
                },
                timeout=config.timeout_s,
            )
            resp.raise_for_status()
            content = resp.json()["choices"][0]["message"]["content"]
            json_match = re.search(r"\{[\s\S]*\}", content)
            if json_match:
                return json.loads(json_match.group())
        except (httpx.HTTPError, json.JSONDecodeError, KeyError, IndexError):
            pass
    return None
