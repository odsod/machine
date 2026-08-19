# Agent Instructions

Project-specific instructions for the `machine` repo. Global agent
instructions live in `.agents/AGENTS.md`. Do not duplicate them here.

## Principles

- **Declarative first**: Express desired state in `mise.toml`, fall back to
- **Single manifest**: `mise.toml` at the repo root is the global config
- **Minimalism**: Standard mise features > custom scripts.

## Structure

- **`mise.toml`**: Source of truth for tools, packages, dotfiles, services,
- **`env.sh`**: Permanent. Single source of truth for environment variables.
- **`tasks/`**: Shell scripts for imperative setup that can't be declarative
- **Topic directories** (`fish/`, `neovim/`, `ghostty/`, etc.): Config source
- **Nested `mise.toml`**: `llama/`, `whisper/`, `keys/`, `kwin/`,
  `endpoint-verification/` — local tasks via `mise run -C <dir> <task>`

## Provisioning

- **Bootstrap**: `mise bootstrap --yes` provisions the full machine.
- **Fresh machine**:
- **Status check**: `mise bootstrap status --missing`
- **Dry run**: `mise bootstrap --dry-run`

## Workflow: Version Bumping

- **mise tools**: `[tools]` uses `latest` (runtimes keep a major prefix:
  `node = "24"`, `python = "3.12"`, `go = "1.26"`). Exact versions live in
  `mise.lock`. `mise upgrade` installs newer matches and rewrites the lockfile.
  Do not use `mise upgrade --bump` (that would change `node = "24"` to `"26"`).
  `npm:@typescript/native-preview` has no `latest`; keep the dated pin.
  `mise lock --global` needs `GITHUB_TOKEN` (e.g. `gh auth token`) or GitHub
  rate-limits leave platforms missing. Commit `mise.lock`. After installs,
  `mise reshim`.
- **Desktop apps** (Slack, Zoom, Cursor, Zed, Yaak, SoapUI, Obsidian): update
  `version` in the corresponding `[tasks."setup:*"]` section in `mise.toml`.
  Cursor also needs the production URL hash (see `cursor/AGENTS.md`).
- **GPU services** (llama, whisper): `mise run -C llama discover` /
  `mise run -C whisper discover`, then update `version` in `[vars]` in the
  topic `mise.toml`. The setup scripts read it from there (single source).
- **Fonts** (Inter, Iosevka, Nerd Fonts): update `VERSION` in corresponding
  `[tasks."setup:font-*"]` section in `mise.toml`.
- **endpoint-verification**: `mise run -C endpoint-verification discover`
  (install always fetches latest; discover is informational).

## Workflow: Applying Changes from Another Machine

After pulling commits that changed `mise.toml` or `mise.lock`:

```
mise run apply
```

Runs full `mise bootstrap --yes` (packages, services, files, dotfiles,
tools, desktop apps) then regenerates shims.

### Bumping mise itself

mise is bootstrapped via COPR dnf package, then self-managed via `[tools]`.

1. Check latest: `mise self-update --dry-run` or GitHub releases
2. Read release notes for all versions since current:
   `defuddle parse https://github.com/jdx/mise/releases/tag/v<version> --md`
3. Evaluate each new feature against the current config:
   - Does it replace something imperative in our tasks/?
   - Does it simplify an existing section?
   - Does it enable removing a hook or script?
4. `mise upgrade aqua:jdx/mise` updates `mise.lock`; do not pin a version
   in `[tools]` (`"aqua:jdx/mise" = "latest"`)
5. Apply any config simplifications identified in step 3

## Adding Things

| What                       | Where                                                  |
| -------------------------- | ------------------------------------------------------ |
| New dev tool binary        | `mise use <tool>` (adds to `[tools]`)                  |
| New system package         | Add `"dnf:<pkg>" = "latest"` to `[bootstrap.packages]` |
| New config symlink         | Add entry to `[dotfiles]`                              |
| New env var                | Add to `env.sh` (picked up by mise, KDE, systemd)      |
| New systemd system service | Add to `[bootstrap.services]`                          |
| New privileged file        | Add to `[bootstrap.files]`                             |
| Complex imperative setup   | Add script to `tasks/`, wire into `[tasks]`            |

## mise.toml Sections

| Section                           | Purpose                                    |
| --------------------------------- | ------------------------------------------ |
| `[settings]`                      | Mise behavior config                       |
| `[tools]`                         | Versioned dev tool binaries                |
| `[env]`                           | Sources `env.sh` via `_.source`            |
| `[settings.dotfiles]`             | Dotfiles root config                       |
| `[dotfiles]`                      | Config symlinks (~46 entries)              |
| `[bootstrap.packages]`            | dnf, brew-cask (fonts), flatpak packages   |
| `[bootstrap.hooks.*]`             | Pre/post hooks for packages and tools      |
| `[bootstrap.files]`               | Privileged files (sudoers, sshd config)    |
| `[bootstrap.services]`            | System services (sshd, docker, tailscaled) |
| `[bootstrap.mise_shell_activate]` | Fish shell activation                      |
| `[tasks.*]`                       | Imperative setup scripts                   |

## Key Design Decisions

- **`env.sh` is permanent**: KDE and systemd don't run mise. They need env
- **`[bootstrap.linux.systemd.units]`** creates `dev.mise.*` units. Can't
- **`[bootstrap.services]`** is system-level only (not `--user`).
- **`[bootstrap.files]`** needs `replace = true` to convert existing symlinks
- **`github:` backend** for GitHub release tools (replaces deprecated `ubi:`).
- **Fish login shell** uses a stable symlink at `/usr/local/bin/fish` pointing
- **Neovim as vim/vi**: Remove vim-enhanced/vim-minimal RPMs, symlink in
- **Fonts**: `brew-cask:font-*` on Linux installs to `~/.local/share/fonts`

## Commit Style

- Follow Conventional Commits.
- **Header MUST be <= 50 chars.** Verify before committing.
- Template: `feat(scope): description`.

## jj

- Use jj for all version control operations.
- Remote read operations are allowed.
- Do not push to the remote repo; leave this to the user.

## Nested Workspaces

### .agents/ (github.com/odsod/agents)

- **Purpose**: Agent skills (tmux, skill-creator, etc.)
- **Install**: `mise bootstrap` clones if `.agents/.jj` is absent.
- **Update**: See global AGENTS.md for workflow.

## Home Folder

See "File System" in `.agents/AGENTS.md` for the standard directory layout.
