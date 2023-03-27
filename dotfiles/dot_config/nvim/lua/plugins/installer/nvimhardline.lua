--[[
  File: nvimhardline.lua
  Description: hardline plugin configuration
  See: https://github.com/ojroques/nvim-hardline
]]
return {
	'ojroques/nvim-hardline',
	config = function()
		require("hardline").setup({
			bufferline = false, -- disable bufferline

			bufferline_settings = {
				exclude_terminal = false, -- don't show terminal buffers in bufferline
				show_index = true,    -- show buffer indexes (not the actual buffer numbers) in bufferline
				seprator = ' | ',
			},
			theme = "catppuccin_minimal", -- change theme ["default", "nord", "catppuccin_minimal", "jellybeans", "one", "oxocarbon", "codeschool_dark"]
			sections = {               -- define sections
				{ class = 'mode',       item = require('hardline.parts.mode').get_item },
				{ class = 'high',       item = require('hardline.parts.git').get_item,     hide = 100 },
				-- { class = 'mode',       item = require('hardline.parts.cwd').get_item },
				{ class = 'bufferline', item = require('hardline.parts.filename').get_item },
				'%<',
				{ class = 'med',     item = '%=' },
				-- { class = 'low',     item = require('hardline.parts.wordcount').get_item,         hide = 100 },
				{ class = 'error',   item = require('hardline.parts.lsp').get_error },
				{ class = 'warning', item = require('hardline.parts.lsp').get_warning },
				{ class = 'warning', item = require('hardline.parts.whitespace').get_item },
				{ class = 'high',    item = require('hardline.parts.filetype').get_item,          hide = 60 },
				{ class = 'error',   item = require('hardline.parts.treesitter-context').get_item },
				{ class = 'mode',    item = require('hardline.parts.line').get_item },
			},
		})
	end
}
