--[[
-- File: todo-comment.lua
-- Description: Enable colors for comment tags in projects
-- See: https://github.com/folke/todo-comments.nvim/tree/main?tab=readme-ov-file
--]]

return {
	"folke/todo-comments.nvim",
	name = "todo-comments",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		require("todo-comments").setup({
			signs = true,
			keywords = {
				TODO = { icon = " ", color = "info" },
				DONE = { icon = " ", color = "warning" },
				HACK = { icon = " ", color = "warning" },
				WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
				PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
				NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
			},
			highlight = {
				before = "",
				keyword = "fg",
				comments_only = true,
			},
			colors = {
				error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
				warning = { "DiagnosticWarning", "WarningMsg", "#FBBF24" },
				info = { "DiagnosticInfo", "#2563EB" },
				hint = { "DiagnosticHint", "#10B981" },
				default = { "Identifier", "#7C3AED" },
			},
		})
		require("config").load_mapping("todo")
	end,
}
