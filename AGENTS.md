# Agent Instructions

## Principles
- **Minimalism**: Standard solutions > Custom scripts.
- **Simplicity**: Idempotent, readable Makefiles.
- **Automation**: All commands MUST be non-interactive (e.g., `dnf install -y`).

## Structure
- **Root Makefile**: Orchestrator (`make install`).
- **Subdirs**: Tool-specific logic.
    - **Config**: Symlink to location required by tool (often `~/.config/<tool>/`).
    - **Binaries**: Symlink/Install to `~/.local/bin/`.
    - **Resources**: Download/Extract to `~/.local/share/odsod/machine/data/<tool>/<version>/`.
        - Symlink active version to `~/.local/share/odsod/machine/<tool>` if needed.
    - **Environment**: `~/.config/environment.d/*.conf`.

## Package Management
- **Preference**: RPM > Flatpak > Manual.
- **Repos**: Terra > COPR > RPM Fusion.

## Workflow: Updates

**Trigger**: "Let's bump versions" -> Agents must check ALL tools.



1.  **Discover**:

    - Check `# Discovery: <url>` in Makefile. **Mandatory** to add if missing.

    - Check GitHub Releases, APIs (e.g., `api2.cursor.sh`), or `install.sh`.

2.  **Validate**: `curl -I <url>` to ensure assets exist.

3.  **Apply**: Update `version` in `Makefile`. No trailing whitespace.

4.  **Verify**: `make -C <dir>` then `<tool> --version`.

5.  **Commit**: `feat(<dir>): bump to v<version>`.

    - **Optional**: Include release notes/changelog link in body if easily fetchable.



## Commit Attribution
- Follow Conventional Commits.
- **Short Headings**: Keep headings concise. Use the body for details if needed.
- **Template**: `feat(scope): description`.

## Maintaining This File
- **Format**: Headers + bullets - No paragraphs.
- **Style**: Concise, direct, action-oriented. No filler or pleasantries.
- **Commit Format**: `docs: update AGENTS.md`. Use `git commit --amend` for small tweaks.

