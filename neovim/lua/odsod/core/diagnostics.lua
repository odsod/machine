local M = {}

function M.setup()
  vim.diagnostic.config({
    virtual_lines = { current_line = true },
    virtual_text = false,
  })
end

return M
