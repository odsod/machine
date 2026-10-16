# Cursor

## RPM Pinning

- Pin both `cursor_version` and `cursor_hash` in `mise/conf.d/cursor.toml` from
  the same `mise run discover` output (or `mise run bump cursor`).
- Never install directly from `/latest`. The production asset lives under
  `downloads.cursor.com/production/<cursor_hash>/...` and returns `AccessDenied`
  when `cursor_hash` does not match `cursor_version`.
- `mise run cursor:setup` skips installation when `rpm -q --qf '%{VERSION}' cursor`
  matches `cursor_version`.

## CLI and Hooks

- `mise run cursor:setup-cli` copies `cli-config.json` to
  `~/.cursor/cli-config.json` only when the live file is missing. Keep the live
  file as a plain file so auth and model-picker state stay out of the repo.
- Hook paths in `hooks.json` resolve relative to `~/.cursor/`.
- Do not symlink `~/.cursor/skills`; Cursor reads `~/.agents/skills` and
  `.agents/skills` directly.
