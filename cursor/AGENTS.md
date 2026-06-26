# Cursor

## Files

- `cli-config.json` - Shared agent CLI settings committed to the repo
- `~/.cursor/cli-config.json` - Live config merged with repo settings on install
- `hooks.json` / `hooks/` - User-level agent hooks (stop notification)

## Targets

- `make -C cursor` - Install RPM, extensions, IDE config, CLI config, hooks
- `make -C cursor discover` - Print pinned `version` and `rpm_url` for bumps
- `make -C cursor cursor-config-diff` - Show trackable CLI config drift vs live config

## Version bumps

Cursor RPMs use a **pinned production URL**, not the `/latest` redirect.

- `/latest` resolves to a redirect; the real asset lives at
  `downloads.cursor.com/production/<commit-hash>/.../cursor-<version>.el8.x86_64.rpm`
- The commit hash in that path changes every release — a stale hash returns
  `AccessDenied`
- Do **not** download from `/latest` in the Makefile — it breaks idempotency
  (version in Makefile can drift from what `/latest` serves)

**Bump workflow** (same pattern as `antigravity/` — update both fields together):

1. `make -C cursor discover` — copy **both** lines into `Makefile`:
   - `version := …`
   - `rpm_url := …`
2. Validate: `curl -I '<rpm_url>'` — expect `HTTP/2 200`
3. Install: `make -C cursor install-rpm`
4. Verify: `rpm -q cursor` and `/usr/bin/cursor --version`

**Idempotency**

- RPM cached at `~/.local/share/odsod/machine/data/cursor/<version>/cursor.rpm`
- Install recorded at `…/<version>/cursor-installed.stamp`
- Re-run `make -C cursor install-rpm` → `Nothing to be done` when stamp exists
- Bumping `version` uses a new data-dir path; old version dirs are inert

## Workflow

- Keep repo-managed defaults in `cli-config.json`
- Run `make -C cursor` after changes to shared CLI config or hooks
- Run `make -C cursor cursor-config-diff` before reviewing drift
- Model picker, auth, and cache fields live only in `~/.cursor/cli-config.json`

## Constraints

- Do not symlink `~/.cursor/cli-config.json` — merge preserves machine-local cache
- Shared skills: `~/.cursor/skills` → `.agents/skills` (installed by `.agents` module)
- Hook paths in `hooks.json` are relative to `~/.cursor/`
- Never bump `version` without updating `rpm_url` from `discover` output
