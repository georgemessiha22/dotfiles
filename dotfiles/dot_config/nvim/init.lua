vim.pack.add({ { src = "https://github.com/georgemessiha22/GogoNvim", version = "master", data = { confirm = false } } })
vim.pack.add({
	{
		src = "https://github.com/folke/which-key.nvim",
		name = "which-key",
		data = {},
	},
})

require("which-key").setup({
	triggers = {
		{ "<auto>", mode = "nixsotc" },
		{ "a", mode = { "n", "v" } },
	},
})
