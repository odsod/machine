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
- Make target: `~/.config/nvim`
- Behavior: remove existing target and symlink `neovim/` as a whole
- Rationale:
  - no per-file symlink maintenance
  - new modules are auto-mounted
  - repo layout and runtime layout stay identical

## Directory Layout
- `init.lua`
  - bootstraps lazy.nvim
  - loads `odsod.*` modules
- `lua/odsod/plugins.lua`
  - plugin specs and plugin config wiring
- `lua/odsod/lsp.lua`
  - LSP defaults, server enable list, LspAttach save actions
- `lua/odsod/core/options.lua`
  - editor options
- `lua/odsod/core/keymaps.lua`
  - global keymaps
- `lua/odsod/core/autocmds.lua`
  - non-LSP autocmds
- `lua/odsod/core/diagnostics.lua`
  - diagnostic rendering policy
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

## Commands
- Install/symlink/plugins:
```sh
make -C neovim
```
- Sync plugins only:
```sh
make -C neovim install-plugins
```
- Startup validation:
```sh
nvim --headless '+qa'
```

## Skills
- Neovim changes: use `neovim` skill
  - `.agents/skills/neovim/SKILL.md`
- CLAUDE/GEMINI memory maintenance: use `claude-md-improver` skill
  - `.agents/skills/claude-md-improver/SKILL.md`
