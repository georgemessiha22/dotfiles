vim.pack.add({ { src = "https://github.com/georgemessiha22/GogoNvim", version = "master", data = { confirm = false } } })
vim.pack.add({
	{
		src = "https://github.com/folke/which-key.nvim",
		name = "which-key",
		data = { confirm = false },
	},
	{
		src = "https://github.com/yetone/avante.nvim",
		version = "main", -- default
	},
	-- deps for Avante {{
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/MunifTanjim/nui.nvim",
	"https://github.com/ColinKennedy/mega.logging",
	"https://github.com/ColinKennedy/mega.cmdparse",

	-- Optional deps
	"https://github.com/MeanderingProgrammer/render-markdown.nvim",
	"https://github.com/hrsh7th/nvim-cmp",
	"https://github.com/nvim-tree/nvim-web-devicons", -- or 'echasnovski/mini.icons'
	"https://github.com/HakonHarnes/img-clip.nvim",
	"https://github.com/zbirenbaum/copilot.lua",
	"https://github.com/folke/snacks.nvim", -- for modern input UI
	-- }}
	-- {
	-- 	src = "https://github.com/rose-pine/neovim",
	-- 	name = "rose-pine",
	-- 	data = { confirm = false },
	-- },
})
