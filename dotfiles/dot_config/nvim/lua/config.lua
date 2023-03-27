local M = {}

local merge_table = vim.tbl_deep_extend
local mapkey = vim.keymap.set

M.icons = require("icons")

M.ui = require("ui")

M.echo = function(message)
	vim.cmd("redraw")
	vim.api.nvim_echo({ { message, "Bold" } }, true, {})
end

M.bootstrap = function()
	-- Setup Lazy {{{
	local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

	if not vim.loop.fs_stat(lazypath) then
		M.echo("  Installing lazy.nvim")
		vim.fn.system({
			"git",
			"clone",
			"--filter=blob:none",
			"https://github.com/folke/lazy.nvim.git",
			"--branch=stable", -- latest stable release
			lazypath,
		})
	end

	vim.opt.rtp:prepend(lazypath)
	-- }}}
end

M.SetupPlugins = function()
	-- Load Plugins {{{
	require("lazy").setup(require("plugins"))
	-- }}}
end

M.load_mapping = function(section)
	vim.schedule(function()
		local function set_section_map(values)
			if values.plugin then -- bypass plugins section
				return
			end
			values.plugin = nil                              -- this to garauntee all values are pair

			for mode, mode_values in pairs(values) do        -- first layer is modes i, v, t, x
				for keybind, mapping_info in pairs(mode_values) do -- second layer is key = {command, description}
					local opts = merge_table("force", { desc = mapping_info[2], noremap = true }, mapping_info.opts or {})
					mapkey(mode, keybind, mapping_info[1], opts)
				end
			end
		end

		local mappings = require("mappings")

		if type(section) == "string" then -- if section declared only load this section
			mappings[section]["plugin"] = nil
			mappings = { mappings[section] }
		end

		for _, sec in pairs(mappings) do
			set_section_map(sec)
		end
	end)
end

M.load_config = function()
	-- load general settings
	require("settings")

	-- load keybindings
	M.load_mapping()
end

return M
