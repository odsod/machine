# Recorder — Agent Instructions

Ambient meeting recorder daemon. Always-on capture → transcription → daily event log.

- **Design doc**: `~/Vaults/odsod/wiki/synthesis/ambient-meeting-recorder.md`

## Architecture

```
parec (mic) ─┐                          ┌─ server-side ─┐
             ├→ RMS gate → AudioChunk → │ Silero VAD    │→ LLM cleanup ─┐
parec (sys) ─┘   (with timestamps)      │ whisper decode│               │
                                         └───────────────┘               │
                                                                         ↓
CDP (Meet/Teams) → SpeakerTimeline ←─── Transcription Worker → Transcript
KWin (kdotool) → WindowTimeline ←───────────────┘                  ↓
                                                          IncrementalSegmenter
                                                                  ↓
                                                          Summarize → Inbox
```

- **Daemon** — runs in a tmux session, stdout is a structured log stream
- **No TUI** — plain timestamped log output, composable with tmux panes
- **Sole writer** — only the transcription worker writes to the transcript file
- **Notes** — `Meta+W` launches `recorder-note` via KWin/kdialog
- **Toggle** — `recorder-toggle` creates/switches tmux session

### Threading Model

| Thread                     | Role                                                               | Writes to transcript?    |
| -------------------------- | ------------------------------------------------------------------ | ------------------------ |
| Main                       | Capture loop, silence counting, segmenter.on_silence()             | No                       |
| Transcription worker       | Whisper → cleanup → speaker lookup → write → segmenter.on_speech() | Yes (sole writer)        |
| Signal collector (Speaker) | CDP polling → SpeakerTimeline + ParticipantSet                     | No                       |
| Signal collector (Window)  | KWin polling → WindowTimeline                                      | No                       |
| Input loop                 | Keyboard (p/s)                                                     | No                       |
| Ephemeral                  | Summarization (per segment)                                        | Yes (seg marker + inbox) |

Critical invariant: only the transcription worker calls `transcript.append()` for speech and signal lines.

### Layers

| Layer | Purpose                                                   | Status |
| ----- | --------------------------------------------------------- | ------ |
| 1     | Capture + transcribe + clean → daily transcript           | ✅     |
| 2     | Context signals interleaved into transcript               | ✅     |
| 3     | Segment transcript → segment boundaries (incremental)     | ✅     |
| 4     | Summarize closed segments → `inbox/` drafts               | ✅     |
| 5     | CDP speaker signal → inline speaker attribution on speech | ✅     |

## CLI

Single `recorder` binary, all functionality as subcommands:

```
recorder run                                  # start the daemon
recorder note                                 # desktop note dialog
recorder segment <transcript>                 # dry-run: show boundaries + summaries
recorder segment <transcript> --write         # write inbox drafts + seg markers
recorder segment <transcript> --boundaries    # only show boundaries, no LLM calls
recorder dom [--interval SECS] [--ports 9224 9223]  # snapshot meeting DOM (auto-detects platform)
```

**Principle**: all recorder functionality lives under the `recorder` command as subcommands.

## Structure

```
recorder/
├── src/recorder/
│   ├── __main__.py     # Subcommand dispatch
│   ├── app.py          # Recorder daemon — capture loop, transcription worker, log output
│   ├── config.py       # Dataclass config, loads ~/.config/recorder/config.toml
│   ├── lock.py         # Lockfile — prevents multiple instances across machines
│   ├── timeline.py     # Time-indexed ring buffers (SpeakerTimeline, WindowTimeline, ParticipantSet)
│   ├── segmenter.py    # Incremental stateful segmenter — detects + finalizes boundaries
│   ├── signals.py      # Signal collectors (write to in-memory timelines only)
│   ├── speaker_cdp.py  # Multi-platform speaker detection via CDP (Meet, Teams)
│   ├── meet_cdp.py     # Backward-compat shim + Meet HTML parser (for tests)
│   ├── debug_dom.py    # CDP DOM snapshot tool — auto-detects platform
│   ├── note.py         # Desktop-global note dialog entrypoint
│   ├── segment.py      # Segmentation algorithm — pure functions for offline CLI
│   ├── segment_cli.py  # CLI for segment subcommand
│   ├── segment_run.py  # Offline segmentation orchestration (CLI only)
│   ├── summarize.py    # LLM summarization — system prompt, chunking, inbox writer
│   ├── transcribe.py   # whisper HTTP, LLM cleanup, dedup, hallucination filter
│   ├── transcript.py   # DailyTranscript — append-only markdown event log
│   └── prompts/
│       ├── summarize.md  # System prompt for per-segment summarization
│       └── combine.md    # System prompt for map-reduce combine step
├── hosts/             # Full host-specific configs
├── recorder-toggle     # Fish script — tmux session toggle
├── Makefile            # Install: deps, silero model, uv tool, config, toggle
└── pyproject.toml      # uv tool install -e
```

## Daemon Controls

Keybindings in the tmux pane (raw terminal input, no prefix):

| Key   | Action                                     |
| ----- | ------------------------------------------ |
| `C-c` | Quit (clean shutdown, final segmenter run) |
| `p`   | Pause/resume capture                       |
| `s`   | Insert `📍 pin` (segment boundary hint)    |

## Capture Pipeline

Per-channel chunking with server-side VAD:

1. `parec` captures mic + system audio continuously (separate channels)
2. Permissive RMS gate (threshold 0.002) — avoids sending dead silence over HTTP
3. Accumulate until 1s+ silence, min 10s / max 45s chunks
4. Each chunk carries wall-clock `(start_time, end_time)` for speaker correlation
5. Submit to whisper-server → **Silero VAD** decides speech/non-speech server-side
6. Whisper decodes only VAD-approved segments (ROCm GPU)
7. LLM cleanup (filler, grammar, dedup, hallucination filtering)
8. **Speaker resolution** — query SpeakerTimeline for chunk's time window
9. **Audio dedup** — mic text suppressed if token overlap ≥ 60% with system text
10. Append clean timestamped speech to daily transcript with inline speaker attribution

Client-side RMS is permissive by design — server-side Silero VAD (0.97 accuracy, spectral
analysis) makes the real speech/non-speech decision.

## Transcript Format

Append-only daily event log at `~/Vaults/odsod/raw/transcripts/YYYY-MM-DD-recorder.md`.

Speech and context events interleaved chronologically:

```markdown
[09:00:15] 🪟 **win** "Meet" → "Meet - Weekly Sync"
[09:00:20] 👥 **ppl** Alice, Bob, Oscar Söderlund
[09:00:32] 🔊 **sys** [Alice] Hey, can you hear me?
[09:00:35] 🎤 **mic** [Oscar Söderlund] Yeah, all good. Let's start.
[09:01:12] 🔊 **sys** [Bob] I'll share the design doc.
[09:01:45] 🔊 **sys** [Alice, Bob] Right, and about the migration...
[09:15:05] 📝 **nfo** decision: split terraform schema
[09:34:12] 🪟 **win** "Meet - Weekly Sync" closed
[09:39:15] 💤 **idl** 5 min
[09:40:00] 📍 **pin**
```

## Line Grammar

Every line: `[HH:MM:SS] <emoji> **<tag>** <text>`

For speech lines, optional inline speaker: `[HH:MM:SS] 🔊 **sys** [Speaker] text` / `[HH:MM:SS] 🎤 **mic** [Speaker] text`

Fixed-width 3-char tag inside bold markers — grepable, parseable, human-readable.
Emojis must be single codepoint (U+1Fxxx) — no variation selectors (U+FE0F) which cause inconsistent terminal width:

| Tag | Emoji | Source                                                           |
| --- | ----- | ---------------------------------------------------------------- |
| sys | 🔊    | System audio transcription (with inline `[Speaker]` attribution) |
| mic | 🎤    | Mic audio transcription (with inline `[Speaker]` attribution)    |
| win | 🪟    | kdotool polling — open/close/title change                        |
| ppl | 👥    | CDP polling — participant set changes                            |
| idl | 💤    | Silence detector                                                 |
| nfo | 📝    | User — freeform annotation (`Meta+W`)                            |
| pin | 📍    | User — segment boundary hint (`s` in recorder pane)              |
| seg | ✂️    | Segmenter — segment boundary emitted                             |
| rec | 🟢/🔴 | Recorder started/stopped                                         |

## Runtime Dependencies

| Service        | URL                                             | Purpose            |
| -------------- | ----------------------------------------------- | ------------------ |
| whisper-server | `http://odsod-desktop:8178/v1/audio/…`          | ASR (ROCm GPU)     |
| llama-server   | `http://odsod-desktop:8179/v1/chat/completions` | Cleanup (Qwen 3.5) |

System: `pulseaudio-utils` (parec), `kdotool`, `kdialog`.
Chrome (Meet): `--remote-debugging-port=9224` via dedicated profile `data/google-chrome/recorder`.
Chrome (Teams): work browser on `--remote-debugging-port=9223`.

## Development

- **Install**: `make -C recorder install`
- **Run**: `recorder` (editable install via `uv tool install -e`)
- **Note**: `recorder-note` opens a kdialog input box and appends submitted text as `📝 nfo`
- **Config**: `~/.config/recorder/config.toml` (symlink to host config)
- **Host source**: `recorder/hosts/$(hostname).toml`

### Config Sections

```toml
[audio]       # sample_rate (16000), format ("s16")
[whisper]     # url, timeout_s (60)
[llm]         # url, timeout_s (180)
[transcript]  # output_dir ("~/Vaults/odsod/raw/transcripts")
[dedup]       # threshold (0.6) — token overlap ratio for mic/sys dedup
[signals]     # silence_threshold_secs (180), kwin_poll_interval_secs (10), meeting_window_patterns, cdp_ports ([9224, 9223])
```

## Notes

- **Shortcut**: `Meta+W` (KWin global shortcut)
- **Dialog**: `kdialog --title "Note" --geometry 420 --inputbox "Note:"`
- **Save**: Enter/OK with non-empty text appends to the daily transcript as `📝 **nfo**`
- **Discard**: Esc/cancel, or blank input, appends nothing
- **Daemon**: Recorder does not need to be running; `recorder-note` writes directly to the transcript

## Hallucination Mitigation

Whisper hallucinates on near-silence that passes the RMS gate. Layered defense:

### Server-side VAD (primary defense)

- **Silero VAD** on whisper-server — skips non-speech before decoding (see `whisper/AGENTS.md`)
- **`--suppress-nst`** — suppresses `[Music]`, bracket tokens on ambient noise

### Pre-transcription (client-side)

- **Permissive RMS gate** (0.002) — only rejects dead silence to save HTTP round-trips
- **Whole-chunk RMS gate** (0.003) — rejects chunks that are mostly silent despite per-frame detection
- **Min chunk 10s** — short clips still cause hallucination even with VAD
- **Max chunk 45s** — force split for monologues

### Post-transcription

- **LLM cleanup prompt** hardened to return empty on non-speech (no regex filtering)
- **Summarizer filter** — `_is_hallucination()` in summarize.py strips known hallucination phrases from transcript lines before feeding to the summarization LLM (separate defense layer from cleanup prompt)
- If hallucinations persist despite VAD, next step: integrate the
  `sachaarbonel/whisper-hallucinations` dataset (7,889 phrases, MIT, flat CSV)
  as a phrase set lookup — see `huggingface.co/datasets/sachaarbonel/whisper-hallucinations`

### What does NOT work

- **Silero VAD client-side** — requires gain boost on mic to trigger reliably (server-side works fine)
- **`no_speech_thold` alone** — doesn't help when language is forced (whisper confidently emits artifacts)
- **Forcing a single language** — meetings mix English + Swedish; forcing one degrades the other

## Segmentation (Layer 3)

### Online: Incremental Segmenter

The `IncrementalSegmenter` detects boundaries and finalizes segments as they complete:

- **Boundary detected** when: silence crosses 5 min, meeting identity changes, or user pins
- **Boundary finalized** when: speech resumes after the boundary — previous segment is now complete
- **Finalization triggers** summarization immediately (in background thread)
- **Crash resilience** — completed segments are finalized within seconds of ending; only the in-progress segment at crash time is affected

### Offline: Pure Function CLI

`recorder segment <transcript>` uses the pure functions in `segment.py` for tuning/backfill.

### Boundary Triggers

Three independent OR triggers — any one is sufficient to emit a boundary:

| Trigger                 | Detects                                        |
| ----------------------- | ---------------------------------------------- |
| Silence ≥ 5 min         | Topic changes in long calls, gaps between work |
| Meeting identity change | Back-to-back meetings with no silence gap      |
| Pin                     | Anything the algorithm misses                  |

**Two silence thresholds** (different purposes):

- `SilenceMonitor`: 180s (3 min) → emits `💤 idl` transcript marker (informational)
- `IncrementalSegmenter`: 300s (5 min) → triggers segmentation boundary

**Pin snapping**: walks backwards from pin time to find the nearest ≥3s silence gap
within 90s. Snaps the boundary there instead of at the raw pin time.

### Seg Markers

- `✂️ seg` lines in transcript mark processed segments
- Format: `[HH:MM:SS] ✂️ seg | HHMM slug` — the HHMM id is for idempotency

## Summarization (Layer 4)

Local LLM (Qwen 3.5 9B) produces structured markdown summaries per segment.

- **Short segments** (≤35k chars): single LLM call
- **Long segments**: map-reduce — summarize each chunk → combine results
- **Chunking**: splits at natural silence gaps in the transcript (largest time gap in second half of chunk)
- **Output**: `~/Vaults/odsod/inbox/YYYY-MM-DD-HHMM-<slug>.md`
- **Format**: frontmatter + structured markdown summary (headings per topic) + raw transcript

### Inbox Draft Frontmatter

```yaml
title: "Short Descriptive Title" # ≤8 words, subject-first
date: YYYY-MM-DD
time: "HH:MM–HH:MM"
duration: Xm
type: segment
source: "[[raw/transcripts/YYYY-MM-DD-recorder.md]]"
participants: ["Alice", "Bob"] # from ppl events, optional
```

`type: segment` reflects what this file is — the recorder's raw segmented
output. The vault ingest agent promotes it to `type: interaction` when it
creates the wiki page in `wiki/interactions/`.

The vault ingest agent (Claude) later enriches these with wikilinks, entity
pages, and cross-references. The local LLM focuses on faithful content
extraction.

## Speaker Attribution (Layer 5)

Real-time speaker identification via CDP. Multi-platform: supports Meet and Teams.

### Approach: Chrome DevTools Protocol + Auto-Discovery

`SpeakerDetector` in `speaker_cdp.py` scans configured CDP ports for active
meeting tabs, auto-detects the platform, and discovers the speaking indicator
class via temporal diffing — no hardcoded CSS classes.

- **Accuracy**: exact — platform's own visual indicator data
- **Latency**: ~1s polling interval
- **Cost**: one WebSocket round-trip per poll
- **Platforms**: Meet (port 9224), Teams (port 9223 — work browser)
- **Dependencies**: `websockets`, `httpx`, Chrome with `--remote-debugging-port`

### Attribution Mechanics

1. `SpeakerCollector` polls CDP every ~1s, writes `SpeakerChange(time, name)` to `SpeakerTimeline`
2. Audio chunk carries wall-clock `(start_time, end_time)` from capture
3. After transcription, worker queries `speaker_timeline.speakers_in(start, end)`
4. All distinct speakers during the window are listed: `[Alice]` or `[Alice, Bob]`
5. Both `sys` and `mic` lines get the same attribution (local user's tile lights up in Meet/Teams too)
6. No speaker detected → no brackets (bare line)

### Platform Configs

| Platform | Tile selector                             | Name source            | Class scope |
| -------- | ----------------------------------------- | ---------------------- | ----------- |
| Meet     | `[data-participant-id]`                   | `.notranslate` text    | Subtree     |
| Teams    | `[data-tid="voice-level-stream-outline"]` | Parent `data-tid` attr | Element     |

### Detection Algorithm

1. **Port scan**: iterate `cdp_ports`, GET `/json`, match tab URL to platform
2. **Discovery phase** (first few polls, until someone speaks):
   - Snapshot CSS classes per participant tile (scope depends on platform)
   - Diff class sets between consecutive polls
   - Pick the shortest class that appeared/disappeared → speaking indicator
3. **Cached phase** (rest of session):
   - Use discovered class for fast direct lookups
4. **Cache invalidation**: if the active WebSocket URL changes (meeting ended/new meeting started), reset discovery state

### Participant Tracking

- `ParticipantSet` — thread-safe accumulating set of all participant names
- Set only grows (never shrinks) — resets when a segment is finalized
- Transcription worker emits `👥 ppl` when the set grows
- Ensures all active contributors appear in the segment frontmatter

### Debugging

If detection stops working after a platform update:

```
recorder dom --interval 3
```

Captures DOM snapshots to `--output-dir` (default `~/Tmp/meeting-dom/`). Diff
two tile snapshots (one silent, one speaking) to find the new class —
`SpeakerDetector` should auto-discover it, but this tool helps verify.

## Lockfile

Prevents multiple recorder instances (same machine or across tailnet via Syncthing).

- **Location**: `<transcript_output_dir>/.recorder-lock`
- **Contents**: JSON with `hostname`, `pid`, `updated` (unix timestamp)
- **Heartbeat**: refreshed every 30s in the capture loop
- **Stale after**: 120s — covers crash/kill without clean shutdown
