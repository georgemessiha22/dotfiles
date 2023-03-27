--[[
  File: treesitter.lua
  Description: Configuration of tree-sitter
  See: https://github.com/tree-sitter/tree-sitter
]]

-- TreeSitter {{{
return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = true,
		build = ":TSUpdate",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"nvim-treesitter/nvim-tree-docs",
			"nvim-treesitter/nvim-treesitter-refactor",
			"folke/twilight.nvim",
			"windwp/nvim-ts-autotag",
		},
		config = function()
			require("nvim-treesitter.configs").setup({

				-- Needed parsers
				ensure_installed = {
					"lua",
					"vim",
					"vimdoc",
					"typescript",
					"javascript",
					"go",
					"python",
					"astro",
					"svelte",
					"ruby",
					-- "nu",
				},

				-- Install all parsers synchronously
				sync_install = true,
				-- Automatically install missing parsers when entering buffer
				-- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
				auto_install = true,

				-- List of parsers to ignore installing (or "all")
				ignore_install = { "C" },

				highlight = {
					-- Enabling highlight for all files
					enable = true,
					disable = {},
				},

				indent = {
					enable = true,
				},

				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "<C-space>", -- set to `false` to disable one of the mappings
						node_incremental = "<C-space>",
						scope_incremental = false,
						node_decremental = "<bs>",
					},
				},
				refactor = {
					-- highlight_current_scope = { enable = true },
					highlight_definitions = {
						enable = true,
						-- Set to false if you have an `updatetime` of ~100.
						clear_on_cursor_move = true,
					},
					smart_rename = {
						enable = true,
						-- Assign keymaps to false to disable them, e.g. `smart_rename = false`.
						keymaps = {
							smart_rename = "grr",
						},
					},
				},
				tree_docs = {
					enable = true,
					spec_config = {
						jsdoc = {
							slots = {
								class = { author = true },
							},
							processors = {
								author = function()
									return " * @author George Messiha"
								end,
							},
						},
					},
				},
				modules = {
					"nvim-treesitter/nvim-treesitter-refactor",
					"folke/twilight.nvim",
					"windwp/nvim-ts-autotag",
					"nvim-treesitter/nvim-tree-docs",
				},
			})
		end,
	},
}
-- }}}
