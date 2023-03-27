--[[
  File: bufferline.lua
  Description:  BufferLine plugin configuration
  See: https://github.com/akinsho/bufferline.nvim
]]
return {
	'akinsho/bufferline.nvim',
	version = "*",
	dependencies = { 'nvim-tree/nvim-web-devicons' },
	config = function()
		require("bufferline").setup()
	end
}
