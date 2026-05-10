local M = {}

function M.setup()
  -- PackChanged hook must be registered BEFORE vim.pack.add()
  vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
      if ev.data.spec.name == "nvim-treesitter" then
        pcall(vim.cmd, "TSUpdate")
      end
    end,
  })

  -- Install all plugins (parallel download on first run)
  vim.pack.add({
    "https://github.com/shaunsingh/nord.nvim",
    "https://github.com/nvim-tree/nvim-tree.lua",
    "https://github.com/ibhagwan/fzf-lua",
    "https://github.com/numToStr/Comment.nvim",
    "https://github.com/nvim-treesitter/nvim-treesitter",
  })

  -- Theme: Nord
  vim.g.nord_italic = false
  vim.g.nord_bold = false
  require("nord").set()
  vim.api.nvim_set_hl(0, "LspInlayHint", { link = "Comment" })

  -- File tree
  require("nvim-tree").setup({
    filters = { git_ignored = false },
    filesystem_watchers = { ignore_dirs = { "node_modules", ".git", ".jj" } },
    view = { width = 30 },
    renderer = {
      group_empty = true,
      icons = { show = { file = false, folder = false, folder_arrow = true, git = false } },
    },
  })

  -- Fuzzy finder
  require("odsod.ui.fzf").setup()

  -- Comments
  require("Comment").setup({})

  -- Treesitter
  require("nvim-treesitter").setup({
    ensure_installed = { "go", "python", "lua", "bash", "json", "yaml", "markdown", "proto" },
    highlight = { enable = true },
    indent = { enable = true },
  })
end

return M
