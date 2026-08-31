local M = {}

function M.setup()
  local opt = vim.opt
  -- One clipboard path everywhere: ghostty and herdr both honor OSC 52,
  -- locally and over remote attach. Also syncs plain y.
  vim.g.clipboard = "osc52"
  opt.clipboard = "unnamedplus"
  opt.cursorline = true
  opt.expandtab = true
  opt.hidden = true
  opt.ignorecase = true
  opt.number = true
  opt.shiftwidth = 2
  opt.smartcase = true
  opt.tabstop = 2
  opt.title = true
  opt.wildmode = "list:longest,full"
  opt.shortmess = "atI"
  opt.mouse = ""
  opt.autoread = true
end

return M
