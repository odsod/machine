local M = {}

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

function M.setup(bufnr)
  if vim.b[bufnr].lsp_save_actions then
    return
  end
  vim.b[bufnr].lsp_save_actions = true

  vim.api.nvim_create_autocmd("BufWritePre", {
    buffer = bufnr,
    callback = function()
      local filetype = vim.bo[bufnr].filetype
      local import_action = import_action_by_filetype[filetype]
      local formatter_owner = formatter_owner_by_filetype[filetype]

      if import_action then
        vim.lsp.buf.code_action({
          bufnr = bufnr,
          context = { only = { import_action } },
          apply = true,
        })
      end

      if formatter_owner then
        vim.lsp.buf.format({
          bufnr = bufnr,
          async = false,
          filter = function(format_client)
            return format_client.name == formatter_owner
          end,
        })
      end
    end,
  })
end

return M
