# Recorder — Agent Instructions

Ambient meeting recorder daemon. Always-on capture → transcription → daily event log.

- **Design doc**: `~/Vaults/odsod/wiki/synthesis/ambient-meeting-recorder.md`

## Architecture

```
parec (mic) ─┐                          ┌─ server-side ─┐
             ├→ RMS gate (permissive) → │ Silero VAD    │→ LLM cleanup → append transcript
parec (sys) ─┘                          │ whisper decode│
                                        └───────────────┘

KWin (kdotool) ─────→ window events ────┐
AT-SPI (Meet) ──────→ participants ─────┼→ interleaved into transcript
silence detector ───→ silence markers ──┘
```

- **Daemon** — runs in a tmux session, stdout is a structured log stream
- **No TUI** — plain timestamped log output, composable with tmux panes
- **Notes** — `Meta+W` launches `recorder-note` via KWin/kdialog
- **Toggle** — `recorder-toggle` creates/switches tmux session

### Layers

| Layer | Purpose                                         | Status |
| ----- | ----------------------------------------------- | ------ |
| 1     | Capture + transcribe + clean → daily transcript | ✅     |
| 2     | Context signals interleaved into transcript     | ✅     |
| 3     | Segment transcript → interaction boundaries     | ✅     |
| 4     | Summarize closed segments → `inbox/` drafts     | ✅     |

## CLI

Single `recorder` binary, all functionality as subcommands:

```
recorder run                                  # start the daemon
recorder note                                 # desktop note dialog
recorder segment <transcript>                 # dry-run: show boundaries + summaries
recorder segment <transcript> --write         # write inbox drafts + seg markers
recorder segment <transcript> --boundaries    # only show boundaries, no LLM calls
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
│   ├── meet.py         # AT-SPI participant extraction from Google Meet
│   ├── note.py         # Desktop-global note dialog entrypoint
│   ├── segment.py      # Segmentation algorithm — silence + meeting change + pins
│   ├── segment_cli.py  # CLI for segment subcommand
│   ├── segment_run.py  # Shared segmentation orchestration (online + offline)
│   ├── signals.py      # Context signal monitors (KWin, Meet participants, silence)
│   ├── summarize.py    # LLM summarization — system prompt, chunking, inbox writer
│   ├── transcribe.py   # whisper HTTP, LLM cleanup, dedup, hallucination filter
│   ├── transcript.py   # DailyTranscript — append-only markdown event log
│   └── prompts/
│       ├── summarize.md  # System prompt for per-interaction summarization
│       └── combine.md    # System prompt for map-reduce combine step
├── hosts/             # Full host-specific configs
├── recorder-toggle     # Fish script — tmux session toggle
├── Makefile            # Install: deps, silero model, uv tool, config, toggle
└── pyproject.toml      # uv tool install -e
```

## Daemon Controls

Keybindings in the tmux pane (raw terminal input, no prefix):

| Key | Action                                     |
| --- | ------------------------------------------ |
| `q` | Quit (clean shutdown, final segmenter run) |
| `p` | Pause/resume capture                       |
| `s` | Insert `📍 pin` (segment boundary hint)    |

## Capture Pipeline

Per-channel chunking with server-side VAD:

1. `parec` captures mic + system audio continuously (separate channels)
2. Permissive RMS gate (threshold 0.002) — avoids sending dead silence over HTTP
3. Accumulate until 1s+ silence, min 10s / max 45s chunks
4. Submit to whisper-server → **Silero VAD** decides speech/non-speech server-side
5. Whisper decodes only VAD-approved segments (ROCm GPU)
6. LLM cleanup (filler, grammar, dedup, hallucination filtering)
7. **Audio dedup** — mic text suppressed if token overlap ≥ 60% with system text (prevents double-transcription when mic picks up system audio)
8. Append clean timestamped speech to daily transcript

Client-side RMS is permissive by design — server-side Silero VAD (0.97 accuracy, spectral
analysis) makes the real speech/non-speech decision. Previous attempt at client-side Silero
failed because it needed mic gain boost; server-side processes already-captured audio.

## Transcript Format

Append-only daily event log at `~/Vaults/odsod/raw/transcripts/YYYY-MM-DD-recorder.md`.

Speech and context events interleaved chronologically:

```markdown
[09:00:15] 🪟 **win** "Meet" → "Meet - Weekly Sync"
[09:00:20] 👥 **ppl** Alice, Bob, Oscar Söderlund
[09:00:32] 🔊 **sys** Hey, can you hear me?
[09:00:35] 🎤 **mic** Yeah, all good. Let's start.
[09:15:05] 📝 **nfo** decision: split terraform schema
[09:34:12] 🪟 **win** "Meet - Weekly Sync" → "Meet"
[09:39:15] 💤 **idl** 5 min
[09:40:00] 📍 **pin**
```

## Line Grammar

Every line: `[HH:MM:SS] <emoji> **<tag>** <text>`

Fixed-width 3-char tag inside bold markers — grepable, parseable, human-readable.
Emojis must be single codepoint (U+1Fxxx) — no variation selectors (U+FE0F) which cause inconsistent terminal width:

| Tag | Emoji | Source                                              |
| --- | ----- | --------------------------------------------------- |
| sys | 🔊    | System audio transcription                          |
| mic | 🎤    | Mic audio transcription                             |
| win | 🪟    | kdotool polling — open/close/title change           |
| ppl | 👥    | AT-SPI polling — participant set changes            |
| idl | 💤    | Silence detector                                    |
| nfo | 📝    | User — freeform annotation (`Meta+W`)               |
| pin | 📍    | User — segment boundary hint (`s` in recorder pane) |
| seg | ✂️    | Segmenter — interaction boundary emitted            |
| rec | 🟢/🔴 | Recorder started/stopped                            |

## Runtime Dependencies

| Service        | URL                                             | Purpose            |
| -------------- | ----------------------------------------------- | ------------------ |
| whisper-server | `http://odsod-desktop:8178/v1/audio/…`          | ASR (ROCm GPU)     |
| llama-server   | `http://odsod-desktop:8179/v1/chat/completions` | Cleanup (Qwen 3.5) |

System: `pulseaudio-utils` (parec), `kdotool`, `kdialog`, `at-spi2-core`.

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
[signals]     # silence_threshold_secs (180), kwin_poll_interval_secs (10), meeting_window_patterns
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

Pure function: reads transcript event log → outputs segment boundaries.

### Algorithm: Silence + Signals + Pins

Three independent OR triggers — any one is sufficient to emit a boundary:

| Trigger                 | Detects                                        | Requires integration |
| ----------------------- | ---------------------------------------------- | -------------------- |
| Silence ≥ 5 min         | Topic changes in long calls, gaps between work | No                   |
| Meeting identity change | Back-to-back meetings with no silence gap      | Yes                  |
| Pin                     | Anything the algorithm misses                  | No                   |

**Design**: silence is the baseline — works without any integrations. In a day-long
work call, silence between topics IS the boundary. Meeting signals only handle the
zero-gap case (hang up one meeting, join another immediately). The segmenter
over-generates boundaries; trivial interactions are filtered by the LLM returning skip.

**Two silence thresholds** (different purposes):

- `signals.py` SilenceMonitor: 180s (3 min) → emits `💤 idl` transcript marker (informational)
- `segment.py` SILENCE_THRESHOLD: 300s (5 min) → triggers segmentation boundary + online dispatch

**Pin snapping**: walks backwards from pin time to find the nearest ≥3s silence gap
within 90s. Snaps the boundary there instead of at the raw pin time.

### Execution

- **Online**: triggers when silence crosses threshold (GPU idle — no whisper work)
- **Offline**: `recorder segment <transcript>` for tuning/backfill
- **Dedup**: `✂️ seg` lines in transcript mark processed interactions
  - Format: `[HH:MM:SS] ✂️ seg | HHMM slug` — the HHMM id is parsed for idempotency
- **On stop**: runs segmenter one final time to catch the last interaction

## Summarization (Layer 4)

Local LLM (Qwen 3.5 9B) produces structured markdown summaries per interaction.

- **Short interactions** (≤35k chars): single LLM call
- **Long interactions**: map-reduce — summarize each chunk → combine results
- **Chunking**: splits at natural silence gaps in the transcript (largest time gap in second half of chunk)
- **Output**: `~/Vaults/odsod/inbox/YYYY-MM-DD-HHMM-<slug>.md`
- **Format**: frontmatter + structured markdown summary (headings per topic) + raw transcript

### Inbox Draft Frontmatter

```yaml
title: "Short Descriptive Title"
date: YYYY-MM-DD
time: "HH:MM–HH:MM"
duration: Xm
type: interaction
source: "[[raw/transcripts/YYYY-MM-DD-recorder.md]]"
participants: ["Alice", "Bob"] # from ppl events, optional
```

The vault ingest agent (Claude) later enriches these with wikilinks, entity pages,
and cross-references. The local LLM focuses on faithful content extraction.

## Lockfile

Prevents multiple recorder instances (same machine or across tailnet via Syncthing).

- **Location**: `<transcript_output_dir>/.recorder-lock`
- **Contents**: JSON with `hostname`, `pid`, `updated` (unix timestamp)
- **Heartbeat**: refreshed every 30s in the capture loop
- **Stale after**: 120s — covers crash/kill without clean shutdown
