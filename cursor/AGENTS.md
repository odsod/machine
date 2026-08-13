# Cursor

## Files

- `cli-config.json` - Shared agent CLI settings committed to the repo
- `~/.cursor/cli-config.json` - Live config merged with repo settings on install
- `hooks.json` / `hooks/` - User-level agent hooks (stop notification)

## Tasks

- `mise run setup:cursor` - Install the Cursor RPM
- `mise run setup:cursor-cli` - Seed `~/.cursor/cli-config.json` if missing
- IDE settings, keybindings, and hooks are `[dotfiles]` symlinks

## Version bumps

Cursor RPMs use a **pinned production URL**, not the `/latest` redirect.

- `/latest` resolves to a redirect; the real asset lives at
  `downloads.cursor.com/production/<commit-hash>/.../cursor-<version>.el8.x86_64.rpm`
- The commit hash in that path changes every release — a stale hash returns
  `AccessDenied`
- Do **not** install from `/latest` — it breaks idempotency (pinned `version`
  can drift from what `/latest` serves)

**Bump workflow** (update version and URL hash together):

1. Discover:

   ```bash
   curl -sI https://api2.cursor.sh/updates/download/golden/linux-x64-rpm/cursor/latest
   ```

   `Location` is the production URL. Version is the `cursor-<version>.el8`
   segment.

2. Copy both into `[tasks."setup:cursor"]` in `mise.toml`:
   - `version="…"`
   - the `https://downloads.cursor.com/production/<hash>/...` RPM URL
3. Validate: `curl -I '<rpm_url>'` — expect `HTTP/2 200`
4. Install: `mise run setup:cursor`
5. Verify: `rpm -q cursor` and `/usr/bin/cursor --version`

**Idempotency**

- Install is skipped when `rpm -q --qf '%{VERSION}' cursor` matches `version`
- Never bump `version` without updating the production URL from discover

## Workflow

- Keep repo-managed defaults in `cli-config.json`
- `setup:cursor-cli` only seeds a missing live config; it does not merge
- Model picker, auth, and cache fields live only in `~/.cursor/cli-config.json`

## Constraints

- Do not symlink `~/.cursor/cli-config.json` — merge preserves machine-local cache
- Shared skills: `~/.cursor/skills` → `.agents/skills` (installed by `.agents`)
- Hook paths in `hooks.json` are relative to `~/.cursor/`
