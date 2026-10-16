# Agent Instructions

## Structure

- **`mise.toml`**: Root config for `[settings]`, `[tools]`, `[env]`, base system
  state (core CLI packages, user/sudoers, `/tmp`, swap, `mise.repo`), and
  top-level tasks (`discover`, `bump`, `apply`, `clean`, `bootstrap`). Keep
  `[tools]` here so `mise.lock` stays at the repo root.
- **`mise/conf.d/<topic>.toml`**: One global config fragment per topic, loaded
  in alphabetical order before `mise.toml`. Owns that topic's `[vars]`,
  `[dotfiles]`, `[bootstrap.*]`, and `[tasks."<topic>:*"]`.
- **`<topic>/`**: Config files, service templates, and setup scripts referenced
  by `mise/conf.d/<topic>.toml`. Do not add `<topic>/mise.toml` files.
- **`env.sh`**: Environment variables for `mise`, KDE (`~/.config/plasma-workspace/env/`),
  and login shells (`~/.profile`).
- **`tasks/`**: Cross-cutting scripts (`discover.sh`, `bump.sh`, `apply.sh`,
  `clean.sh`, `setup-swapfile.sh`, `setup-tmp.sh`).
- **`~/.local/share/odsod/machine/data/`**: Runtime source trees, builds,
  archives, and model weights (`llama/`, `whisper/`, `endpoint-verification/`).
  Never store build trees or downloaded artifacts in the repo.

### Dependency and Path Rules

- Dependency flows one way: `mise/conf.d/<topic>.toml` -> `<topic>/`.
- `mise/conf.d/<topic>.toml` links files from `../../<topic>/`, runs scripts in
  `<topic>/`, and passes `[vars]` to scripts via task `env = { ... }`.
- `<topic>/` scripts read inputs from environment variables only. Only
  `tasks/discover.sh` and `tasks/bump.sh` read or write `mise/conf.d/*.toml`.
- `~/.config/mise/conf.d` is a directory symlink to `mise/conf.d/`. `mise`
  resolves relative paths in `[dotfiles]` and `[bootstrap.files]` against
  `config_path.parent()` without canonicalizing file symlinks, so `../../` works
  only inside `mise/conf.d/*.toml`.
- `[bootstrap.services]` manages system units only. Enable `--user` units in
  `[bootstrap.hooks.post-packages]` or setup tasks.
- Set `replace = true` on `[bootstrap.files]` entries that replace symlinks or
  package-owned files.

## Provisioning and Convergence

- **Full convergence**: `mise run apply` runs `mise bootstrap --yes`,
  `mise reshim`, and `mise run clean`.
- **Inspect state**: `mise bootstrap status --missing`, `mise bootstrap plan`,
  or `mise bootstrap --dry-run`.
- **Fresh machine**: `./bootstrap.sh` trusts the config and runs
  `mise bootstrap --yes`.
- **Runtime config drift**: `antigravity:check` and `codex:check` gate
  `mise run apply`. Live `~/.gemini/antigravity-cli/settings.json` and
  `~/.codex/config.toml` are plain files because the apps write private runtime
  state into them. On failure, copy intentional setting changes into the repo
  (never workspace paths or auth state), then run `mise run antigravity:resolve`
  or `mise run codex:resolve` (or `mise run apply --force`).
- **Overwritten dotfile symlinks**: If an app replaces a `[dotfiles]` symlink
  with a plain file, copy wanted changes into the repo before running
  `mise bootstrap --force-dotfiles`.

## Version Bumping

- **`mise run discover`**: Compares every pin against upstream and runs
  `mise outdated`. Aborts if any PR is open on `origin`; close or merge open
  PRs, then `jj git fetch --remote origin && jj rebase -o main@origin`. Requires
  `gh auth status`. A `?` row means upstream changed its release format; fix the
  probe in `tasks/discover.sh` first.
- **`mise run bump [<name>] [--dry-run]`**: Runs `mise upgrade --bump` (using
  `GITHUB_TOKEN` from `gh auth token`) and updates pins in `mise/conf.d/*.toml`,
  `mise.lock`, and `neovim/nvim-pack-lock.json`. Does not apply changes.
- **After bumping**: Run `mise run apply`. Verify `mise run discover` shows all
  `ok`, `mise bootstrap --dry-run` has no pending work, and GPU services answer
  (`/health` on `127.0.0.1:8178` and `127.0.0.1:8179`).
- **Pin specifics**:
  - **Desktop apps** (`slack`, `zoom`, `cursor`, `yaak`, `soap-ui`, `obsidian`):
    Pinned in `[vars]` in `mise/conf.d/<app>.toml`. Cursor pairs
    `cursor_version` with `cursor_hash` (see `cursor/AGENTS.md`). Obsidian
    tracks the newest release with a desktop AppImage.
  - **GPU services** (`llama`, `whisper`): Pin the newest semver release tag
    (without `v`, never `bNNNN`) in `mise/conf.d/llama.toml` and
    `mise/conf.d/whisper.toml`. `mise run apply` rebuilds and restarts the
    service when the version or unit changes, then `clean` removes old source
    trees. Never run `clean` before `apply`.
  - **endpoint-verification**: `mise run endpoint-verification:discover` prints
    `endpoint_verification_version`, `endpoint_verification_deb`, and
    `endpoint_verification_sha256` for `mise/conf.d/endpoint-verification.toml`.
  - **Neovim plugins**: `mise run bump neovim` updates plugins via
    `odsod.pack.update()` in `neovim/lua/odsod/pack.lua` and writes
    `neovim/nvim-pack-lock.json`.
  - **`mise` itself**: Read release notes since current (`defuddle parse
    https://github.com/jdx/mise/releases/tag/v<version> --md`), adopt any
    features that simplify `mise/conf.d/` or `tasks/`, and upgrade via
    `mise upgrade aqua:jdx/mise`.

## Agents and Skills

- `mise run update-skills` updates vendored global skills in `agents/` and
  rewrites `agents/.skill-lock.json`.
- This repo is public. Keep employer names, private repo names, and account
  identifiers out of `agents/AGENTS.md` and repo configs.
