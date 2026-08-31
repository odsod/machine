local M = {}

function M.setup()
  local opt = vim.opt
  -- One clipboard path for copy: nvim emits OSC 52, and both ghostty and
  -- herdr deliver it to the clipboard of the attached client, locally and
  -- over remote attach. Paste reads the system clipboard when this session
  -- has one. Herdr does not relay OSC 52 read queries, so in a remote pane
  -- paste-by-register cannot work; use the terminal paste (ctrl+shift+v)
  -- there.
  local osc52 = require("vim.ui.clipboard.osc52")

  local function paste(want_primary)
    if vim.env.WAYLAND_DISPLAY ~= nil and vim.env.WAYLAND_DISPLAY ~= "" then
      if vim.fn.executable("wl-paste") == 0 then
        return {}
      end
      local args = { "wl-paste", "--no-newline" }
      if want_primary then
        table.insert(args, "--primary")
      end
      return vim.fn.systemlist(args, { "" }, 1)
    elseif vim.env.DISPLAY ~= nil and vim.env.DISPLAY ~= "" then
      if vim.fn.executable("xclip") == 0 then
        return {}
      end
      local args = { "xclip", "-o", "-selection", want_primary and "primary" or "clipboard" }
      return vim.fn.systemlist(args, { "" }, 1)
    end
    vim.notify(
      "No clipboard access in this pane; paste with ctrl+shift+v (terminal paste)",
      vim.log.levels.WARN
    )
    return {}
  end

  vim.g.clipboard = {
    name = "OSC52CopySystemPaste",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = function()
        return paste(false)
      end,
      ["*"] = function()
        return paste(true)
      end,
    },
  }
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
