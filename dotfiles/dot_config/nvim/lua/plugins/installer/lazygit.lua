--[[
-- File: lazygit.lua
-- Description: LazyGit view plugin from inside neovim.
-- See: https://github.com/kdheepak/lazygit.nvim
--]]

return {
	"kdheepak/lazygit.nvim",
	-- optional for floating window border decoration
	dependencies = {
		"nvim-lua/plenary.nvim",
	},

	cmd = {
		"LazyGit",
		"LazyGitConfig",
		"LazyGitCurrentFile",
		"LazyGitFilter",
		"LazyGitFilterCurrentFile",
	},
}
