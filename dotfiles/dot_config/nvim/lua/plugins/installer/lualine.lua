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
			local ui = require("config").ui
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
					lualine_c = { "lsp_progress", { "filename", path = 1 } },
					lualine_x = { "encoding", "fileformat", "filetype" },
					lualine_y = { "progress" },
					lualine_z = {
						"location",
						-- "selectioncount",
						"searchcount",
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
					-- globalstatus = true,
					disabled_filetypes = {
						"neo-tree",
						-- "trouble",
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
					-- "neo-tree",
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
