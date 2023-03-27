--[[
  File: trouble.lua
  Description: Configuration of trouble.nvim
  See: https://github.com/folke/trouble.nvim
]]
-- Trouble {{{
return {
	"folke/trouble.nvim",
	lazy = false,
	dependencies = "nvim-tree/nvim-web-devicons",
	opts = { use_diagnostic_signs = true },
	config = function(_, opts)
		require("trouble").setup(opts)
		require("config").load_mapping("trouble")
	end,
}
-- }}}
