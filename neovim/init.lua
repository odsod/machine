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
  { "numToStr/Comment.nvim", opts = {} },

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
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Apply capabilities globally to all LSP servers
      vim.lsp.config("*", {
        capabilities = capabilities,
        root_markers = { ".jj", ".git" },
      })

      -- Adjust root markers for 'ty'
      vim.lsp.config("ty", {
        root_markers = { "pyproject.toml", ".jj", ".git" },
      })

      -- Adjust root markers for oxlint to trigger without an .oxlintrc.json
      vim.lsp.config("oxlint", {
        root_markers = { "package.json", ".jj", ".git" },
      })

      -- Allow yaml-language-server to detect project roots in jj repos
      vim.lsp.config("yamlls", {
        root_markers = { ".jj", ".git" },
      })

      -- Prefer jj repos for fish-lsp root detection
      vim.lsp.config("fish_lsp", {
        root_markers = { "config.fish", ".jj", ".git" },
      })

      -- markdown-oxide recommends enabling dynamic watched-files registration
      vim.lsp.config("markdown_oxide", {
        capabilities = vim.tbl_deep_extend("force", capabilities, {
          workspace = {
            didChangeWatchedFiles = {
              dynamicRegistration = true,
            },
          },
        }),
      })

      -- Setup gopls settings
      vim.lsp.config("gopls", {
        settings = {
          gopls = {
            gofumpt = true,
            staticcheck = true,
            usePlaceholders = true,
            analyses = {
              nilness = true,
              unusedparams = true,
              unusedwrite = true,
              useany = true,
            },
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
      })

      -- Enable all servers
      vim.lsp.enable({ "ty", "ruff", "oxlint", "vtsls", "bashls", "fish_lsp", "lua_ls", "gopls", "yamlls", "markdown_oxide" })

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
        sh = { "shfmt" },
        bash = { "shfmt" },
        javascript = { "oxfmt" },
        javascriptreact = { "oxfmt" },
        typescript = { "oxfmt" },
        typescriptreact = { "oxfmt" },
        mjs = { "oxfmt" },
        cjs = { "oxfmt" },
        mts = { "oxfmt" },
        cts = { "oxfmt" },
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

-- --- Autocommands ---
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.go", "*.py", "*.ts", "*.tsx", "*.js", "*.jsx" },
  callback = function()
    local params = vim.lsp.util.make_range_params()
    params.context = {only = {"source.organizeImports"}}
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
    for cid, res in pairs(result or {}) do
      for _, r in pairs(res.result or {}) do
        if r.edit then
          local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
          vim.lsp.util.apply_workspace_edit(r.edit, enc)
        end
      end
    end
  end
})
