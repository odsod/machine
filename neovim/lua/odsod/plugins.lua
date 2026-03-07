local M = {}

function M.setup()
  require("lazy").setup({
    -- Theme: Nord
    {
      "shaunsingh/nord.nvim",
      lazy = false,
      priority = 1000,
      config = function()
        vim.g.nord_italic = false
        vim.g.nord_bold = false
        require("nord").set()
      end,
    },

    -- Neovim Development
    {
      "folke/lazydev.nvim",
      lazy = false,
      opts = {
        library = {
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
      },
    },

    -- UI & Tools
    {
      "nvim-tree/nvim-tree.lua",
      opts = {
        filters = {
          git_ignored = false,
        },
        filesystem_watchers = {
          ignore_dirs = {
            "node_modules",
            ".git",
            ".jj",
          },
        },
        view = { width = 30 },
        renderer = {
          group_empty = true,
          icons = { show = { file = false, folder = false, folder_arrow = true, git = false } },
        },
      },
    },
    {
      "ibhagwan/fzf-lua",
      config = function()
        require("odsod.ui.fzf").setup()
      end,
    },
    { "numToStr/Comment.nvim", opts = {} },

    -- Treesitter: Better syntax highlighting
    {
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      opts = {
        ensure_installed = { "go", "python", "lua", "bash", "json", "yaml", "markdown", "proto" },
        highlight = { enable = true },
        indent = { enable = true },
      },
      config = function(_, opts)
        require("nvim-treesitter").setup(opts)
      end,
    },

    -- LSP: Language Support
    {
      "neovim/nvim-lspconfig",
      config = function()
        require("odsod.lsp").setup()
      end,
    },
  })
end

return M
