--[[
  File: ts_autotag.lua
  Description: TS plugin configuration
  See: https://github.com/windwp/nvim-ts-autotag
]]
return {
	"windwp/nvim-ts-autotag",
	lazy = true,
	config = function()
		require("nvim-ts-autotag").setup()
	end,
}
