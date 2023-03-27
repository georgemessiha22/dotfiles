--[[
  File: gitsigns.lua
  Description: Configuration of gitsigns
  See: https://github.com/lewis6991/gitsigns.nvim
]]
-- Git Signs{{{
return {
	"lewis6991/gitsigns.nvim",
	lazy = false,
	config = function()
		local gitIcons = require("config").icons.git
		require("gitsigns").setup({
			signs = {
				add = { text = gitIcons.LineAdded },
				change = { text = gitIcons.LineModified },
				delete = { text = gitIcons.LineRemoved },
				topdelete = { text = gitIcons.LineRemoved },
				changedelete = { text = "~" },
				untracked = { text = gitIcons.FileUnstaged },
			},
			current_line_blame = false,
			current_line_blame_opts = {
				virt_text = true,
				virt_text_pos = "right_align",
				delay = 1000,
				ignore_whitespace = false,
			},
		})
	end,
}
-- }}}
