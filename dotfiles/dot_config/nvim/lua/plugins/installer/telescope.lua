--[[
  File: telescope.lua
  Description: Telescope plugin configuration
  See: https://github.com/nvim-telescope/telescope.nvim
]]
-- Telescope {{{
return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.5",
	lazy = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
			cond = function()
				return vim.fn.executable("make") == 1
			end,
		},
	},
	config = function()
		local icons = require("config").icons
		local ui = require("config").ui
		local telescope = require("telescope")
		telescope.setup({
			pickers = {
				find_files = {
					hidden = true,
				},
			},
			defaults = {
				layout_strategy = "flex",
				layout_config = {
					-- flip_columns = 120,
					vertical = { width = 0.5 },
				},
				vimgrep_arguments = {
					"rg",
					"-L",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
				},
				prompt_prefix = icons.ui.Scopes .. " ",
				file_ignore_patterns = {
					".git",
					"node%_modules",
				},
			},

			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
			},
			picker = ui.telescope,
		})

		-- load extensions
		-- for _, ext in ipairs({ "terms", "fzf" }) do
		-- 	telescope.load_extension(ext)
		-- end
		require("config").load_mapping("telescope")
	end,
}
-- }}}
