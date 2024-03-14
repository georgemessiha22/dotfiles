--[[
-- File: none-ls
-- Description: Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua.
-- See: https://github.com/nvimtools/none-ls.nvim
--]]

return {
	"nvimtools/none-ls.nvim",
	branch = "main",
	config = function()
		local null_ls = require("null-ls")

		null_ls.setup({
			autostart = true,
			sources = {
				-- formatters
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.formatting.rubocop,
				null_ls.builtins.formatting.sqlfmt,
				null_ls.builtins.formatting.shellharden,
				null_ls.builtins.formatting.shfmt,

				-- Diagnostics
				null_ls.builtins.diagnostics.golangci_lint,
				null_ls.builtins.diagnostics.zsh,
				null_ls.builtins.diagnostics.codespell,
				null_ls.builtins.diagnostics.commitlint,
				null_ls.builtins.diagnostics.dotenv_linter,
				null_ls.builtins.diagnostics.fish,
				null_ls.builtins.diagnostics.rubocop,

				-- Code Actions
				null_ls.builtins.code_actions.gomodifytags,
				null_ls.builtins.code_actions.gitsigns,
				null_ls.builtins.code_actions.impl,

				-- completion
				null_ls.builtins.completion.spell,
			},
		})
	end,
}
