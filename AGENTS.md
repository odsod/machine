# Agent Instructions

Project-specific instructions for the `machine` repo. Global agent
instructions live in `agents/AGENTS.md`. Do not duplicate them here.

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

Start with `mise run discover`. It prints one row per pinned thing with the
pinned version, the latest upstream release, and `ok` / `BUMP` / `?`, then runs
`mise outdated` for `[tools]`. It reads GitHub through `gh api`, so `gh auth
status` must show a login. A `?` means the probe matched nothing, which usually
means upstream changed its release scheme: fix the probe in `tasks/discover.sh`
before trusting the row.

- **Fonts and desktop apps** (Inter, Iosevka, Nerd Fonts, Slack, Zoom, Cursor,
  Zed, Yaak, SoapUI, Obsidian): edit `[vars]` in `mise.toml`. Nothing else
  holds a version. Cursor needs `cursor_hash` bumped with `cursor_version`; both
  values come from the same `discover` rows (see `cursor/AGENTS.md`).
- **mise tools**: `[tools]` uses `latest` (runtimes keep a major prefix:
  `node = "24"`, `python = "3.12"`, `go = "1.26"`). Exact versions live in
  `mise.lock`. `mise upgrade` installs newer matches and rewrites the lockfile.
  Do not use `mise upgrade --bump` (that would change `node = "24"` to `"26"`).
  `npm:@typescript/native-preview` has no `latest`; keep the dated pin.
  `mise lock --global` needs `GITHUB_TOKEN` (e.g. `gh auth token`) or GitHub
  rate-limits leave platforms missing. Commit `mise.lock`. After installs,
  `mise reshim`.
- **GPU services** (llama, whisper): update `version` in `[vars]` in the topic
  `mise.toml`. The setup scripts read it from there (single source). Both pin
  the newest non-prerelease semver tag, not a `bNNNN` nightly, and the setup
  scripts add the `v` prefix because GitHub source tarballs drop it. Both repos
  also publish `bNNNN` build tags, and `/releases/latest` has pointed at one of
  those, so `discover` filters on release shape instead. After a bump, restart
  the user services: the setup scripts rewrite the units but do not restart an
  already-running service.
- **endpoint-verification**: `mise run -C endpoint-verification discover`
  prints `version`, `deb`, and `sha256` as a paste-ready `[vars]` block. All
  three move together: the filename carries a per-build hash, and install
  verifies the checksum.
- **Obsidian**: some tags ship an Android APK only. `discover` reports the
  newest release that has a desktop AppImage, so trust that row over the tag.

### After editing pins

Editing `[vars]` changes nothing on disk. Run these in order.

1. `mise run bootstrap` installs the new fonts, desktop apps, and GPU builds.
   Use `mise run apply` instead for full convergence including dotfiles.
2. Restart any GPU service whose version moved:
   `systemctl --user restart llama-server llama-embed whisper-server`.
3. `mise run clean` last, never first. It deletes the source tree the running
   service still points at. Old versions accumulate under
   `~/.local/share/odsod/machine/data` and as `llama.cpp-*` / `whisper.cpp-*`
   source trees, and it keeps only the pinned ones.
4. Verify: `mise run discover` shows every row `ok`, `mise bootstrap --dry-run`
   reports no work, and each service answers on its port, for example
   `curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8179/health`.

If `mise bootstrap` stops with "refusing to overwrite existing files", an app
has replaced its dotfile symlink with a real file. Copy the live file into the
repo before using `--force-dotfiles`, or its runtime edits are lost.

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
| New pinned desktop app     | Add `<app>_version` to `[vars]`, probe in `discover`   |

## mise.toml Sections

| Section                           | Purpose                                    |
| --------------------------------- | ------------------------------------------ |
| `[settings]`                      | Mise behavior config                       |
| `[vars]`                          | Pinned font and desktop app versions       |
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
- **Apps that rewrite their own config**: Antigravity writes `model` and
  `trustedWorkspaces` into its settings at runtime, so the symlink gets
  replaced by a real file. Before `mise bootstrap --force-dotfiles`, copy the
  live file back into the repo, or those edits are lost. Never copy
  `trustedWorkspaces` back: it holds workspace paths that name private repos and
  branches, and this repo is public. Drop the key and let Antigravity re-prompt.
  Cursor's `cli-config.json` stays unsymlinked because the live file holds
  `authInfo` and auth cache keys, which must not reach this public repo.

## Commit Style

- Follow Conventional Commits.
- **Header MUST be <= 50 chars.** Verify before committing.
- Template: `feat(scope): description`.

## jj

- Use jj for all version control operations.
- Remote read operations are allowed.
- Do not push to the remote repo; leave this to the user.

## Agents

`AGENTS.md` is the real file and `CLAUDE.md` is a symlink onto it, never a second
copy. The same holds for skills: `.agents/skills` is real, `.claude/skills` links
to it.

- `agents/` is the source for `~/.agents`: the instruction file every agent loads
  and the skills that apply in every repo (`herdr`). `[dotfiles]` links it to
  `~/.agents` and links its `AGENTS.md` to the names Claude, Codex and Gemini
  look for.
- The `~/.claude/skills` link exists because Claude Code reads only its own
  directories. Cursor reads the `.agents` paths itself, so it needs no link.
- A skill only about this repo goes in `.agents/skills/`, with a
  `.claude/skills` symlink beside it. There are none; add one only when a real
  procedure has proved itself, not to record what a source repo already explains.
- `mise run update-skills` pulls new upstream releases of the vendored global
  skills and rewrites `agents/.skill-lock.json`.
- This repo is public. Keep employer names, private repo names and account
  identifiers out of `agents/AGENTS.md`; they belong in that employer's own repo.

## Home Folder

See "Layout" in `agents/AGENTS.md` for the standard directory layout.
