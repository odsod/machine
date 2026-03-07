local M = {}

local function set_highlights()
  -- Keep picker windows aligned with Nord floating UI defaults.
  vim.api.nvim_set_hl(0, "FzfLuaNormal", { link = "Normal" })
  vim.api.nvim_set_hl(0, "FzfLuaBorder", { link = "FloatBorder" })
  vim.api.nvim_set_hl(0, "FzfLuaTitle", { link = "Title" })
  vim.api.nvim_set_hl(0, "FzfLuaCursorLine", { link = "CursorLine" })
  vim.api.nvim_set_hl(0, "FzfLuaCursorLineNr", { link = "CursorLineNr" })
  vim.api.nvim_set_hl(0, "FzfLuaSearch", { link = "IncSearch" })
  vim.api.nvim_set_hl(0, "FzfLuaLivePrompt", { link = "Normal" })
end

function M.setup()
  local fzf = require("fzf-lua")

  set_highlights()

  fzf.setup({
    hls = {
      normal = "Normal",
      border = "FloatBorder",
      title = "Title",
      cursorline = "CursorLine",
      cursorlinenr = "CursorLineNr",
      search = "IncSearch",
      live_prompt = "Normal",
      header_bind = "DiagnosticHint",
      header_text = "DiagnosticHint",
      fzf = {
        normal = "Normal",
        cursorline = "CursorLine",
        match = "IncSearch",
        border = "FloatBorder",
        scrollbar = "FloatBorder",
        separator = "FloatBorder",
        gutter = "Normal",
        header = "Comment",
        info = "Comment",
        pointer = "Type",
        marker = "Type",
        spinner = "Type",
        prompt = "Normal",
        query = "Normal",
      },
    },
    fzf_colors = {
      true,
      ["fg"] = { "fg", "Normal" },
      ["bg"] = { "bg", "Normal" },
      ["hl"] = { "fg", "IncSearch" },
      ["fg+"] = { "fg", { "CursorLine", "Normal" } },
      ["bg+"] = { "bg", "CursorLine" },
      ["hl+"] = { "fg", "IncSearch" },
      ["info"] = { "fg", "Comment" },
      ["prompt"] = { "fg", "Normal", "regular" },
      ["pointer"] = { "fg", "Type" },
      ["marker"] = { "fg", "Type" },
      ["spinner"] = { "fg", "Type" },
      ["header"] = { "fg", "Comment" },
      ["query"] = { "fg", "Normal", "regular" },
      ["gutter"] = { "bg", "Normal" },
      ["border"] = { "fg", "FloatBorder" },
      ["separator"] = { "fg", "FloatBorder" },
      ["scrollbar"] = { "fg", "FloatBorder" },
    },
    winopts = {
      backdrop = false,
      winblend = 0,
      border = "rounded",
      preview = {
        border = "rounded",
        winopts = { winblend = 0 },
      },
      treesitter = { enabled = true, fzf_colors = false },
    },
    files = {
      no_ignore = true,
    },
    grep = {
      rg_opts = "--column --line-number --no-heading --color=never --smart-case --max-columns=4096 --hidden --no-ignore --glob '!.git' --glob '!.jj' --glob '!node_modules'",
    },
  })
end

return M
