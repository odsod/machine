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
- **`tasks/`**: Cross-cutting scripts (`discover.sh`, `bump.sh`,
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
  `mise reshim`, and `mise run clean`. `clean` runs `mise prune`, which deletes
  every tool version no tracked config selects.
- **Host packages**: `[bootstrap.packages]` installs missing packages only. A
  `"latest"` entry accepts any installed version, so `mise run apply` never
  upgrades one. Packages from enabled repos, such as the COPR build of
  scrcpy, follow system updates (KDE Discover via PackageKit, or
  `sudo dnf upgrade`). Use `mise bootstrap packages upgrade` to upgrade them
  from mise instead.
- **Inspect state**: `mise bootstrap status --missing`, `mise bootstrap plan`,
  or `mise bootstrap --dry-run`.
- **Fresh machine**: `./bootstrap.sh` trusts the config and runs
  `mise bootstrap --yes`.
- **App-owned config**: Apps that write their own config get a
  `merge = "missing"` `[dotfiles]` entry instead of a symlink
  (`codex/config.toml`, `antigravity/settings.json`, `pi/settings.json`,
  `herdr/app/{settings,keys}.json`). The repo file seeds defaults: mise sets
  only keys the live file lacks, at any depth, and the app owns every key after
  that. A changed repo value does not reach a machine that already has the
  key; delete the key in the live file, then run `mise dot apply`. Copy
  settings changed in an app into the repo by hand (never workspace paths or
  auth state).
- **Links into tool installs**: `tools:link` (`tasks/link-tools.sh`) points
  `vi`, `vim`, `obsidian-app` and similar links at the versions this config
  selects, on every apply. Never link from a postinstall: it follows the last
  install, which can be an older pin from another workspace.
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
- **Lockfile format**: `mise.lock` is format 4, which records the npm repository
  each `npm:` package's provenance names. mise keeps an existing lockfile at its
  format, so run `mise lock --global --upgrade` after a mise upgrade, then
  `mise install` to write new pins. `--global` is required: the repo config is
  the global config.
- **Pin specifics**:
  - **gh extensions** (`github:github/gh-stack`): a mise tool pinned in
    `mise.lock`. `tools:link` links the install dir to
    `~/.local/share/gh/extensions/gh-stack` as a local extension.
    Never run `gh extension install github/gh-stack`: gh keeps its copy and the
    two writers fight.
  - **slackcli**: never run `slackcli update`, even when the vendored skill
    suggests it. It replaces the mise binary and leaves `mise.lock` stale.
  - **Desktop apps** (`slack`, `zoom`, `yaak`): Pinned in `[vars]` in
    `mise/conf.d/<app>.toml`, because mise cannot install an RPM. `obsidian` and
    `soap-ui` are `http:` tools in `mise.toml` that read their releases through
    `version_list_url`, so `mise outdated` and `mise upgrade --bump` cover them.
  - **Herdr app** (`http:herdr-app`, `http:herdr-core`): mise tools in
    `mise.toml`, pinned in `mise.lock` and bumped by `mise run bump`, with
    checksums from the upstream release manifests. herdr-core sees its mise
    install path and leaves updates to mise.
    `herdr:setup-core` links `hc` and `herdr-core` in `~/.local/bin` to the
    pinned core (the app looks there before the mise shims) and warns when a
    running core is stale. Run `hc server restart` by hand at a safe point;
    terminals survive it, attached streams reattach.
    The app still updates itself in place, so it can run ahead of `mise.lock`.
    Track these upstream issues and drop this caveat when one ships:
    - [herdrdev/herdr-app#459](https://github.com/herdrdev/herdr-app/pull/459)
      (fixes [#136](https://github.com/herdrdev/herdr-app/issues/136)): a
      mise-installed app skips its own updates.
    - [herdrdev/herdr-app#207](https://github.com/herdrdev/herdr-app/issues/207):
      a setting to turn app updates off.
    - [herdrdev/herdr-app#395](https://github.com/herdrdev/herdr-app/issues/395):
      GitHub releases, which would allow a `github:` backend instead of `http:`.
  - **Herdr app mods**: shipped mods and layouts are read-only and rewritten
    on every app start. To change one, add `herdr/app/patches/<mod>.patch`
    (a unified diff of its `main.js`, `a/` and `b/` prefixes).
    `herdr:patch-mods` rebuilds `odsod-<mod>` from the shipped mod plus the
    patch, and `layouts/odsod-main.json` from the shipped `main` with those
    mods swapped in. `herdr-patch-mods.path` reruns it whenever the app
    rewrites `installed.json`, so upstream changes arrive on their own. A
    patch that no longer applies keeps the last good build and sends a
    desktop notification: fix the patch against the new shipped file.
    Agent icons are hidden through `herdr/app/programs.json` (`"icon": ""`),
    not a patch.
  - **GPU services** (`llama`, `whisper`): Pin the newest semver release tag
    without `v`, never a bare `bNNNN` tag (`1.0.0-b12359-b1b770d`, not
    `b12359`), in `mise/conf.d/llama.toml` and `mise/conf.d/whisper.toml`.
    `mise run apply` rebuilds and restarts the service when the version or
    unit changes, then `clean` removes old source trees. Never run `clean`
    before `apply`.
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
