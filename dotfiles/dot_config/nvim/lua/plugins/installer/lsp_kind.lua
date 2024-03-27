--[[
  File: lspkind.lua
  Description: LSP Kind plugin configuration, showing the functions ability after the dot
  See: https://github.com/onsails/lspkind.nvim
]]
-- LSP Kind {{{
return {
	'onsails/lspkind-nvim',
	lazy = true,
	config = function()
		require('lspkind').init({
			mode = 'symbol',
			preset = 'codicons',
			symbol_map = require('config').icons.kind
		})
	end
}
-- }}}
