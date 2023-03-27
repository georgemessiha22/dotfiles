--[[
  File: neotree.lua
  Description: NeoTree plugin configuration
  See: https://github.com/nvim-neo-tree/neo-tree.nvim
]]
-- Neo Tree {{{
return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		"MunifTanjim/nui.nvim",
		{
			"s1n7ax/nvim-window-picker",
			version = "2.*",
			config = function()
				require("window-picker").setup({
					hint = "statusline-windbar",
					filter_rules = {
						include_current_win = false,
						autoselect_one = true,
						-- filter using buffer options
						bo = {
							-- if the file type is one of following, the window will be ignored
							filetype = { "neo-tree", "neo-tree-popup", "notify" },
							-- if the buffer type is one of following, the window will be ignored
							buftype = { "terminal", "quickfix" },
						},
					},
				})
			end,
		},
	},
	config = function()
		local icons = require("config").icons
		-- If you want icons for diagnostic errors, you'll need to define them somewhere:
		vim.fn.sign_define("DiagnosticSignError", { text = icons.diagnostics.Error, texthl = "DiagnosticSignError" })
		vim.fn.sign_define(
			"DiagnosticSignWarn",
			{ text = icons.diagnostics.BoldWarning, texthl = "DiagnosticSignWarn" }
		)
		vim.fn.sign_define(
			"DiagnosticSignInfo",
			{ text = icons.diagnostics.BoldInformation, texthl = "DiagnosticSignInfo" }
		)
		vim.fn.sign_define("DiagnosticSignHint", { text = icons.diagnostics.BoldHint, texthl = "DiagnosticSignHint" })
		require("neo-tree").setup({
			close_if_last_window = true,
			name = {
				trailing_slash = true,
				use_git_status_colors = true,
				highlight = "NeoTreeFileName",
			},
			window = {
				width = 25,
				mappings = {
					["l"] = "open",
					["h"] = "close_node",
				},
			},
			filesystem = {
				follow_current_file = {
					enabled = true,
				},
			},
			source_selector = {
				winbar = false,
				statusline = true,
			},
		})

		require("config").load_mapping("neotree")
	end,
}
-- }}}
