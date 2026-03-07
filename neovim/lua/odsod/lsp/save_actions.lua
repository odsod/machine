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
  markdown = "oxfmt",
  json = "oxfmt",
  jsonc = "oxfmt",
  yaml = "oxfmt",
  toml = "oxfmt",
  css = "oxfmt",
  scss = "oxfmt",
  less = "oxfmt",
  html = "oxfmt",
  vue = "oxfmt",
  graphql = "oxfmt",
  handlebars = "oxfmt",
}

local function apply_first_code_action(bufnr, action_kind)
  local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/codeAction" })
  if #clients == 0 then
    return
  end

  local params = vim.lsp.util.make_range_params(0)
  params.context = {
    only = { action_kind },
    diagnostics = vim.diagnostic.get(bufnr),
    triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked,
  }

  local responses = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 800)
  if not responses then
    return
  end

  for _, client in ipairs(clients) do
    local response = responses[client.id]
    for _, action in ipairs((response and response.result) or {}) do
      local resolved_action = action
      if not (action.edit and action.command) and client:supports_method("codeAction/resolve") then
        local resolved = client:request_sync("codeAction/resolve", action, 800, bufnr)
        if resolved and resolved.result then
          resolved_action = resolved.result
        end
      end

      if resolved_action.edit then
        vim.lsp.util.apply_workspace_edit(resolved_action.edit, client.offset_encoding)
      end

      local command = resolved_action.command
      if command then
        local command_to_run = type(command) == "table" and command or resolved_action
        client:exec_cmd(command_to_run, { bufnr = bufnr })
      end

      return
    end
  end
end

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
        apply_first_code_action(bufnr, import_action)
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
