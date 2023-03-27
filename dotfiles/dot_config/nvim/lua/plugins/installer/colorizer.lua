--[[
-- File: colorizer.lua
-- Description: add color background when find color mentioned
-- See: https://github.com/norcalli/nvim-colorizer.lua
--]]

return {
	"norcalli/nvim-colorizer.lua",
	event = "VeryLazy",
	config = function()
		require("colorizer").setup()
	end,
}
