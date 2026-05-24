# Recorder — Machine Module

Installation and configuration for the [recorder](https://github.com/odsod/recorder) daemon.

## Source

- **Repo**: `github.com/odsod/recorder`
- **Local checkout**: `~/Code/github.com/odsod/recorder`
- **Install method**: `go install github.com/odsod/recorder@<hash>`

## Install

```bash
make -C recorder install          # full: deps + binary + config + scripts
make -C recorder install-tool     # rebuild binary only
```

## Structure

```
recorder/
├── Makefile            # Installation targets
├── AGENTS.md           # This file
├── config.json         # Shared config (symlinked to ~/.config/recorder/)
├── recorder-toggle     # Fish script — tmux session manager
└── recorder-note       # Bash script — kdialog note popup
```

## Config

Symlinked to `~/.config/recorder/config.json`. Single config works on all hosts via Tailscale hostname resolution (`odsod-desktop` resolves everywhere).

```json
{
  "whisper": { "url": "...", "timeoutS": 60 },
  "llm": { "url": "...", "model": "default", "timeoutS": 180 },
  "transcript": { "outputDir": "~/Vaults/odsod/raw/transcripts" },
  "segments": { "outputDir": "~/Vaults/odsod/inbox" },
  "dedup": { "threshold": 0.6 },
  "signals": { "silenceThresholdS": 180, "cdpPorts": [9224, 9223] },
  "log": { "file": "~/.local/share/recorder/recorder.jsonl" },
  "promptVars": { "languages": [...], "owner": { "role": "...", "summaryFor": "..." }, "includeInSummary": [...] },
  "prompts": { "cleanup": "~/.config/recorder/prompts/cleanup.md", ... }
}
```

- **`promptVars`** — template variables for system prompts (languages, owner context, summary content guidance)
- **`prompts`** — paths to prompt template files; seeded with defaults on first run if missing

## Scripts

- **`recorder-toggle`** — creates/switches a tmux session with recorder daemon + transcript tail
- **`recorder-note`** — KDE popup (kdialog) that appends a note to the active transcript

## Dependencies

- `pipewire-utils` (parec) — audio capture
- `kdialog` — note popup UI
- whisper-server (`http://odsod-desktop:8178`) — ASR
- llama-server (`http://odsod-desktop:8179`) — LLM cleanup

## Version Bumps

1. Get latest commit hash from `https://github.com/odsod/recorder/commits/main`
2. Update `version :=` in `Makefile`
3. `make -C recorder install-tool`
4. Verify: `recorder run`
