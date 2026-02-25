-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Leader key
vim.g.mapleader = " "

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
    lazy = false, -- Load immediately to ensure environment is ready for LSP
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  -- UI & Tools
  { "nvim-lualine/lualine.nvim", opts = { options = { theme = "auto", icons_enabled = false } } },
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
    "nvim-telescope/telescope.nvim",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          file_ignore_patterns = { "%.git/", "%.jj/", "node_modules/" },
        },
        pickers = {
          find_files = { no_ignore = true },
          live_grep = { additional_args = { "--no-ignore" } },
        },
      })
      require("telescope").load_extension("fzf")
    end,
  },
  { "tpope/vim-fugitive" },
  { "numToStr/Comment.nvim", opts = {} },
  { "lewis6991/gitsigns.nvim", opts = {} },

  -- Treesitter: Better syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "go", "python", "lua", "bash", "json", "yaml", "markdown" },
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
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      require("mason").setup()
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Setup 'ty' (Astral Python Type Checker)
      if not require("lspconfig.configs").ty then
        require("lspconfig.configs").ty = {
          default_config = {
            cmd = { "ty", "server" },
            filetypes = { "python" },
            root_dir = lspconfig.util.root_pattern("pyproject.toml", ".git"),
          },
        }
      end
      lspconfig.ty.setup({ capabilities = capabilities })

      -- Setup other servers via Mason
      require("mason-lspconfig").setup({
        ensure_installed = { "gopls", "ts_ls", "bashls", "lua_ls" },
        handlers = {
          function(server)
            lspconfig[server].setup({ capabilities = capabilities })
          end,
        },
      })

      -- Autocompletion
      local cmp = require("cmp")
      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
        }),
        sources = cmp.config.sources({
          { name = "lazydev", group_index = 0 },
          { name = "nvim_lsp" },
        }, { { name = "buffer" } }),
      })
    end,
  },

  -- Formatting on Save
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        oxfmt = {
          command = "oxfmt",
          args = { "$FILENAME" },
          stdin = false,
        },
      },
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "isort", "black" },
        javascript = { "oxfmt" },
        javascriptreact = { "oxfmt" },
        typescript = { "oxfmt" },
        typescriptreact = { "oxfmt" },
        mjs = { "oxfmt" },
        cjs = { "oxfmt" },
        mts = { "oxfmt" },
        cts = { "oxfmt" },
        go = { "goimports", "gofmt" },
      },
      format_on_save = { timeout_ms = 500, lsp_fallback = true },
    },
  },
})

-- --- General Settings ---
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

-- --- Keymaps ---
local map = vim.keymap.set
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")
map("n", "<C-n>", "<cmd>Telescope find_files<cr>")
map("n", "<C-g>", "<cmd>Telescope live_grep<cr>")

map("n", "<leader>t", "<cmd>NvimTreeToggle<cr>")
map("n", "<leader>w", ":w<CR>")
map("n", "<leader>q", ":q<CR>")
map("n", "<leader>a", ":wqa<CR>")
map("n", "<leader>n", ":nohlsearch<CR>")
map("n", "<leader>z", ":qa!<CR>")
map("n", "<leader>i", "gg=G<C-O><C-O>")
