# Codex

## Files

- `config.toml` - Shared base config committed to the repo
- `~/.codex/config.toml` - Live config used and mutated by Codex trust prompts
- `sync-config.py` - Sync shared keys from `config.toml` into `~/.codex/config.toml`

## Targets

- `make -C codex` - Install binary, initialize `~/.codex/config.toml` once if missing
- `make -C codex codex-config-diff` - Show pending shared-config changes against the live config
- `make -C codex codex-config-sync` - Apply shared-config changes while preserving `[projects."..."]` trust entries from the live config

## Workflow

- Let Codex trust prompts write directly to `~/.codex/config.toml`
- Keep repo-managed defaults in `config.toml`
- Run `make -C codex codex-config-sync` after changes to `config.toml`
- Run `make -C codex codex-config-diff` before syncing when reviewing drift

## Constraints

- `sync-config.py` preserves only the live `projects` table
- Local edits outside `projects` in `~/.codex/config.toml` are overwritten on sync
- Do not reintroduce a symlink from `~/.codex/config.toml` to `config.toml`
