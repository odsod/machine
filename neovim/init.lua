-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Leader key
vim.g.mapleader = " "

require("odsod.plugins").setup()
require("odsod.ui.statusline").setup()
require("odsod.core.diagnostics").setup()
require("odsod.core.options").setup()
require("odsod.core.keymaps").setup()
require("odsod.core.autocmds").setup()
