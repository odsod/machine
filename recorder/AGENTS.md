# Recorder — Agent Instructions

Ambient meeting recorder daemon. Always-on capture → transcription → daily event log.

- **Design doc**: `~/Vaults/odsod/wiki/synthesis/ambient-meeting-recorder.md`

## Architecture

```
parec (mic) ─┐                          ┌─ server-side ─┐
             ├→ RMS gate (permissive) → │ Silero VAD    │→ LLM cleanup → append transcript
parec (sys) ─┘                          │ whisper decode│
                                        └───────────────┘

pw-dump --monitor ──→ PipeWire events ──┐
KWin D-Bus ─────────→ window events ────┼→ interleaved into transcript
silence detector ───→ silence markers ──┘
```

- **Daemon** — runs in a tmux session, stdout is a structured log stream
- **No TUI** — plain timestamped log output, composable with tmux panes
- **Event insertion** — tmux popup helpers callable from any window via keybind
- **Toggle** — `recorder-toggle` creates/switches tmux session (Meta+Shift+M)

### Layers

| Layer | Purpose                                         |
| ----- | ----------------------------------------------- |
| 1     | Capture + transcribe + clean → daily transcript |
| 2     | Segment transcript → interaction boundaries     |
| 3     | Summarize closed segments → `inbox/` drafts     |

## Structure

```
recorder/
├── src/recorder/
│   ├── app.py          # Recorder daemon — capture loop, transcription worker, log output
│   ├── config.py       # Dataclass config, loads ~/.config/recorder/config.toml
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
[09:00:15] 🎙 PipeWire: chrome mic stream created (pid: 12345)
[09:00:15] 🪟 KWin: "Meet - Weekly Sync" window active
[09:00:32] **System** Hey, can you hear me?
[09:00:35] **You** Yeah, all good. Let's start.
[09:15:05] 📝 decision: split terraform schema by resource
[09:34:12] 🎙 PipeWire: chrome mic stream destroyed
[09:39:15] ⏸ Silence: 5 min
```

## Event Insertion

Events injected into the transcript from outside the recorder process:

| Event          | Trigger              | Source                       |
| -------------- | -------------------- | ---------------------------- |
| `✂️ split`     | Keybind (tmux popup) | User — hard segment boundary |
| `📝 <text>`    | Keybind (tmux popup) | User — freeform annotation   |
| `🎙 PipeWire:` | `pw-dump --monitor`  | Automatic                    |
| `🪟 KWin:`     | KWin D-Bus           | Automatic                    |
| `⏸ Silence:`   | Silence detector     | Automatic                    |

## Runtime Dependencies

| Service        | URL                                             | Purpose            |
| -------------- | ----------------------------------------------- | ------------------ |
| whisper-server | `http://odsod-desktop:8178/v1/audio/…`          | ASR (ROCm GPU)     |
| llama-server   | `http://odsod-desktop:8179/v1/chat/completions` | Cleanup (Qwen 3.5) |

System: `pipewire-utils`, `pulseaudio-utils` (parec), `libnotify`.

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

## Segmentation (Layer 2)

Pure function: reads transcript event log → outputs segment boundaries with metadata.

**Boundary rules** (priority order):

1. `✂️ split` → hard boundary (user override)
2. `🎙 PipeWire: stream destroyed` → meeting app released mic
3. `⏸ Silence: 5 min` with no active context → natural boundary
4. New calendar event while previous segment open → split

**Execution**: batch every 10 min (with lookahead), immediately on `✂️ split`, on shutdown.

## Summarization (Layer 3)

Triggered on segment close. Input is already clean text from Layer 1.

- Extract: title, key decisions, action items, open questions
- Write draft interaction to `~/Vaults/odsod/inbox/YYYY-MM-DD-<slug>.md`
