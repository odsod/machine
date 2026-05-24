# Cursor

## Files

- `cli-config.json` - Shared agent CLI settings committed to the repo
- `~/.cursor/cli-config.json` - Live config merged with repo settings on install
- `hooks.json` / `hooks/` - User-level agent hooks (stop notification)

## Targets

- `make -C cursor` - Install RPM, extensions, IDE config, CLI config, hooks
- `make -C cursor cursor-config-diff` - Show trackable CLI config drift vs live config

## Workflow

- Keep repo-managed defaults in `cli-config.json`
- Run `make -C cursor` after changes to shared CLI config or hooks
- Run `make -C cursor cursor-config-diff` before reviewing drift
- Model picker, auth, and cache fields live only in `~/.cursor/cli-config.json`

## Constraints

- Do not symlink `~/.cursor/cli-config.json` — merge preserves machine-local cache
- Shared skills: `~/.cursor/skills` → `.agents/skills` (installed by `.agents` module)
- Hook paths in `hooks.json` are relative to `~/.cursor/`
