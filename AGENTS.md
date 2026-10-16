# Agent Instructions

Project-specific instructions for the `machine` repo. Global agent
instructions live in `agents/AGENTS.md`. Do not duplicate them here.

## Principles

- **Declarative first**: Express desired state in `mise.toml` and `mise/conf.d/`,
  and fall back to `tasks/` only for imperative steps.
- **Single source of truth**: `mise.toml` plus `mise/conf.d/` is the global
  config.
- **Single modularity mechanism**: `mise/conf.d/` holds all topic modules. Do
  not add nested `<topic>/mise.toml` files.
- **Minimalism**: Standard mise features > custom scripts.

## Structure

- **`mise.toml`**: Root config for mise settings, `[tools]`, and `[env]`.
  `[tools]` stays here on purpose: mise anchors `mise.lock` to the
  highest-precedence config that defines tools, so moving them into fragments
  would relocate the lockfile.
- **`mise/conf.d/`**: Global config fragments, loaded in alphabetical order
  before `mise.toml`. `~/.config/mise/conf.d` is a directory symlink to
  `mise/conf.d/`. Paths in `[dotfiles]` and `[bootstrap.files]` resolve against
  `mise/conf.d/`, so repo files need a `../../` prefix.
  - **`00-machine.toml`**: Cross-cutting system base (`env.sh` links, `mise`
    self-deploy links, core packages, vendor RPM repos, groups/users, sudoers,
    `/tmp`, swap, and top-level orchestration tasks `discover`, `bump`, `apply`,
    `clean`, `bootstrap`).
  - **`<topic>.toml`**: One file per topic (`fish.toml`, `herdr.toml`,
    `kde.toml`, `kwin.toml`, `keys.toml`, `llama.toml`, `whisper.toml`,
    `endpoint-verification.toml`, ...). Owns that topic's `[vars]`,
    `[dotfiles]`, `[bootstrap.*]`, and `[tasks."<topic>:*"]`.
- **`env.sh`**: Permanent. Single source of truth for environment variables.
- **`tasks/`**: Cross-cutting lifecycle and base-system scripts (`apply.sh`,
  `bump.sh`, `discover.sh`, `clean.sh`, `setup-swapfile.sh`, `setup-tmp.sh`).
- **Topic directories** (`fish/`, `neovim/`, `ghostty/`, `llama/`, etc.):
  Config files, service templates, topic setup scripts (`llama/setup.sh`,
  `whisper/setup.sh`, `herdr/setup-machines.sh`), and source code referenced by
  `mise/conf.d/<topic>.toml`.
- **`~/.local/share/odsod/machine/data/`**: Runtime build trees, extracted
  archives, and model weights (`llama/`, `whisper/`, `endpoint-verification/`).
  Never store compiled trees or downloaded artifacts in the repo.

### Dependency Direction

Dependency flows strictly one way: **`mise/conf.d/<topic>.toml` -> `<topic>/`**.

- `mise/conf.d/<topic>.toml` knows about `<topic>/`: it links files from
  `../../<topic>/`, runs scripts in `<topic>/`, and passes `[vars]` into scripts
  via task `env = { ... }`.
- `<topic>/` never reads or parses `mise/conf.d/*.toml`. Topic scripts take
  their inputs from environment variables supplied by the `mise` task.
- Cross-cutting scripts in `tasks/` (`discover.sh`, `bump.sh`) are the only
  scripts that read or write `mise/conf.d/*.toml`.

## Provisioning

- **Bootstrap**: `mise bootstrap --yes` provisions the full machine.
- **Fresh machine**: Run `./bootstrap.sh` to install `mise` and run initial
  convergence.
- **Status check**: `mise bootstrap status --missing`
- **Execution plan**: `mise bootstrap plan`
- **Dry run**: `mise bootstrap --dry-run`

## Workflow: Version Bumping

Run `mise run bump` to upgrade `[tools]` with `mise upgrade --bump`, then
discover, pre-flight verify, and update every self-managed pin. That covers
desktop apps, endpoint-verification, the GPU services that compile from source,
and the Neovim plugin lock. It writes only version files (`mise.toml`, the
`mise/conf.d/*.toml` fragments, `mise.lock`, and `neovim/nvim-pack-lock.json`)
plus the tool installs that `mise upgrade` does. It does not apply config or run
convergence. Run `mise run apply` for that. Pass `mise run bump <name>` to bump
a single pin, or `--dry-run` to preview.

To inspect versions manually, start with `mise run discover`. Before probing
anything it refuses to run while any PR is open on the remote: the bump work may
already be half-done in that PR, from this machine or another. When it aborts,
list the PRs with `gh pr list`, then merge or close them. Pull the result before
rerunning: `jj git fetch --remote origin && jj rebase -o main@origin`.

The task then prints one row per pinned thing with the
pinned version, the latest upstream release, and `ok` / `BUMP` / `?`, then runs
`mise outdated` for `[tools]`. It reads GitHub through `gh api`, so `gh auth
status` must show a login. A `?` means the probe matched nothing, which usually
means upstream changed its release scheme: fix the probe in `tasks/discover.sh`
before trusting the row.

- **Desktop apps** (Slack, Zoom, Cursor, Yaak, SoapUI, Obsidian): edit `[vars]`
  in `mise/conf.d/00-machine.toml` (Slack, Zoom, Yaak, SoapUI),
  `mise/conf.d/cursor.toml`, or `mise/conf.d/obsidian.toml`. Nothing else holds
  an app version. Cursor needs `cursor_hash` bumped with `cursor_version`; both
  values come from the same `discover` rows (see `cursor/AGENTS.md`). Fonts use
  `brew-cask:font-*` under `[bootstrap.packages]` in `mise/conf.d/kde.toml` and
  update via package bootstrap.
- **mise tools**: `[tools]` uses `latest` (runtimes keep a major prefix:
  `node = "26"`, `python = "3.15"`, `go = "1.27"`). Exact versions live in
  `mise.lock`. `mise run bump` runs `mise upgrade --bump`, so a full bump moves
  those major prefixes and rewrites the lockfile. For a range-only upgrade by
  hand, use `mise upgrade`. Both need `GITHUB_TOKEN` (e.g. `gh auth token`) or
  GitHub rate-limits leave platforms missing. Commit `mise.lock`. After
  installs, `mise reshim`.
- **GPU services** (llama, whisper): update `llama_version` or `whisper_version`
  in `[vars]` in `mise/conf.d/llama.toml` or `mise/conf.d/whisper.toml`. The
  setup tasks pass `[vars]` to `llama/setup.sh` and `whisper/setup.sh` (single
  source). Both pin the newest non-prerelease semver tag, not a `bNNNN`
  nightly, and the setup scripts add the `v` prefix because GitHub source
  tarballs drop it. Both repos also publish `bNNNN` build tags, and
  `/releases/latest` has pointed at one of those, so `discover` filters on
  release shape instead. Source and build trees live under
  `~/.local/share/odsod/machine/data/llama` and `.../whisper`. After a bump,
  `mise run apply` rebuilds the service. Its setup script restarts a running
  service only when the installed version or unit file changed.
- **Neovim plugins**: a full bump updates every plugin and syncs
  `neovim/nvim-pack-lock.json` from the actual checkouts. `mise run bump neovim`
  updates only the plugins. `odsod.pack.update()` in `neovim/lua/odsod/pack.lua`
  does the work, and the neovim `postinstall` hook calls it too.
- **endpoint-verification**: `mise run endpoint-verification:discover` prints
  `endpoint_verification_version`, `endpoint_verification_deb`, and
  `endpoint_verification_sha256` as a paste-ready `[vars]` block for
  `mise/conf.d/endpoint-verification.toml`. All three move together: the
  filename carries a per-build hash, and install verifies the checksum.
- **Obsidian**: some tags ship an Android APK only. `discover` reports the
  newest release that has a desktop AppImage, so trust that row over the tag.

### After editing pins

Editing `[vars]` changes nothing on disk. Run these in order.

1. `mise run apply` converges packages, services, dotfiles, tools, and desktop
   apps, then runs `mise run clean`. `mise run bump` does not call it, so run it
   yourself after every bump. It must succeed before you finish.
   If it stops on `codex:check` or `antigravity:check`:
   - Inspect the diff first.
   - Integrate any intentional config changes (model, effort, preferences) back
     into the repo config. Never keep workspace paths or runtime state.
   - Run the resolve task (`mise run codex:resolve` or
     `mise run antigravity:resolve`).
   - Re-run `mise run apply` until it succeeds.
     `mise run apply --force` resolves both configs and then converges in one
     step. Use it only when the drift holds nothing worth keeping.
2. Restarting a GPU service is automatic: `llama:setup` and `whisper:setup`
   restart a running service when the installed version or unit file changed.
3. `clean` runs at the end of `mise run apply`, never first. Clean deletes the
   source tree the running service still points at, so never run it before the
   rebuild. Old `llama.cpp-*` and `whisper.cpp-*` source trees accumulate under
   `~/.local/share/odsod/machine/data`, and `clean` keeps only the pinned ones.
4. Verify: `mise run discover` shows every row `ok`, `mise run apply` succeeds
   with zero errors, `mise bootstrap --dry-run` reports no work, and each
   service answers on its port, for example
   `curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8179/health`.

If `mise bootstrap` stops with "refusing to overwrite existing files", an app
has replaced its dotfile symlink with a real file. Copy the live file into the
repo before using `--force-dotfiles`, or its runtime edits are lost.

## Workflow: Applying Changes from Another Machine

After pulling commits that changed `mise.toml`, `mise/conf.d/`, or `mise.lock`:

```
mise run apply
```

Runs full `mise bootstrap --yes` (packages, services, files, dotfiles,
tools, desktop apps) then regenerates shims.

### Bumping mise itself

mise is bootstrapped via the upstream dnf repo, then self-managed via `[tools]`.

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

| What                       | Where                                                                                        |
| -------------------------- | -------------------------------------------------------------------------------------------- |
| New dev tool binary        | `mise use <tool>` (adds to `[tools]` in `mise.toml`)                                         |
| New system package         | Add `"dnf:<pkg>" = "latest"` to `[bootstrap.packages]` in `mise/conf.d/<topic>.toml`         |
| New font                   | Add `"brew-cask:font-<name>" = "latest"` to `[bootstrap.packages]` in `mise/conf.d/kde.toml` |
| New config symlink         | Add entry with `../../` prefix to `[dotfiles]` in `mise/conf.d/<topic>.toml`                 |
| New env var                | Add to `env.sh` (picked up by mise, KDE, systemd)                                            |
| New systemd system service | Add to `[bootstrap.services]` in `mise/conf.d/<topic>.toml`                                  |
| New privileged file        | Add with `../../` prefix to `[bootstrap.files]` in `mise/conf.d/<topic>.toml`                |
| Complex imperative setup   | Add script to `tasks/`, wire into `[tasks."<topic>:*"]` in `mise/conf.d/<topic>.toml`        |
| New pinned desktop app     | Add `<app>_version` to `[vars]` in `mise/conf.d/`, probe in `discover` and `bump`            |

## Config Sections (`mise.toml` and `mise/conf.d/*.toml`)

| Section                 | Location             | Purpose                                                |
| ----------------------- | -------------------- | ------------------------------------------------------ |
| `[settings]`            | `mise.toml`          | Mise behavior config                                   |
| `[tools]`               | `mise.toml`          | Versioned dev tool binaries (anchors `mise.lock`)      |
| `[env]`                 | `mise.toml`          | Sources `env.sh` via `_.source`, sets `REPO_DIR`       |
| `[vars]`                | `mise/conf.d/*.toml` | Pinned versions and model parameters                   |
| `[dotfiles]`            | `mise/conf.d/*.toml` | Config symlinks (`../../` prefix) and inline dotfiles  |
| `[bootstrap.dnf.repos]` | `mise/conf.d/*.toml` | COPR repositories (`ghostty`, `scrcpy`)                |
| `[bootstrap.packages]`  | `mise/conf.d/*.toml` | dnf, brew-cask (fonts), flatpak packages               |
| `[bootstrap.hooks.*]`   | `mise/conf.d/*.toml` | Pre/post hooks for packages and tools                  |
| `[bootstrap.files]`     | `mise/conf.d/*.toml` | Privileged files (sudoers, sshd, xkb, yum.repos.d)     |
| `[bootstrap.groups]`    | `mise/conf.d/*.toml` | System group declarations                              |
| `[bootstrap.users]`     | `mise/conf.d/*.toml` | System user accounts and group memberships             |
| `[bootstrap.services]`  | `mise/conf.d/*.toml` | System services (sshd, docker, tailscaled, odsod-keys) |
| `[tasks.*]`             | `mise/conf.d/*.toml` | Setup and lifecycle tasks (`<topic>:<action>`)         |

## Key Design Decisions

- **Why `mise/conf.d/<topic>.toml` is separate from `<topic>/`**: `mise`
  resolves relative paths in `[dotfiles]` and `[bootstrap.files]` against
  `path.parent()` of the loaded config path (`~/.config/mise/conf.d/<topic>.toml`)
  without canonicalizing file symlinks first. A directory symlink
  (`~/.config/mise/conf.d` -> `mise/conf.d/`) lets `../..` traverse back into
  the repo root, whereas per-file symlinks from `~/.config/mise/conf.d/` into
  `<topic>/` would resolve relative paths against `~/.config/mise/conf.d/` and
  break. Keeping `mise.toml` out of `<topic>/` also prevents `mise` from
  auto-discovering a second project config when you `cd` into `<topic>/`.
- **`env.sh` is permanent**: KDE and systemd do not run mise. They source
  `env.sh` via `~/.profile` and `~/.config/plasma-workspace/env/`.
- **`[bootstrap.services]`** is system-level only (not `--user`). User units are
  enabled in `[bootstrap.hooks.post-packages]` or setup tasks.
- **`[bootstrap.files]`** needs `replace = true` to convert existing symlinks or
  package-owned config files into plain files.
- **`github:` backend** for GitHub release tools (replaces deprecated `ubi:`).
- **Fish login shell** uses a stable binary at `/usr/local/bin/fish` installed
  by the `github:fish-shell/fish-shell` `postinstall` hook.
- **Neovim as vim/vi**: The `neovim` `postinstall` hook removes
  `vim-enhanced`/`vim-minimal` RPMs and symlinks `~/.local/bin/vim` and `vi`.
- **Fonts**: `brew-cask:font-*` installs directly to `~/.local/share/fonts` without Homebrew.
- **Apps that rewrite their own config**: Antigravity writes `model` and
  `trustedWorkspaces` into its settings at runtime, and Cursor's live
  `cli-config.json` holds `authInfo` and auth cache keys; none of that may
  reach this public repo. Their live files are plain files, not symlinks.
  `antigravity:check` and `codex:check` gate `mise run apply`: they fail
  with a diff while runtime state drifts. Inspect the diff first. Integrate
  any intentional settings back into the repo config. Never keep workspace
  paths or runtime state. `antigravity:resolve` and `codex:resolve` overwrite
  the live file with the repo copy, dropping private runtime state and letting
  the app re-prompt.

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
  `~/.agents` and links its `AGENTS.md` to the names Claude, Codex and Antigravity
  look for.
- The `~/.claude/skills` link exists because Claude Code reads only its own
  directories. Cursor reads the `.agents` paths itself, so it needs no link.
- A skill only about this repo goes in `.agents/skills/`, with a
  `.claude/skills` symlink beside it. Create one only when a real procedure has
  proved itself, not to record what a source repo already explains.
- `mise run update-skills` pulls new upstream releases of the vendored global
  skills and rewrites `agents/.skill-lock.json`.
- This repo is public. Keep employer names, private repo names and account
  identifiers out of `agents/AGENTS.md`; they belong in that employer's own repo.

## Home Folder

See "Layout" in `agents/AGENTS.md` for the standard directory layout.
