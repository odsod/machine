vim.loader.enable()

-- Leader key
vim.g.mapleader = " "

require("odsod.plugins").setup()
require("odsod.lsp").setup()
require("odsod.ui.statusline").setup()
require("odsod.core.diagnostics").setup()
require("odsod.core.options").setup()
require("odsod.core.keymaps").setup()
require("odsod.core.autocmds").setup()
