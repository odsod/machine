local M = {}

function M.setup()
  local opt = vim.opt
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
