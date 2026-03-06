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
      local capabilities = vim.lsp.protocol.make_client_capabilities()

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

      -- Prefer buf.yaml first, while still supporting jj-only repositories
      vim.lsp.config("buf_ls", {
        cmd = { "buf", "lsp", "serve" },
        filetypes = { "proto" },
        root_markers = { "buf.yaml", ".jj", ".git" },
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
          },
        },
      })

      -- Enable all servers
      vim.lsp.enable({ "ty", "ruff", "oxlint", "vtsls", "bashls", "fish_lsp", "lua_ls", "gopls", "yamlls", "markdown_oxide", "buf_ls" })

      -- Vanilla LSP UX: keymaps, completion, and format-on-save.
      local lsp_attach_group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true })
      vim.api.nvim_create_autocmd("LspAttach", {
        group = lsp_attach_group,
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then
            return
          end

          vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf, desc = "Go to definition" })

          if client:supports_method("textDocument/formatting") and not vim.b[args.buf].lsp_format_on_save then
            vim.b[args.buf].lsp_format_on_save = true
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = args.buf,
              callback = function()
                vim.lsp.buf.format({ bufnr = args.buf })
              end,
            })
          end

          if client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
            vim.keymap.set("i", "<c-space>", vim.lsp.completion.get, { buffer = args.buf, desc = "Manual completion" })
          end

        end,
      })
    end,
  },
})

-- --- Diagnostics ---
vim.diagnostic.config({
  virtual_lines = { current_line = true },
  virtual_text = false,
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
opt.autoread = true

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
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  callback = function() vim.cmd("checktime") end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.go", "*.py", "*.ts", "*.tsx", "*.js", "*.jsx" },
  callback = function()
    local clients = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/codeAction" })
    for _, client in ipairs(clients) do
      local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
      params.context = { only = { "source.organizeImports" }, diagnostics = {} }
      local result = client:request_sync("textDocument/codeAction", params, 1000, 0)
      for _, action in ipairs((result and result.result) or {}) do
        if action.edit then
          vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
        elseif action.command then
          client:exec_command(action.command)
        end
      end
    end
  end,
})
