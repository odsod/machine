local M = {}

local mode_map = {
  n = "N",
  i = "I",
  v = "V",
  V = "VL",
  ["\22"] = "VB",
  c = "C",
  R = "R",
  t = "T",
}

local function current_mode()
  return mode_map[vim.api.nvim_get_mode().mode] or "?"
end

local function current_file()
  local file = vim.fn.expand("%:~:.")
  if file == "" then
    file = "[No Name]"
  end
  if vim.bo.modified then
    file = file .. " [+]"
  end
  if vim.bo.readonly then
    file = file .. " [RO]"
  end
  return file
end

local function diagnostics_segment()
  local counts = vim.diagnostic.count(0)
  local segment = {}
  if counts[vim.diagnostic.severity.ERROR] then
    table.insert(segment, "E:" .. counts[vim.diagnostic.severity.ERROR])
  end
  if counts[vim.diagnostic.severity.WARN] then
    table.insert(segment, "W:" .. counts[vim.diagnostic.severity.WARN])
  end
  if counts[vim.diagnostic.severity.INFO] then
    table.insert(segment, "I:" .. counts[vim.diagnostic.severity.INFO])
  end
  if counts[vim.diagnostic.severity.HINT] then
    table.insert(segment, "H:" .. counts[vim.diagnostic.severity.HINT])
  end
  if #segment == 0 then
    return ""
  end
  return " " .. table.concat(segment, " ")
end

local function lsp_segment()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    return ""
  end
  local names = {}
  for _, client in ipairs(clients) do
    names[#names + 1] = client.name
  end
  return " lsp:" .. table.concat(names, ",")
end

local function statusline()
  return table.concat({
    " ",
    current_mode(),
    " ",
    current_file(),
    "%=",
    diagnostics_segment(),
    lsp_segment(),
    " %l:%c ",
  })
end

function M.setup()
  _G.Statusline = statusline
  vim.o.laststatus = 3
  vim.o.statusline = "%{%v:lua.Statusline()%}"
end

return M
