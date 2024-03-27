return {
	"nvim-lua/plenary.nvim",
	require("plugins.installer.theme"),
	require("plugins.installer.cmp"),

	-- Git plugins {{{
	require("plugins.installer.gitsigns"),
	require("plugins.installer.lazygit"),
	-- }}}

	-- LSP, Formatter, Diagnostics {{{
	require("plugins.installer.mason"),
	require("plugins.installer.lsp_kind"),
	require("plugins.installer.none-ls"),

	-- LSP, language specific
	require("plugins.installer.rustacean"),
	require("plugins.installer.go"),
	-- }}}

	-- Find
	require("plugins.installer.fzf"),

	-- Files
	require("plugins.installer.neotree"),

	-- Menus and Submenus {{{
	require("plugins.installer.telescope"),
	require("plugins.installer.dressing"),
	require("plugins.installer.todo-comment"),
	-- }}}

	-- Editor views {{{
	require("plugins.installer.treesitter"),
	require("plugins.installer.trouble"),
	require("plugins.installer.blankline"),
	require("plugins.installer.comment"),
	--}}}

	-- Bars {{{
	require("plugins.installer.lualine"),
	require("plugins.installer.bufferline"),
	require("plugins.installer.dashboard"),
	-- }}}

	-- Helpers
	require("plugins.installer.whichkey"),
	"rcarriga/nvim-notify",
	require("plugins.installer.iconpicker"),
	require("plugins.installer.colorizer"),
}
