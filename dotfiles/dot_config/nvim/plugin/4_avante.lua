-- This file lives in plugin/, so vim.pack.add runs after init (vim_did_init == 1)
-- and sources each plugin immediately. avante's plugin script requires plenary
-- and mega.cmdparse at packadd time; those must already be on runtimepath.
-- The README lists avante first because that example runs from init.lua, where
-- packadd is deferred until every spec is on the path.
vim.pack.add({
	-- Deps (must precede avante.nvim)
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/MunifTanjim/nui.nvim",
	"https://github.com/ColinKennedy/mega.logging",
	"https://github.com/ColinKennedy/mega.cmdparse",

	-- Optional deps
	"https://github.com/MeanderingProgrammer/render-markdown.nvim",
	"https://github.com/hrsh7th/nvim-cmp",
	"https://github.com/echasnovski/mini.icons", -- or 'nvim-tree/nvim-web-devicons'
	"https://github.com/HakonHarnes/img-clip.nvim",
	"https://github.com/folke/snacks.nvim", -- for modern input UI

	{
		src = "https://github.com/avante-corp/avante.nvim",
		version = "v1.2.1", -- use the latest tagged releases x-release-please-version
	},
})

-- Config customizations
-- require("avante").setup({
--     provider = 'xai',
-- 	behaviour = {
-- 		auto_suggestions = true,
-- 	},
-- })
--
-- vim.opt.laststatus = 3
