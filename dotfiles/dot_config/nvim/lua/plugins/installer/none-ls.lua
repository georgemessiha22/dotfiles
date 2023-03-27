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
				null_ls.builtins.formatting.autopep8,
				-- null_ls.builtins.formatting.gofumpt,
				-- null_ls.builtins.formatting.goimports_reviser,
				null_ls.builtins.formatting.rubocop,
				null_ls.builtins.formatting.ruff,
				null_ls.builtins.formatting.rustfmt,
				null_ls.builtins.formatting.sqlfmt,
				null_ls.builtins.formatting.taplo,
				null_ls.builtins.formatting.shellharden,
				null_ls.builtins.formatting.shfmt,
				null_ls.builtins.formatting.beautysh,

				-- Diagnostics
				null_ls.builtins.diagnostics.golangci_lint,
				-- null_ls.builtins.diagnostics.gospel,
				-- null_ls.builtins.diagnostics.gitlint,
				null_ls.builtins.diagnostics.shellcheck,
				null_ls.builtins.diagnostics.yamllint,
				null_ls.builtins.diagnostics.ruff,
				null_ls.builtins.diagnostics.zsh,

				-- Code Actions
				null_ls.builtins.code_actions.gomodifytags,
				null_ls.builtins.code_actions.gitsigns,
				null_ls.builtins.code_actions.impl,
				null_ls.builtins.code_actions.shellcheck,

				-- completion
				null_ls.builtins.completion.spell,
			},
		})
	end,
}
