# Agent Instructions

## Structure

- Public repo: keep employer names, private repo names, and account identifiers
  out of `agents/AGENTS.md` and all configs.
- Keep `[tools]` in `mise.toml` (not `mise/conf.d/`) so `mise.lock` stays at
  the repo root.
- Put topic config (`[vars]`, `[dotfiles]`, `[bootstrap.*]`,
  `[tasks."<topic>:*"]`) in `mise/conf.d/<topic>.toml` (loaded alphabetically
  before `mise.toml`) and topic files in `<topic>/`. Never add
  `<topic>/mise.toml`.
- Keep dependencies one-way (`mise/conf.d/<topic>.toml` -> `<topic>/`): pass
  `[vars]` via task `env = { ... }`, and read only env vars in `<topic>/`
  scripts. Only `tasks/bump.sh` reads or writes `mise/conf.d/*.toml`.
- `~/.config/mise/conf.d` symlinks to `mise/conf.d/`. `mise` resolves relative
  paths against `config_path.parent()` without canonicalizing symlinks, so
  `../../<topic>/` works only inside `mise/conf.d/*.toml`.
- `env.sh` is sourced by `mise`, KDE (`~/.config/plasma-workspace/env/`), and
  login shells (`~/.profile`): keep it POSIX `sh`.
- Store runtime builds, source trees, archives, and model weights in
  `~/.local/share/odsod/machine/data/`, never in the repo.
- `[bootstrap.services]` manages system units only; set up `--user` units with
  `systemctl --user` in `[bootstrap.hooks.post-packages]` or setup tasks.
- Set `replace = true` on `[bootstrap.files]` entries that replace symlinks or
  package-owned files.

## Provisioning

- Full convergence: `mise run apply` runs `mise bootstrap --yes`,
  `mise reshim`, and `mise run clean` (`mise prune` removes unselected tool
  versions). Use `./bootstrap.sh` on a fresh machine.
- Check edits with `mise run check` (`mise run fmt` formats). Inspect state:
  `mise bootstrap status --missing`, `mise bootstrap plan`, or
  `mise bootstrap --dry-run`.
- Host packages: `[bootstrap.packages]` installs missing packages only
  (`"latest"` accepts any installed version, so `apply` never upgrades them).
  Upgrade via KDE Discover, `sudo dnf upgrade`, or
  `mise bootstrap packages upgrade`.
- App-owned config: use `merge = "missing"` in `[dotfiles]`, not a symlink.
  The repo seeds missing keys at any depth; the app owns them after. To push a
  changed default, delete the live key and run `mise dot apply`. Copy wanted
  app edits into the repo by hand (never workspace paths or auth state).
- Tool links: `tools:link` (`tasks/link-tools.sh`) links binaries and
  extensions to selected versions on every apply. Never link from a
  `postinstall` hook (it follows the last install, which may be an older pin
  from another workspace).
- Overwritten dotfile symlinks: copy wanted changes into the repo before
  running `mise bootstrap --force-dotfiles`.

## Version Bumping

- `mise run bump [<name>] [--dry-run]`: runs `mise upgrade --bump` (using
  `gh auth token` as `GITHUB_TOKEN`; aborts on open PRs on `origin`) and
  updates pins in `mise/conf.d/*.toml`, `mise.lock`, and
  `neovim/nvim-pack-lock.json`. Does not apply changes.
- `mise run update-skills`: updates vendored global skills in `agents/` and
  rewrites `agents/.skill-lock.json`.
- After bumping: run `mise run apply`; verify `mise bootstrap --dry-run` has
  no pending work and GPU `/health` answers on `127.0.0.1:8178` and
  `127.0.0.1:8179`.
- `mise` upgrade: read release notes
  (`defuddle parse https://github.com/jdx/mise/releases/tag/v<version> --md`),
  adopt simplifying features, run `mise upgrade aqua:jdx/mise`, then
  `mise lock --global --upgrade` and `mise install` (`--global` required: this
  repo is the global config; keeps lockfile format 4).
- `gh-stack`: pinned in `mise.lock` and symlinked by `tools:link` to
  `~/.local/share/gh/extensions/gh-stack`. Never run
  `gh extension install github/gh-stack` (the two writers fight).
- `slackcli`: never run `slackcli update`, even when the skill suggests it
  (replaces the mise binary and desyncs `mise.lock`).
- Desktop apps: pin RPM-only apps in `[vars]` in `mise/conf.d/<app>.toml`; use
  `http:` tools in `mise.toml` for direct downloads.
- GPU inference servers (whisper-server, llama-server): the `odsod/daemon`
  repo owns them (ADR-0023, `odsodctl inference setup`). This repo only
  installs their ROCm build packages on the desktop (`rocm:setup`).

## Herdr

- Herdr core (`http:herdr-core`): `herdr:setup-core` links `hc` and
  `herdr-core` in `~/.local/bin` to the pinned build and warns on a stale core.
  Restart by hand at a safe point with `hc server restart` (terminals survive;
  streams reattach).
- Herdr app (`http:herdr-app`): `mise` owns updates. `env.sh` points
  `HERDR_RELEASES_URL` at a dead address, so the app finds no update (it would
  stage one beside the mise install). Bump with
  `mise upgrade http:herdr-app`, then restart the app. Swap the override for a
  setting once upstream ships
  [herdrdev/herdr-app#459](https://github.com/herdrdev/herdr-app/pull/459) or
  [#207](https://github.com/herdrdev/herdr-app/issues/207).
- Herdr mods: shipped mods and layouts overwrite on app start. Patch via
  `herdr/app/patches/<mod>.patch` (unified diff of `main.js`, `a/` and `b/`
  prefixes) and `herdr/app/patches/layout.jq`. `herdr:patch-mods` (run by
  `herdr-patch-mods.path`) rebuilds `odsod-<mod>` and
  `layouts/odsod-main.json`; a failed patch keeps the last good build and sends
  a desktop notification.

## Machine Agent

- Each machine runs a `machine` agent (terminal, tab, and space `machine` in
  this original checkout). Address it via `hc send`/`hc get` as `machine`
  locally or `<host>/machine` remotely. Start or repair it any time with
  `herdr-machine-agent`. No leader exists: the Herdr cores and this repo hold
  all state.
- Vault agents (`brain`, `house`, `company`) follow the same scheme in their
  original checkouts: `herdr-machine-agent --agent <name>` starts or repairs
  one (clones a missing vault). The prefix toggles them (`m`, `b`, `o`, `c`),
  and the sidebar lists them under each machine's row.
- Work in this original checkout: edit here, ship PRs from a change on `main`,
  and run `mise run apply` from here (other agents may use workspaces for
  parallel work).
- Manage this machine. Reach remote machines (`hc exec --on <host>`,
  `hc file ... --on <host>`) when asked, or to sync them to `main@origin` after
  your merge (`apply` is idempotent; offline machines catch up later).
- Treat this repo as the only memory; commit lasting rules here. Read live
  state (`herdr-app ls`, `hc ls`, `hc machine ls`, `jj workspace list`) instead
  of assuming it.
- Delegate long reads, builds, and edits to child agents (`hc --skill`) and ask
  for short reports.
