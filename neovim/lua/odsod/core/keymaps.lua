local M = {}

function M.setup()
  local map = vim.keymap.set

  map("n", "<C-h>", "<C-w>h")
  map("n", "<C-j>", "<C-w>j")
  map("n", "<C-k>", "<C-w>k")
  map("n", "<C-l>", "<C-w>l")
  map("n", "<C-n>", "<cmd>FzfLua files<cr>")
  map("n", "<C-g>", "<cmd>FzfLua live_grep<cr>")

  map("n", "<leader>t", "<cmd>NvimTreeToggle<cr>")
  map("n", "<leader>w", ":w<CR>")
  map("n", "<leader>q", ":q<CR>")
  map("n", "<leader>a", ":wqa<CR>")
  map("n", "<leader>n", ":nohlsearch<CR>")
  map("n", "<leader>z", ":qa!<CR>")
  map("n", "<leader>i", "gg=G<C-O><C-O>")
end

return M
