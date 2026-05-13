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
- **Event insertion** — tmux popup helpers callable from any window via keybind
- **Toggle** — `recorder-toggle` creates/switches tmux session (Meta+Shift+M)

### Layers

| Layer | Purpose                                         | Status |
| ----- | ----------------------------------------------- | ------ |
| 1     | Capture + transcribe + clean → daily transcript | ✅     |
| 2     | Context signals interleaved into transcript     | ✅     |
| 3     | Segment transcript → interaction boundaries     |        |
| 4     | Summarize closed segments → `inbox/` drafts     |        |

## Structure

```
recorder/
├── src/recorder/
│   ├── app.py          # Recorder daemon — capture loop, transcription worker, log output
│   ├── config.py       # Dataclass config, loads ~/.config/recorder/config.toml
│   ├── meet.py         # AT-SPI participant extraction from Google Meet
│   ├── signals.py      # Context signal monitors (KWin, Meet participants, silence)
│   ├── transcribe.py   # whisper HTTP, LLM cleanup, dedup, hallucination filter
│   └── transcript.py   # DailyTranscript — append-only markdown event log
├── config.toml         # Default config (installed to ~/.config/recorder/)
├── recorder-toggle     # Fish script — tmux session toggle (Meta+Shift+M)
├── Makefile            # Install: deps, silero model, uv tool, config, toggle, shortcut
└── pyproject.toml      # uv tool install -e
```

## Capture Pipeline

Per-channel chunking with server-side VAD:

1. `parec` captures mic + system audio continuously (separate channels)
2. Permissive RMS gate (threshold 0.002) — avoids sending dead silence over HTTP
3. Accumulate until 1s+ silence, min 10s / max 45s chunks
4. Submit to whisper-server → **Silero VAD** decides speech/non-speech server-side
5. Whisper decodes only VAD-approved segments (ROCm GPU)
6. LLM cleanup (filler, grammar, dedup, hallucination filtering)
7. Append clean timestamped speech to daily transcript

Client-side RMS is permissive by design — server-side Silero VAD (0.97 accuracy, spectral
analysis) makes the real speech/non-speech decision. Previous attempt at client-side Silero
failed because it needed mic gain boost; server-side processes already-captured audio.

## Transcript Format

Append-only daily event log at `~/Vaults/odsod/raw/transcripts/YYYY-MM-DD-recorder.md`.

Speech and context events interleaved chronologically:

```markdown
[09:00:15] 🪟 win | "Meet" → "Meet - Weekly Sync"
[09:00:20] 👥 ppl | Alice, Bob, Oscar Söderlund
[09:00:32] 🔊 sys | Hey, can you hear me?
[09:00:35] 🎤 mic | Yeah, all good. Let's start.
[09:15:05] 📝 nfo | decision: split terraform schema
[09:34:12] 🪟 win | "Meet - Weekly Sync" → "Meet"
[09:39:15] 💤 idl | 5 min
[09:40:00] 📍 pin |
```

## Line Grammar

Every line: `[HH:MM:SS] <emoji> <tag> | <text>`

Fixed-width 3-char tag — grepable, parseable, human-readable.
Emojis must be single codepoint (U+1Fxxx) — no variation selectors (U+FE0F) which cause inconsistent terminal width:

| Tag | Emoji | Source                                    |
| --- | ----- | ----------------------------------------- |
| sys | 🔊    | System audio transcription                |
| mic | 🎤    | Mic audio transcription                   |
| win | 🪟    | kdotool polling — open/close/title change |
| ppl | 👥    | AT-SPI polling — participant set changes  |
| idl | 💤    | Silence detector                          |
| nfo | 📝    | User — freeform annotation (tmux popup)   |
| pin | 📍    | User — segment boundary hint (tmux popup) |
| rec | 🟢/🔴 | Recorder started/stopped                  |

## Runtime Dependencies

| Service        | URL                                             | Purpose            |
| -------------- | ----------------------------------------------- | ------------------ |
| whisper-server | `http://odsod-desktop:8178/v1/audio/…`          | ASR (ROCm GPU)     |
| llama-server   | `http://odsod-desktop:8179/v1/chat/completions` | Cleanup (Qwen 3.5) |

System: `pulseaudio-utils` (parec), `kdotool`, `at-spi2-core`, `libnotify`.

## Development

- **Install**: `make -C recorder install`
- **Run**: `recorder` (editable install via `uv tool install -e`)
- **Config**: `~/.config/recorder/config.toml`

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
- If hallucinations persist despite VAD, next step: integrate the
  `sachaarbonel/whisper-hallucinations` dataset (7,889 phrases, MIT, flat CSV)
  as a phrase set lookup — see `huggingface.co/datasets/sachaarbonel/whisper-hallucinations`

### What does NOT work

- **Silero VAD client-side** — requires gain boost on mic to trigger reliably (server-side works fine)
- **`no_speech_thold` alone** — doesn't help when language is forced (whisper confidently emits artifacts)
- **Forcing a single language** — meetings mix English + Swedish; forcing one degrades the other

## Segmentation (Layer 3)

Pure function: reads transcript event log → outputs segment boundaries with metadata.

**Boundary signals** (priority order):

1. `🪟 win` title reverts (e.g. "Meet - X" → "Meet") → meeting ended
2. `👥 ppl` disappears → left the call
3. `💤 idl` with no active context → natural boundary
4. New calendar event while previous segment open → split

`📍 pin` is a hint, not a hard boundary — the user may drop it slightly before
or after the real transition. The segmenter should snap to the nearest natural
boundary (silence/inactivity) within a window around the pin.

**Execution**: batch every 10 min (with lookahead), immediately on `✂️ split`, on shutdown.

## Summarization (Layer 4)

Triggered on segment close. Input is already clean text from Layer 1.

- Extract: title, key decisions, action items, open questions
- Write draft interaction to `~/Vaults/odsod/inbox/YYYY-MM-DD-<slug>.md`
