local M = {}

-- System clipboard access goes through the + and * registers only; plain
-- yanks stay in nvim. Copy: nvim emits OSC 52, and the Herdr app writes it
-- to the local clipboard, also from a terminal on another machine. Paste
-- reads the system clipboard when this session has one. The app never
-- answers OSC 52 read queries, so in a remote terminal paste-by-register
-- cannot work; use the terminal paste (ctrl+shift+v) there.
function M.setup()
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
    vim.notify("No clipboard access in this pane; paste with ctrl+shift+v (terminal paste)", vim.log.levels.WARN)
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
end

return M
