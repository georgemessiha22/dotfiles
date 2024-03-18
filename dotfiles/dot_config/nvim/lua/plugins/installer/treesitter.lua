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
			"nvim-treesitter/nvim-treesitter-textobjects",
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
						init_selection = "gnn", -- set to `false` to disable one of the mappings
						node_incremental = "grn",
						scope_incremental = "grc",
						node_decremental = "grm",
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
				texobjects = {
					select = {
						enable = true,

						-- Automatically jump forward to textobj, similar to targets.vim
						lookahead = true,

						keymaps = {
							-- You can use the capture groups defined in textobjects.scm
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							-- You can optionally set descriptions to the mappings (used in the desc parameter of
							-- nvim_buf_set_keymap) which plugins like which-key display
							["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
							-- You can also use captures from other query groups like `locals.scm`
							["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
						},
						-- You can choose the select mode (default is charwise 'v')
						--
						-- Can also be a function which gets passed a table with the keys
						-- * query_string: eg '@function.inner'
						-- * method: eg 'v' or 'o'
						-- and should return the mode ('v', 'V', or '<c-v>') or a table
						-- mapping query_strings to modes.
						selection_modes = {
							["@parameter.outer"] = "v", -- charwise
							["@function.outer"] = "V", -- linewise
							["@class.outer"] = "<c-v>", -- blockwise
						},
						-- If you set this to `true` (default is `false`) then any textobject is
						-- extended to include preceding or succeeding whitespace. Succeeding
						-- whitespace has priority in order to act similarly to eg the built-in
						-- `ap`.
						--
						-- Can also be a function which gets passed a table with the keys
						-- * query_string: eg '@function.inner'
						-- * selection_mode: eg 'v'
						-- and should return true or false
						include_surrounding_whitespace = true,
					},
				},
				modules = {
					"nvim-treesitter/nvim-treesitter-refactor",
					"windwp/nvim-ts-autotag",
					"nvim-treesitter/nvim-tree-docs",
					"nvim-treesitter/nvim-treesitter-textobjects",
				},
			})
		end,
	},
}
-- }}}
