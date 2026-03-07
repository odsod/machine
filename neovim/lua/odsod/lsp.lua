local M = {}

function M.setup()
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  -- Global defaults for all LSP servers.
  vim.lsp.config("*", {
    capabilities = capabilities,
    root_markers = { ".jj", ".git" },
  })

  -- Enable all servers
  vim.lsp.enable({ "ty", "ruff", "oxlint", "vtsls", "bashls", "fish_lsp", "lua_ls", "gopls", "yamlls", "markdown_oxide", "buf_ls" })

  local import_action_by_filetype = {
    go = "source.organizeImports",
    python = "source.organizeImports.ruff",
    javascript = "source.organizeImports",
    javascriptreact = "source.organizeImports",
    typescript = "source.organizeImports",
    typescriptreact = "source.organizeImports",
  }

  local formatter_owner_by_filetype = {
    go = "gopls",
    python = "ruff",
    javascript = "oxfmt",
    javascriptreact = "oxfmt",
    typescript = "oxfmt",
    typescriptreact = "oxfmt",
  }

  local lsp_attach_group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = lsp_attach_group,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then
        return
      end

      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf, desc = "Go to definition" })

      if client:supports_method("textDocument/completion") then
        vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
        vim.keymap.set("i", "<c-space>", vim.lsp.completion.get, { buffer = args.buf, desc = "Manual completion" })
      end

      if client:supports_method("textDocument/inlayHint") then
        vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
      end

      if not vim.b[args.buf].lsp_save_actions then
        vim.b[args.buf].lsp_save_actions = true
        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer = args.buf,
          callback = function()
            local filetype = vim.bo[args.buf].filetype
            local import_action = import_action_by_filetype[filetype]
            local formatter_owner = formatter_owner_by_filetype[filetype]

            if import_action then
              vim.lsp.buf.code_action({
                bufnr = args.buf,
                context = { only = { import_action } },
                apply = true,
              })
            end

            if formatter_owner then
              vim.lsp.buf.format({
                bufnr = args.buf,
                async = false,
                filter = function(format_client)
                  return format_client.name == formatter_owner
                end,
              })
            end
          end,
        })
      end
    end,
  })
end

return M
