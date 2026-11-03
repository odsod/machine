# Codex

## Config Drift

- `config.toml` holds repo defaults. `~/.codex/config.toml` is a plain file
  because Codex writes per-project trust entries, `hooks.state`, and NUX
  counters into it at runtime.
- A `merge = "missing"` `[dotfiles]` entry seeds the keys in `config.toml`
  that the live file lacks. Codex owns them after that.
- Copy intentional setting changes into `config.toml` by hand (never workspace
  paths or runtime state).
- Never add standing project trust to `config.toml`; each `jj` workspace should
  prompt for trust on first use.
