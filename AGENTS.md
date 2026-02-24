# Agent Instructions

## Principles
- **Minimalism**: Standard solutions > Custom scripts.
- **Simplicity**: Idempotent, readable Makefiles.
- **Automation**: All commands MUST be non-interactive (e.g., `dnf install -y`).

## Structure
- **Root Makefile**: Orchestrator (`make install`).
- **Subdirs**: Tool-specific logic.
    - **Config**: Symlink (`ln -fsT`) to location required by tool (often `~/.config/<tool>/`).
    - **Binaries**: Symlink/Install to `~/.local/bin/`.
    - **Resources**: Download/Extract to `~/.local/share/odsod/machine/data/<tool>/<version>/`.
        - Symlink active version (`ln -fsT`) to `~/.local/share/odsod/machine/<tool>` if needed.
- **Environment**: `env.sh` (POSIX sh).
    - **Role**: Source of Truth for all environment variables and PATH.
    - **Install**: Symlinked to `~/.profile` and `~/.config/plasma-workspace/env/odsod-machine.sh` by Root Makefile.

## Development
- **Efficiency**: Iterating on configs should not trigger a full `make`. Use specific targets.

## Package Management
- **Preference**: RPM > Flatpak > Manual.
- **Repos**: Terra > COPR > RPM Fusion.

## Workflow: Updates
**Trigger**: "Let's bump versions" -> Agents must check ALL tools.

1.  **Identify Candidates**:
    - Search for `version :=` to find tools managed by version variables.

2.  **Discover**:
    - Check `# Discovery: <url>` in Makefile. **Mandatory** to add if missing.
    - **Quality**: URL must be future-proof (e.g., `latest` endpoints, releases pages). Avoid hardcoded version paths in discovery URLs unless unavoidable.
    - Check GitHub Releases, APIs, or project downloads pages.

3.  **Validate**: `curl -I <url>` to ensure assets exist before editing Makefile.

4.  **Apply**: Update `version` in `Makefile`. No trailing whitespace.

5.  **Verify**: `make -C <dir>` then `<tool> --version`.

6.  **Commit**: `feat(<dir>): bump to v<version>`.

    - **Optional**: Include release notes/changelog link in body if easily fetchable.

## Commit style
- Follow Conventional Commits.
- **CRITICAL**: Header MUST be <= 50 chars. Verify before committing.
- **Template**: `feat(scope): description`.

## jj migration
- The user is in the process of migrating to jj. 
- Do all vcs operations using jj
- Provide explanations of your jj operations and workflows to the user
- Do not push to the remote repo, leave this to the user

## Nested Workspaces
- **Pattern**: Use ignored nested workspaces for independent inner repos (no submodules).
- **Setup**: Add directory to `.gitignore`, then `jj git clone <url> <path>`.
- **Workflow**: `cd` into the nested directory to perform `jj` operations. They are fully independent of the parent workspace.

## Maintaining This File
- **Format**: Headers + bullets - No paragraphs.
- **Style**: Concise, direct, action-oriented. No filler or pleasantries.
- **Commit Format**: `docs: update AGENTS.md`. Use `git commit --amend` for small tweaks.
