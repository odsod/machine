# Neovim Agent Guide

## Scope

- Path: `neovim/`
- Runtime target: `~/.config/nvim`
- Source of truth: this directory

## Strategy

- Native Neovim 0.11+ first
- Minimal plugin surface
- Split by concern, not by tool novelty
- Prefer built-ins over plugins when behavior is equivalent

## Full Mount Symlink

- Dotfile: `~/.config/nvim` → `neovim/` (`[dotfiles]` in `mise/conf.d/neovim.toml`)
- Behavior: remove existing target and symlink `neovim/` as a whole
- Rationale:
  - no per-file symlink maintenance
  - new modules are auto-mounted
  - repo layout and runtime layout stay identical

## Directory Layout

- `init.lua`
  - bootstrap + top-level module loading
- `lua/odsod/plugins.lua`
  - `vim.pack.add()` declarations + plugin configuration
- `lua/odsod/pack.lua`
  - plugin update + lockfile sync helper
- `lua/odsod/lsp.lua`
  - LSP defaults + server enable list + LspAttach hooks
- `lua/odsod/lsp/save_actions.lua`
  - format/import actions on save, filtered by filetype/client
- `lua/odsod/core/options.lua`
  - editor options
- `lua/odsod/core/keymaps.lua`
  - global keymaps
- `lua/odsod/core/autocmds.lua`
  - non-LSP autocmds
- `lua/odsod/core/diagnostics.lua`
  - diagnostic rendering policy
- `lua/odsod/ui/fzf.lua`
  - `fzf-lua` setup + color/highlight contract
- `lua/odsod/ui/statusline.lua`
  - native statusline implementation
- `lsp/*.lua`
  - per-server configs, decoupled by language/server

## Module Naming

- Namespace: `odsod`
- Require pattern:
  - `require("odsod.core.options")`
  - `require("odsod.ui.statusline")`
- Constraint: avoid top-level generic modules like `config` or `plugins`

## LSP Rules

- Global defaults via `vim.lsp.config("*", ...)`
- Server activation via `vim.lsp.enable({ ... })`
- Per-server overrides in `lsp/<server>.lua`
- Root markers must include:
  - `.jj`
  - `.git`

## Editing Rules

- Keep `init.lua` thin
- Add new logic in `lua/odsod/*`
- Add language-specific behavior in `lsp/*`
- Keep save-time actions deterministic by filetype/client filter
- Keep picker theme config centralized in `lua/odsod/ui/fzf.lua`

## Commands

- Config is a `[dotfiles]` symlink. Binary and plugin sync run from the
  neovim `postinstall` hook in root `mise.toml`.
- Sync/update plugins:

```sh
nvim --headless '+lua require("odsod.pack").update()' +qa
```

- `odsod.pack.update()` updates every plugin to its latest revision and then
  syncs `nvim-pack-lock.json` from the actual checkouts. Plain
  `vim.pack.update()` skips the lockfile write when a checkout is already at
  the remote revision, which leaves a stale lockfile.

- Startup validation:

```sh
nvim --headless '+qa'
```
