local M = {}

local function jj_origin_trunk_rev()
	local origin_head = vim.trim(vim.fn.system({ "git", "symbolic-ref", "--quiet", "refs/remotes/origin/HEAD" }))
	if vim.v.shell_error == 0 then
		local branch = origin_head:match("^refs/remotes/origin/(.+)$")
		if branch and branch ~= "" then
			return branch .. "@origin"
		end
	end

	return "trunk()"
end

local function set_highlights()
	-- Keep picker windows aligned with Nord floating UI defaults.
	vim.api.nvim_set_hl(0, "FzfLuaNormal", { link = "Normal" })
	vim.api.nvim_set_hl(0, "FzfLuaBorder", { link = "FloatBorder" })
	vim.api.nvim_set_hl(0, "FzfLuaTitle", { link = "Title" })
	vim.api.nvim_set_hl(0, "FzfLuaCursorLine", { link = "CursorLine" })
	vim.api.nvim_set_hl(0, "FzfLuaCursorLineNr", { link = "CursorLineNr" })
	vim.api.nvim_set_hl(0, "FzfLuaSearch", { link = "IncSearch" })
	vim.api.nvim_set_hl(0, "FzfLuaLivePrompt", { link = "Normal" })
end

function M.setup()
	local fzf = require("fzf-lua")

	set_highlights()

	fzf.setup({
		hls = {
			normal = "Normal",
			border = "FloatBorder",
			title = "Title",
			cursorline = "CursorLine",
			cursorlinenr = "CursorLineNr",
			search = "IncSearch",
			live_prompt = "Normal",
			header_bind = "DiagnosticHint",
			header_text = "DiagnosticHint",
			fzf = {
				normal = "Normal",
				cursorline = "CursorLine",
				match = "IncSearch",
				border = "FloatBorder",
				scrollbar = "FloatBorder",
				separator = "FloatBorder",
				gutter = "Normal",
				header = "Comment",
				info = "Comment",
				pointer = "Type",
				marker = "Type",
				spinner = "Type",
				prompt = "Normal",
				query = "Normal",
			},
		},
		fzf_colors = {
			true,
			["fg"] = { "fg", "Normal" },
			["bg"] = { "bg", "Normal" },
			["hl"] = { "fg", "IncSearch" },
			["fg+"] = { "fg", { "CursorLine", "Normal" } },
			["bg+"] = { "bg", "CursorLine" },
			["hl+"] = { "fg", "IncSearch" },
			["info"] = { "fg", "Comment" },
			["prompt"] = { "fg", "Normal", "regular" },
			["pointer"] = { "fg", "Type" },
			["marker"] = { "fg", "Type" },
			["spinner"] = { "fg", "Type" },
			["header"] = { "fg", "Comment" },
			["query"] = { "fg", "Normal", "regular" },
			["gutter"] = { "bg", "Normal" },
			["border"] = { "fg", "FloatBorder" },
			["separator"] = { "fg", "FloatBorder" },
			["scrollbar"] = { "fg", "FloatBorder" },
		},
		winopts = {
			backdrop = false,
			winblend = 0,
			border = "rounded",
			preview = {
				border = "rounded",
				winopts = { winblend = 0 },
			},
			treesitter = { enabled = true, fzf_colors = false },
		},
		files = {
			no_ignore = true,
			file_ignore_patterns = {
				"%.worktrees/",
			},
		},
		grep = {
			rg_opts = "--column --line-number --no-heading --color=never --smart-case --max-columns=4096 --hidden --no-ignore --glob '!.git' --glob '!.jj' --glob '!node_modules' --glob '!.worktrees'",
		},
	})
end

function M.jj_changed()
	local fzf = require("fzf-lua")
	local base_rev = jj_origin_trunk_rev()
	local quoted_base_rev = vim.fn.shellescape(base_rev)

	fzf.fzf_exec("jj diff --from " .. quoted_base_rev .. " --name-only", {
		prompt = false,
		winopts = { width = 0.9, height = 0.9 },
		fzf_opts = {
			["--no-info"] = "",
			["--no-sort"] = "",
			["--disabled"] = "",
			["--preview-window"] = "right,62%",
		},
		keymap = {
			fzf = {
				["j"] = "down",
				["k"] = "up",
				["q"] = "abort",
			},
		},
		preview = "jj diff --from " .. quoted_base_rev .. " --git -- {1} | delta",
		actions = {
			["default"] = function(selected)
				if selected and selected[1] then
					local file = selected[1]
					local diff = vim.fn.system({ "jj", "diff", "--from", base_rev, "--git", "--", file })
					local line = 1
					for hunk in diff:gmatch("@@ %S+ %+(%d+)") do
						line = tonumber(hunk)
						break
					end
					vim.cmd("edit +" .. line .. " " .. vim.fn.fnameescape(file))
				end
			end,
		},
	})
end

return M
