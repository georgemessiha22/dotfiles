return {
	------------------------------- base46 -------------------------------------
	-- hl = highlights
	hl_add = {},
	hl_override = {},
	changed_themes = {},
	theme_toggle = { "catppuccin_mocha", "catppuccin_macchiato" },
	theme = "catppuccin_macchiato", -- default theme
	transparency = false,
	lsp_semantic_tokens = false,   -- needs nvim v0.9, just adds highlight groups for lsp semantic tokens
	termguicolors = true,

	-- cmp themeing
	cmp = {
		icons = true,
		lspkind_text = true,
		style = "default",          -- default/flat_light/flat_dark/atom/atom_colored
		border_color = "grey_fg",   -- only applicable for "default" style, use color names from base30 variables
		selected_item_bg = "colored", -- colored / simple
	},

	telescope = {
		style = "borderless",
	}, -- borderless / bordered

	------------------------------- nvchad_ui modules -----------------------------
	statusline = {
		theme = "PaperColor", -- auto/gruvbox-material/nord/powerline/onedark/papercolor/palenight/
		-- default/round/block/arrow separators work only for default statusline theme
		-- round and block will work for minimal theme only
		separator_style = "|",
		overriden_modules = nil,
	},

	-- dash (dashboard)
	dash = {
		load_on_startup = true,

		header = {
			"                                                     ",
			"                                                     ",
			"                                                     ",
			"                                                     ",
			"/====================================================\\",
			"||                                                  ||",
			"||                                                  ||",
			"||                                                  ||",
			"||      █████████             █████████             ||",
			"||     ███░░░░░███           ███░░░░░███            ||",
			"||    ███     ░░░   ██████  ███     ░░░   ██████    ||",
			"||   ░███          ███░░███░███          ███░░███   ||",
			"||   ░███    █████░███ ░███░███    █████░███ ░███   ||",
			"||   ░░███  ░░███ ░███ ░███░░███  ░░███ ░███ ░███   ||",
			"||    ░░█████████ ░░██████  ░░█████████ ░░██████    ||",
			"||     ░░░░░░░░░   ░░░░░░    ░░░░░░░░░   ░░░░░░     ||",
			"||                                                  ||",
			"||                                                  ||",
			"||                                                  ||",
			"\\====================================================/",
			"                                                     ",
			"                                                     ",
			"                                                     ",
			"                                                     ",
		},
		center = {
			{ icon = "  ", desc = "Find File", key = "Spc f f", action = "Telescope find_files" },
			-- { icon = "󰈚  ", desc = "Recent Files", key = "Spc f o", action = "Telescope oldfiles" },

			{ icon = "󰈭  ", desc = "Find Word", key = "Spc f w", action = "Telescope live_grep" },
			{ icon = "  ", desc = "Bookmarks", key = "Spc m a", action = "Telescope marks" },

			{ icon = "  ", desc = "Themes", key = "Spc t h", action = "Telescope themes" },

			-- { icon = "  ", desc = "Mappings", key = "Spc c h", action = "NvCheatsheet" },
		},

		disable_mode = false,
	},

	-- cheatsheet = { theme = "grid" }, -- simple/grid

	lsp = {
		-- show function signatures i.e args as you type
		signature = {
			disabled = false,
			silent = true, -- silences 'no signature help available' message from appearing
		},
	},
}
