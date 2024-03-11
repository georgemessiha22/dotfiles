--[[
  File: lsp_zero.lua
  Description: LSP zero plugin configuration
  See: https://lsp-zero.netlify.app/v3.x/getting-started.html
]]
-- LSP zero {{{

return {
	"VonHeikemen/lsp-zero.nvim",
	branch = "v3.x",
	config = function()
		local lzp_zero = require("lsp-zero")
		lsp_zero.on_attach(function(client, bufnr)
			lsp_zero.default_keymaps({ buffer = bufnr })
		end)
	end,
}
-- }}}
