# Codex

## Config Drift

- `config.toml` holds repo defaults. `~/.codex/config.toml` is a plain file
  because Codex writes per-project trust entries, `hooks.state`, and NUX
  counters into it at runtime.
- `mise run codex:check` diffs the live file against `config.toml` and gates
  `mise run apply`.
- Copy intentional setting changes into `config.toml` (never workspace paths or
  runtime state), then run `mise run codex:resolve` to overwrite
  `~/.codex/config.toml`.
- Never add standing project trust to `config.toml`; each `jj` workspace should
  prompt for trust on first use.
