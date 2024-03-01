--[[
  File: mappings.lua
  Description: Base keybindings for neovim
  Info: Use <zo> and <zc> to open and close foldings
]]
-- Copying the mappings way of NvChad. using maps for definitions and later load them using `vim.schedule`

-- n, v, i, t = mode names
-- for plugin add M.pluginname = {}

-- TODO: rewrite this file to use wk.register instead
local M = {}

M.general = {
	i = {
		-- go to  beginning and end
		["<C-b>"] = { "<ESC>^i", "Beginning of line" },
		["<C-e>"] = { "<End>", "End of line" },

		-- navigate within insert mode
		["<C-h>"] = { "<Left>", "Move left" },
		["<C-l>"] = { "<Right>", "Move right" },
		["<C-j>"] = { "<Down>", "Move down" },
		["<C-k>"] = { "<Up>", "Move up" },

		-- save
		["<C-s>"] = { "<ESC><CR> <cmd>w<CR>", "Save file" },
	},

	n = {
		--["<C-_>"] = { function()
		--  vim.notify("HI")
		-- end, "SayHI" },

		["<Esc>"] = { ":noh <CR>", "Clear highlights" },

		-- switch between windows
		["<C-h>"] = { "<C-w>h", "Window left" },
		["<C-l>"] = { "<C-w>l", "Window right" },
		["<C-j>"] = { "<C-w>j", "Window down" },
		["<C-k>"] = { "<C-w>k", "Window up" },

		-- save
		["<C-s>"] = { "<cmd> w <CR>", "Save file" },

		-- Copy all
		["<C-c>"] = { "<cmd> %y+ <CR>", "Copy whole file" },

		-- line numbers
		["<Leader>ln"] = { "<cmd> set nu! <CR>", "Toggle line number" },
		["<Leader>rn"] = { "<cmd> set rnu! <CR>", "Toggle relative number" },

		-- Allow moving the cursor through wrapped lines with j, k, <Up> and <Down>
		-- http://www.reddit.com/r/vim/comments/2k4cbr/problem_with_gj_and_gk/
		-- empty mode is same as using <cmd> :map
		-- also don't use g[j|k] when in operator pending mode, so it doesn't alter d, y or c behaviour
		["j"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
		["k"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
		["<Up>"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
		["<Down>"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },

		-- new buffer
		["<Leader>bn"] = { "<cmd> enew <CR>", "New buffer" },
		["<Leader>bc"] = { "<cmd>bd<CR>", "Close buffer" },

		-- split screen
		["<Leader>sv"] = { "<cmd>vsplit<CR>", "Split screen vertically" },
		["<Leader>sh"] = { "<CMD>split h<CR>", "Split screen horizontally" },

		-- formatting
		["<leader>fm"] = {
			function()
				vim.lsp.buf.format({ async = true })
			end,
			"LSP formatting",
		},

		["<leader>e"] = {
			"<cmd>lua vim.diagnostic.open_float()<CR>",
			"Open Diagnostics",
			opts = { noremap = true, silent = true },
		},

		-- tab movements
		-- ["tl"] = {'', "Move to left tab"},
		-- ["th"] = {'', "Move to right tab"},
		["<leader>tn"] = { "<cmd>bNext<CR>", "Move to next tab" },
		["<leader>tp"] = { "<cmd>bprevious<CR>", "Move to previous tab" },
	},

	t = {
		["<C-x>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, true, true), "Escape terminal mode" },
	},

	v = {
		["<Up>"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
		["<Down>"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
	},

	x = {
		["j"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
		["k"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
		-- Don't copy the replaced text after pasting in visual mode
		-- https://vim.fandom.com/wiki/Replace_a_word_with_yanked_text#Alternative_mapping_for_paste
		["p"] = { 'p:let @+=@0<CR>:let @"=@0<CR>', "Dont copy replaced text", opts = { silent = true } },
	},
}

M.lspconfig = {
	plugin = true,

	-- See `<cmd> :help vim.lsp.*` for documentation on any of the below functions

	n = {
		["gD"] = {
			function()
				vim.lsp.buf.declaration()
			end,
			"LSP declaration",
		},

		["gd"] = {
			function()
				vim.lsp.buf.definition()
			end,
			"LSP definition",
		},

		["K"] = {
			function()
				vim.lsp.buf.hover()
			end,
			"LSP hover",
		},

		["gi"] = {
			function()
				vim.lsp.buf.implementation()
			end,
			"LSP implementation",
		},

		["<leader>ls"] = {
			function()
				vim.lsp.buf.signature_help()
			end,
			"LSP signature help",
		},

		["<leader>D"] = {
			function()
				-- vim.notify("DD")
				vim.lsp.buf.type_definition()
			end,
			"LSP definition type",
		},

		["<leader>ra"] = {
			function()
				vim.lsp.buf.rename()
			end,
			"LSP rename",
		},

		["<leader>ca"] = {
			function()
				vim.lsp.buf.code_action()
			end,
			"LSP code action",
		},

		["gr"] = {
			function()
				vim.lsp.buf.references()
			end,
			"LSP references",
		},

		["<leader>d"] = {
			function()
				vim.diagnostic.open_float({ border = "rounded" })
			end,
			"Floating diagnostic",
		},

		["[d"] = {
			function()
				vim.diagnostic.goto_prev({ float = { border = "rounded" } })
			end,
			"Goto prev",
		},

		["]d"] = {
			function()
				vim.diagnostic.goto_next({ float = { border = "rounded" } })
			end,
			"Goto next",
		},

		["<leader>ql"] = {
			function()
				vim.diagnostic.setloclist()
			end,
			"Diagnostic setloclist",
		},

		["<leader>wa"] = {
			function()
				vim.lsp.buf.add_workspace_folder()
			end,
			"Add workspace folder",
		},

		["<leader>wr"] = {
			function()
				vim.lsp.buf.remove_workspace_folder()
			end,
			"Remove workspace folder",
		},

		["<leader>wl"] = {
			function()
				print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
			end,
			"List workspace folders",
		},
	},
}

M.telescope = {
	plugin = true,

	n = {
		["<leader>ldw"] = { "<cmd> Telescope lsp_dynamic_workspace_symbols<CR>", "Search for dynamic symbols" },
		["<leader>tld"] = { "<cmd> Telescope lsp_definitions <CR>", "TeleScope defentions" },
		["<leader>li"] = { "<cmd> Telescope lsp_implementations <CR>", "Lsp implementations" },
		["<leader>lwd"] = { "<cmd> Telescope diagnostics <CR>", "Show Workspace Diagnostics" },
		["<leader>lts"] = { "<cmd> Telescope treesitter <CR>", "Show treesitter" },
		["<leader>qf"] = { "<cmd> Telescope quickfix <CR>", "Show quickfixes" },
		["<leader>lci"] = { "<cmd> Telescope lsp_outgoing_calls <CR>", "Show LSP outgoing calls" },
		["<leader>lco"] = { "<cmd> Telescope lsp_incoming_calls <CR>", "Show LSP incoming calls" },
		["<leader>ltd"] = { "<cmd> Telescope lsp_type_defentions <CR>", "Show LSP type definition" },
		["<leader>lr"] = { "<cmd> Telescope lsp_references <CR>", "Show LSP references" },
		-- find
		["<leader>F"] = { "<cmd> Telescope find_files <CR>", "Find files", opts = { noremap = true } },
		["<leader>fa"] = { "<cmd> Telescope find_files follow=true no_ignore=true hidden=true <CR>", "Find all" },
		["<leader>fw"] = { "<cmd> Telescope live_grep <CR>", "Live grep" },
		["<leader>fs"] = { "<cmd> Telescope grep_string <CR>", "Search keyword" },
		["<leader>fb"] = { "<cmd> Telescope buffers <CR>", "Find buffers" },
		["<leader>fh"] = { "<cmd> Telescope help_tags <CR>", "Help page" },
		["<leader>fo"] = { "<cmd> Telescope oldfiles <CR>", "Find oldfiles" },
		["<leader>fz"] = { "<cmd> Telescope current_buffer_fuzzy_find <CR>", "Find in current buffer" },

		-- git
		["<leader>gcm"] = { "<cmd> Telescope git_commits <CR>", "Git commits" },
		["<leader>gt"] = { "<cmd> Telescope git_status <CR>", "Git status" },
		["<leader>gba"] = { "<cmd> Telescope git_branches <CR>", "Show git branches" },
		["<leader>gbc"] = { "<cmd> Telescope git_bcommits <CR", "Show Blame commits" },
		["<leader>gf"] = { "<cmd> Telescope git_files <CR>", "Search for a file in project" },

		-- pick a hidden term
		-- ["<leader>pt"]  = { "<cmd> Telescope terms <CR>", "Pick hidden term" },

		-- theme switcher
		["<leader>th"] = { "<cmd> Telescope colorscheme <CR>", "Themes" },

		-- notification history
		["<leader>tn"] = { "<cmd> Telescope notify <CR>", "Show notification history" },

		["<leader>i"] = { "<cmd> Telescope jumplist <CR>", "Show jumplist (previous locations)" },
		["<leader>ma"] = { "<cmd> Telescope marks <CR>", "telescope bookmarks" },

		["<leader>ta"] = { "<cmd> Telescope <CR>", "Show all commands" },
	},
}

M.trouble = {
	plugin = true,
	n = {
		["<leader>xx"] = { "<CMD>TroubleToggle<CR>", "Show Trouble" },
		["<leader>xw"] = { "<CMD>TroubleToggle workspace_diagnostics<CR>", "Show trouble workspace_diagnostics" },
		["<leader>xd"] = { "<CMD>TroubleToggle document_diagnostics<CR>", "Show trouble document_diagnostics" },
		["<leader>xq"] = { "<CMD>TroubleToggle quickfix<CR>", "Show touble quickfixes" },
	},
}

M.neotree = {
	plugin = true,
	n = {
		["<leader>nf"] = { "<cmd> Neotree toggle float <CR>", "Open/Close explroer float" },
		["<leader>nl"] = { "<cmd> Neotree toggle left <CR>", "Open/Cloase explroer on left" },
		["<leader>nr"] = { "<cmd> Neotree toggle right <CR>", "Open/Close explorer on right" },
	},
}

M.comment = {
	plugin = true,

	-- toggle comment in both modes
	n = {
		["<C-_>"] = {
			function()
				require("Comment.api").toggle.linewise.current()
			end,
			"Toggle comment line wise",
		},
	},

	v = {
		["<C-_>"] = {
			function()
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, true, true), "nx", true)

				require("Comment.api").locked("toggle.blockwise")(vim.fn.visualmode())
			end,
			"Toggle comment blockwise",
		},
	},
}

M.whichkey = {
	plugin = true,

	n = {
		["<leader>wK"] = {
			function()
				vim.cmd("WhichKey")
			end,
			"Which-key all keymaps",
		},
		["<leader>wk"] = {
			function()
				local input = vim.fn.input("WhichKey: ")
				vim.cmd("WhichKey " .. input)
			end,
			"Which-key query lookup",
		},
	},
}

M.cmp = {
	plugin = true,
	--	cmp keymaps are configured in `plugins/installer/cmp.lua`
}

M.iconpicker = {
	plugin = true,
	n = {
		["<leader><leader>i"] = { "<CMD>IconPickerInsert<CR>", "Icon Picker" },
		["<Leader><Leader>y"] = { "<CMD> IconPickerYank <CR>", "Icon Picker yank" },
	},
}

M.todo = {
	plugin = true,
	n = {
		["<leader>td"] = { "<CMD> TodoTelescope <CR>", "ToDo list" },
	},
}

return M
