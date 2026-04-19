# Agent Instructions

Project-specific instructions for the `machine` repo. Global agent
instructions live in `.agents/AGENTS.md` — do not duplicate them here.

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

## Module Dependencies

- **Default**: Keep modules independent.
- **Convention**: Express dependencies only in consumer modules with explicit calls (e.g. `$(MAKE) -C ../nodejs ~/.local/bin/npm`).
- **Avoid**: Central dependency graphs and root ordering lists.

## Home Folder

See "File System" in `.agents/AGENTS.md` for the standard directory layout.

## Package Management

- **Preference**: RPM > Flatpak > Manual.
- **Repos**: Terra > COPR > RPM Fusion.

## Workflow: Updates

**Trigger**: "Let's bump versions" -> Agents must check ALL tools.

1.  **Start Clean**:
    - Top-level repo: ensure the working tree is committed before changing versions.
    - Top-level repo: `jj git fetch --remote origin`
    - Top-level repo: if `jj log -r '@ & ~descendants(main@origin)' --no-graph` is non-empty, run `jj rebase -d main@origin`
    - `.agents/`: if external skills may be updated, `cd .agents`
    - `.agents/`: ensure the working tree is committed before updating skills
    - `.agents/`: `jj git fetch --remote origin`
    - `.agents/`: if `jj log -r '@ & ~descendants(main@origin)' --no-graph` is non-empty, run `jj rebase -d main@origin`

2.  **Identify Candidates**:
    - Search for `version :=` (or variations like `gopls_version :=`) to find all tools managed by version variables.

3.  **Discover**:
    - Check `# Discovery: <url>` comment above each version variable. **Mandatory** to add if missing.
    - **Quality**: URL must be future-proof (e.g., `latest` endpoints, releases pages). Avoid hardcoded version paths in discovery URLs unless unavoidable.
    - Check GitHub Releases, APIs, or project downloads pages.

4.  **Validate**:
    - For archive-based tools: `curl -I <url>` to ensure assets exist.
    - For `go install` tools: Ensure the version string is valid for the module.

5.  **Apply**: Update version variables in `Makefile`. No trailing whitespace.

6.  **Verify**: `make -C <dir>` then `<tool> --version`.
    - For `codex/`: run `make -C codex codex-config-diff`
    - If `codex/config.toml` changed: run `make -C codex codex-config-sync`
    - Check `<dir>/AGENTS.md` for module-specific update notes.

7.  **External Skills** (in `.agents/skills/`):
    - Check: `npx skills check -g`
    - Update: `npx skills update -g`, or re-add individual skills:
      ```
      npx skills add anthropics/skills -s skill-creator -y -g --copy
      npx skills add vercel-labs/agent-browser -s agent-browser -y -g --copy
      npx skills add anthropics/claude-plugins-official -s claude-md-improver -y -g --copy
      ```
    - `-g` writes to `~/.agents/` which symlinks to `.agents/` in this repo
    - Lock file: `.agents/.skill-lock.json` (v3 format)
    - Commit in `.agents/`: `jj describe -m "feat(skills): update external skills"`

8.  **Commit**: `feat(<dir>): bump versions`.
    - List specific tool bumps in the commit body.
    - **Optional**: Include release notes/changelog link in body if easily fetchable.

## Commit style

- Follow Conventional Commits.
- **CRITICAL**: Header MUST be <= 50 chars. Verify before committing.
- **Template**: `feat(scope): description`.

## jj

- Use jj for all version control operations
- Remote read operations are allowed (`jj git fetch`, release/API queries, cloning)
- Do not push to the remote repo, leave this to the user

## Nested Workspaces

- **Pattern**: Use ignored nested workspaces for independent inner repos (no submodules).
- **Setup**: Add directory to `.gitignore`, then `jj git clone <url> <path>`.
- **Workflow**: `cd` into the nested directory to perform `jj` operations. They are fully independent of the parent workspace.

### .agents/ (github.com/odsod/agents)

- **Purpose**: Agent skills (tmux, skill-creator, etc.)
- **Install**: `make install` clones if `.agents/.jj` is absent.
- **Update**:
  - `cd .agents`
  - Ensure the working tree is committed before starting work
  - `jj git fetch --remote origin`
  - If `jj log -r '@ & ~descendants(main@origin)' --no-graph` is non-empty, run `jj rebase -d main@origin`
  - Only then start the `.agents` update work

## Maintaining This File

- **Format**: Headers + bullets - No paragraphs.
- **Style**: Concise, direct, action-oriented. No filler or pleasantries.
- **Commit Format**: `docs: update AGENTS.md`. Use `git commit --amend` for small tweaks.
