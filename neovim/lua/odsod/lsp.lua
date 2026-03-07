local M = {}
local save_actions = require("odsod.lsp.save_actions")

function M.setup()
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  -- Global defaults for all LSP servers.
  vim.lsp.config("*", {
    capabilities = capabilities,
    root_markers = { ".jj", ".git" },
  })

  -- Enable all servers
  vim.lsp.enable({ "ty", "ruff", "oxfmt", "oxlint", "vtsls", "bashls", "fish_lsp", "lua_ls", "gopls", "yamlls", "markdown_oxide", "buf_ls" })

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

      save_actions.setup(args.buf)
    end,
  })
end

return M
