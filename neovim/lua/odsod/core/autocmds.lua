local M = {}

function M.setup()
  vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
    callback = function() vim.cmd("checktime") end,
  })
end

return M
