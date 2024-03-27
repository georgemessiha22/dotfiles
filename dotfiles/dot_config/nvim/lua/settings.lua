--[[
  File: settings.lua
  Description: Base settings for neovim
  Info: Use <zo> and <zc> to open and close foldings
]]

local cmd = vim.cmd -- Command function
local g = vim.g -- Vim globals
local opt = vim.opt -- Vim optionals

local config = require("config")

-------------------------------------- globals -----------------------------------------
cmd("color " .. config.ui.theme)

vim.notify = require("notify")

g.mapleader = config.ui.leader
g.toggle_theme_icon = "   "
g.neon_transparent = config.ui.transparency
g.neon_style = config.ui.theme_toggle[1]
vim.guifont = config.ui.font

-------------------------------------- options ------------------------------------------
opt.laststatus = 2 -- global statusline
opt.showmode = true
opt.termguicolors = config.ui.termguicolors
opt.colorcolumn = "140"

-- Clipboard {{{
-- opt.clipboard = 'unnamedplus' -- Use system clipboard
opt.fixeol = false -- Turn off appending new line in the end of a file
opt.cursorline = true
-- }}}

-- Indenting {{{
opt.expandtab = false
opt.shiftwidth = 2
opt.smartindent = true
opt.tabstop = 2
opt.softtabstop = 2

opt.fillchars = { eob = " " }
opt.ignorecase = true
opt.smartcase = true
opt.mouse = "a"
-- }}}

-- Folding {{{
opt.foldmethod = "indent"
opt.foldlevelstart = 99
-- opt.foldexpr = "nvim_treesitter#foldexpr()"

-- }}}

-- Numbers {{{
opt.relativenumber = true
opt.number = true
opt.numberwidth = 4
opt.ruler = true
-- }}}

-- Search {{{
opt.ignorecase = true -- Ignore case if all characters in lower case
opt.joinspaces = false -- Join multiple spaces in search
opt.smartcase = true -- When there is a one capital letter search for exact match
opt.showmatch = true -- Highlight search instances
-- }}}

-- Window {{{
opt.splitbelow = true -- Put new windows below current
opt.splitright = true -- Put new vertical splits to right
-- }}}

-- Wild Menu {{{
opt.wildmenu = true
opt.wildmode = "longest:full,full"
-- }}}

-- disable nvim intro
-- opt.shortmess:append "sI"

opt.signcolumn = "yes"
opt.splitbelow = true
opt.splitright = true
opt.termguicolors = true
opt.timeoutlen = 500
opt.undofile = true

-- disable nvim default complete
-- vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- interval for writing swap file to disk, also used by gitsigns
opt.updatetime = 250

-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
opt.whichwrap:append("<>[]hl")

-- disable some default providers {{{
for _, provider in ipairs({ "perl", "ruby" }) do
	g["loaded_" .. provider .. "_provider"] = 0
end
-- }}}

-- add binaries installed by mason.nvim to path
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

-------------------------------------- autocmds ------------------------------------------
local autocmd = vim.api.nvim_create_autocmd
local format_sync_grp = vim.api.nvim_create_augroup("Format", {})
-- format on save all files
autocmd("BufWritePre", {
	pattern = "*",
	-- exclude = { "*.rb" },
	callback = function()
		--    vim.notify("Formatter")
		-- Never request solargaph for formatting
		vim.lsp.buf.format({
			filter = function(client)
				return client.name ~= "solargraph"
			end,
		})
	end,
	group = format_sync_grp,
})

-- autocmd("BufWritePost", {
-- 	pattern = "*.go",
-- 	callback = function()
-- 		vim.notify("PostWrite", vim.log.levels.WARN, {})
-- 	end,
-- 	group = format_sync_grp,
-- })
-- dont list quickfix buffers
-- autocmd("FileType", {
-- 	pattern = "qf",
-- 	callback = function()
-- 		vim.opt_local.buflisted = false
-- 	end,
-- })

-- reload some options on-save
autocmd("BufWritePost", {
	pattern = vim.tbl_map(function(path)
		return vim.fs.normalize(vim.loop.fs_realpath(path))
	end, vim.fn.glob(vim.fn.stdpath("config") .. "/lua/*.lua", true, true, true)),
	group = vim.api.nvim_create_augroup("ReloadConfig", {}),

	callback = function(opts)
		local fp = vim.fn.fnamemodify(vim.fs.normalize(vim.api.nvim_buf_get_name(opts.buf)), ":r") --[[@as string]]
		local app_name = vim.env.NVIM_APPNAME and vim.env.NVIM_APPNAME or "nvim"

		local module = string.gsub(fp, "^.*/" .. app_name .. "/lua/", ""):gsub("/", ".")
		-- vim.notify(vim.inspect(module))

		require("plenary.reload").reload_module(module)

		require("config").load_config()

		vim.cmd("redraw!")
	end,
})

-- Default Plugins {{{
local disabled_built_ins = {
	--	"netrw",
	--	"netrwPlugin",
	--	"netrwSettings",
	--	"netrwFileHandlers",
	"gzip",
	"zip",
	"zipPlugin",
	"tar",
	"tarPlugin",
	"getscript",
	"getscriptPlugin",
	"vimball",
	"vimballPlugin",
	-- "2html_plugin",
	-- "logipat",
	"rrhelper",
	-- "spellfile_plugin",
	-- "matchit",
}

for _, plugin in pairs(disabled_built_ins) do
	g["loaded_" .. plugin] = 1
end
-- }}}
