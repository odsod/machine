# Codex

## Files

- `config.toml` - Shared base config committed to the repo; the single source
  of truth
- `~/.codex/config.toml` - Live config written by Codex trust prompts and
  runtime state

## Tasks

- Binary: `[tools] codex` in root `mise.toml`
- `mise run setup:codex` - Check drift between live and repo config; fails
  `mise run apply`/`bootstrap` until resolved
- `mise run codex:diff` - Show the drift diff
- `mise run codex:resolve` - Resolve drift by overwriting the live config with
  the repo config

## Workflow

- Let Codex trust prompts write directly to `~/.codex/config.toml`
- Keep repo-managed defaults in `config.toml`
- `mise run codex:diff` to review drift, `mise run codex:resolve` to resolve
- Trust is never granted standing in the base config; jj workspaces create
  fresh directories, so each one should prompt for trust

## Constraints

- Resolve drops runtime state (per-project trust entries, `hooks.state`
  hash, NUX counters); Codex re-prompts for the current directory and the
  hook on next use
- Do not reintroduce a symlink or a merge script
