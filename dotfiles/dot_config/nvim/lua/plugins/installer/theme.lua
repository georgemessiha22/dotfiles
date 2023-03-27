-- Theme
return {
	-- Theme: catppuccin {{{
	{
		"catppuccin/vim",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
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
