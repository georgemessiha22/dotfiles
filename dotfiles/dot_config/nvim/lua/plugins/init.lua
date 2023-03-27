return {
	"nvim-lua/plenary.nvim",
	require("plugins.installer.theme"),
	require("plugins.installer.cmp"),
	require("plugins.installer.gitsigns"),

	-- LSP, Formatter, Diagnositcs {{{
	require("plugins.installer.lsp_kind"),
	require("plugins.installer.mason"),
	require("plugins.installer.none-ls"),
	require("plugins.installer.neodev"),
	require("plugins.installer.nushell"),

	-- LSP, language specific
	require("plugins.installer.go"),
	require("plugins.installer.rustacean"),
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

	-- Bars
	require("plugins.installer.bufferline"),
	require("plugins.installer.lualine"),
	-- require("plugins.installer.nvimhardline"),
	require("plugins.installer.dashboard"),

	-- Helpers
	require("plugins.installer.whichkey"),
	"rcarriga/nvim-notify",
	require("plugins.installer.ts_autotag"),
	require("plugins.installer.iconpicker"),
	require("plugins.installer.colorizer"),
}
