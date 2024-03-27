-- Theme
return {
	-- Theme: catppuccin {{{
	{
		"catppuccin/nvim",
		lazy = true,
		name = "catppuccin",
		opts = {
			integrations = {
				aerial = true,
				alpha = true,
				cmp = true,
				dashboard = true,
				flash = true,
				gitsigns = true,
				headlines = true,
				illuminate = true,
				indent_blankline = { enabled = true },
				leap = true,
				lsp_trouble = true,
				mason = true,
				markdown = true,
				mini = true,
				native_lsp = {
					enabled = true,
					underlines = {
						errors = { "undercurl" },
						hints = { "undercurl" },
						warnings = { "undercurl" },
						information = { "undercurl" },
					},
				},
				navic = { enabled = true, custom_bg = "lualine" },
				neotest = true,
				neotree = true,
				noice = true,
				notify = true,
				semantic_tokens = true,
				telescope = true,
				treesitter = true,
				treesitter_context = true,
				which_key = true,
			},
		},
	},
	-- }}}

	-- Theme: Sonokai {{{
	{
		"sainnhe/sonokai",
		lazy = false,
		config = function() end,
	},
	-- }}}

	-- Theme: Tokyonight {{{
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.g.tokyodark_enable_italic_comment = true
			vim.g.tokyodark_enable_italic = true
		end,
	},
	-- }}}

	-- Theme: Neon {{{
	{
		"rafamadriz/neon",
		lazy = false,
		priority = 1000,
		config = function()
			vim.g.neon_italic_keyword = true
			vim.g.neon_italic_function = true
		end,
		opts = {},
	},
	-- }}}

	{
		"ray-x/starry.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.g.starry_italic_comments = true
			require("starry").setup()
		end,
	},
}
