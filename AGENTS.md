# Agent Instructions

## Principles
- **Minimalism**: Standard solutions > Custom scripts.
- **Simplicity**: Idempotent, readable Makefiles.

## Structure
- **Root Makefile**: Orchestrator (`make install`).
- **Subdirs**: Tool-specific logic.
    - **Config**: Symlink to location required by tool (often `~/.config/<tool>/`).
    - **Binaries**: Symlink/Install to `~/.local/bin/`.
    - **Resources**: Download/Extract to `~/.local/share/odsod/machine/<tool>/`. **Do not** use `build/` in the repo.
    - **Environment**: `~/.config/environment.d/*.conf`.

## Package Management
- **Preference**: RPM > Flatpak > Manual.
- **Repos**: Terra > COPR > RPM Fusion.

## Workflow: Updates
1. **Discover**: GitHub Releases / APIs (e.g. `api2.cursor.sh`).
2. **Validate**: `curl -I <url>`.
3. **Apply**: Update `version` in `Makefile`. No trailing whitespace.
4. **Verify**: `make -C <dir>` then `<tool> --version`.
5. **Commit**: `feat(<dir>): bump to v<version>`.

## Commit Attribution
- Follow Conventional Commits.
- **Short Headings**: Keep headings concise. Use the body for details if needed.
- **Template**: `feat(scope): description`.

## Maintaining This File
- **Format**: Headers + bullets - No paragraphs.
- **Style**: Concise, direct, action-oriented. No filler or pleasantries.
- **Commit Format**: `docs: update AGENTS.md`. Use `git commit --amend` for small tweaks.

