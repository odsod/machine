# Neovim

## Conventions

- Target native Neovim 0.11+ built-ins before adding plugins.
- Keep `init.lua` thin; place modules under `lua/odsod/` (`odsod.core.*`,
  `odsod.ui.*`, `odsod.lsp.*`) and per-server overrides in `lsp/<server>.lua`.
- Configure global LSP defaults with `vim.lsp.config("*", ...)` and activate
  servers with `vim.lsp.enable({ ... })`. Include `.jj` and `.git` in root
  markers.
- Keep save-time formatting and import actions deterministic by filetype/client
  in `lua/odsod/lsp/save_actions.lua`.

## Plugins and Verification

- Update plugins and sync `nvim-pack-lock.json`:
  `nvim --headless '+lua require("odsod.pack").update()' +qa`
  (or `mise run bump neovim`).
- Always use `odsod.pack.update()` instead of bare `vim.pack.update()`:
  `vim.pack.update()` skips writing `nvim-pack-lock.json` when a checkout is
  already at the remote revision.
- Validate startup: `nvim --headless '+qa'`
