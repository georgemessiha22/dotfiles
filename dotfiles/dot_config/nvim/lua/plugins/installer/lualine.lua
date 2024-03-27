--[[
  File: lualine.lua
  Description: Lualine for status line
  See: https://github.com/nvim-lualine/lualine.nvim
--]]

return {
	{
		"arkav/lualine-lsp-progress",
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			-- Color for highlights
			local colors = {
				yellow = "#ECBE7B",
				cyan = "#008080",
				darkblue = "#081633",
				green = "#98be65",
				orange = "#FF8800",
				violet = "#a9a1e1",
				magenta = "#c678dd",
				blue = "#51afef",
				red = "#ec5f67",
			}
			require("lualine").setup({
				--[[
					branch (git branch) ✔️
					buffers (shows currently available buffers) ✔️
					diagnostics (diagnostics count from your preferred source) ✔️
					diff (git diff status)
					encoding (file encoding)
					fileformat (file format)
					filename
					filesize
					filetype
					hostname
					location (location in file in line:column format)
					mode (vim mode)
					progress (%progress in file)
					searchcount (number of search matches when hlsearch is active)
					selectioncount (number of selected characters or lines)
					tabs (shows currently available tabs)
					windows (shows currently available windows)
				--]]
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch", "diff", "diagnostics" },
					lualine_c = {
						{
							"lsp_progress",
							colors = {
								percentage = colors.cyan,
								title = colors.cyan,
								message = colors.cyan,
								spinner = colors.cyan,
								lsp_client_name = colors.magenta,
								use = true,
							},
							separators = {
								component = " ",
								progress = " | ",
								percentage = { pre = "", post = "%%" },
								title = { pre = "", post = ":" },
								lsp_client_name = { pre = "[", post = "]" },
								spinner = { pre = "", post = "" },
								message = { pre = "(", post = ")", commenced = "In Progress", completed = "Completed" },
							},
							display_components = {
								"lsp_client_name",
								"spinner",
								{
									--[[ "title", ]]
									"percentage",
									--[[ "message" ]]
								},
							},
							-- timer = { progress_enddelay = 500, spinner = 1000, lsp_client_name_enddelay = 1000 },
							spinner_symbols = { "🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘" },
						},
						{
							"filename",
							path = 1,
						},
						-- {
						-- 	"progress",
						-- 	seprator = " ",
						-- 	padding = { left = 0, right = 1 },
						-- },
					},
					lualine_x = {
						-- "encoding",
						-- "fileformat",
						"filetype",
					},
					lualine_y = { "location", "selectioncount", "searchcount" },
					lualine_z = {
						{ "os.date('%l:%M %p')", "data", "require'lsp-status'.status()" },
					},
				},
				tabline = {
					-- lualine_c = { "buffers" },
					-- lualine_x = { { "tabs" } },
					-- lualine_y = { "windows" },
				},
				-- winbar = { lualine_a = { "windows" } },
				options = {
					-- theme = "nord",
					theme = "auto",
					globalstatus = false,
					disabled_filetypes = {

						"neo-tree",
						"trouble",
					},
					component_separators = { left = "", right = "|" },
					section_separators = { left = "", right = "" },
				},
				extensions = {
					-- "aerial",
					-- "chadtree",
					-- "ctrlspace",
					-- "fern",
					-- "fugitive",
					"fzf",
					"lazy",
					-- "man",
					"mason",
					-- "mundo",
					"neo-tree",
					-- "nerdtree",
					"nvim-dap-ui",
					-- "nvim-tree",
					-- "oil",
					-- "overseer",
					"quickfix",
					"symbols-outline",
					-- "toggleterm",
					"trouble",
				},
			})
		end,
	},
}
