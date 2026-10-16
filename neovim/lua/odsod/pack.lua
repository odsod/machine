local M = {}

-- Record the revision of every managed plugin in nvim-pack-lock.json.
--
-- vim.pack.update() checks out the remote revision but only writes the
-- lockfile for plugins it moves away from the revision in the lockfile. A
-- checkout that is already at the remote revision leaves a stale lockfile
-- behind, so sync the lockfile from the actual git checkout.
function M.sync_lockfile()
  local path = vim.fs.joinpath(vim.fn.stdpath("config"), "nvim-pack-lock.json")
  if vim.fn.filereadable(path) == 0 then
    return
  end

  local lock = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  for _, plugin in ipairs(vim.pack.get(nil, { info = false })) do
    local entry = lock.plugins[plugin.spec.name]
    if entry then
      local proc = vim.system({ "git", "rev-parse", "HEAD" }, { cwd = plugin.path, text = true }):wait()
      local rev = vim.trim(proc.stdout or "")
      if proc.code == 0 and rev ~= "" then
        entry.rev = rev
      end
    end
  end

  local encoded = vim.json.encode(lock, { indent = "  ", sort_keys = true })
  -- writefile() turns an embedded newline into a NUL byte, so split first.
  vim.fn.writefile(vim.split(encoded, "\n"), path)
end

-- Update every plugin to the latest revision and record the result.
function M.update()
  vim.pack.update(nil, { force = true })
  M.sync_lockfile()
end

return M
