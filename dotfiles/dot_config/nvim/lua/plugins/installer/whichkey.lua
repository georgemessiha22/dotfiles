--[[
  File: whichkey.lua
  Description: WhichKey plugin configuration
  See: https://github.com/folke/which-key.nvim
]]
return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	keys = { "<leader>", '"', "'", "`", "c", "v", "g", "f", "c", "<C>", "t" },
	config = function(_, opts)
		require("which-key").setup(opts)
		require("config").load_mapping("whichkey")
	end,
}
