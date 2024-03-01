--[[
  File: mason.lua
  Description: Mason plugin configuration (with lspconfig)
  See: https://github.com/williamboman/mason.nvim
]]

-- Mason {{{
return {
	"williamboman/mason.nvim",
	build = ":MasonUpdate",
	dependencies = {
		{ "VonHeikemen/lsp-zero.nvim", branch = "v3.x" },
		"williamboman/mason-lspconfig.nvim",
		"neovim/nvim-lspconfig",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		{ "j-hui/fidget.nvim",         opt = {} },
	},
	config = function()
		local lsp_zero = require("lsp-zero")
		lsp_zero.extend_lspconfig()

		lsp_zero.on_attach(function(client, bufnr)
			-- see :help lsp-zero-keybindings
			-- to learn the available actions
			lsp_zero.default_keymaps({ buffer = bufnr })
		end)
		local mason = require("mason")
		local mason_lspconfig = require("mason-lspconfig")
		local lspconfig = require("lspconfig")
		local icons = require("config").icons

		mason.setup({
			ui = {
				icons = {
					package_installed = icons.misc.Package,
					package_pending = icons.kind.Property,
					package_uninstalled = icons.ui.BoldClose,
				},
			},
		})
		mason_lspconfig.setup({
			ensure_installed = {
				"lua_ls",                      -- LSP for Lua language
				"tsserver",                    -- LSP for Typescript and Javascript
				"emmet_ls",                    -- LSP for Emmet (Vue, HTML, CSS)
				"cssls",                       -- LSP for CSS
				"ruff_lsp",                    -- LSP for Python
				"gopls",                       -- LSP for Go
				"svelte",                      -- LSP for Svelte
				"tailwindcss",                 -- LSP for TailWindCss
				"marksman",                    -- LSP for Markdown
				"dockerls",                    -- LSP for Dockerfile
				"docker_compose_language_service", -- LSP for Docker-compose
				"bashls",                      -- LSP for Bash
				"denols",                      -- LSP for deno
				"yamlls",                      -- LSP yaml
				-- "rust_analyzer", -- LSP Rust rust_analyzer, disable if rustacean enabled
				"jsonls",                      -- LSP json
				"html",                        -- LSP html
				"eslint",                      -- LSP eslint
				"pyright",                     -- LSP python
				"texlab",
				"taplo",                       -- LSP TOML
			},
		})

		mason_lspconfig.setup_handlers({
			function(server_name)
				if server_name == "gopls" then
					lspconfig.gopls.setup({
						capabilities = lsp_zero.get_capabilities(),
						filetypes = { "go", "gomod" },
						fillstruct = "gopls",
						settings = {
							gopls = {
								analyses = {
									unusedparams = true,
								},
								staticcheck = true,
								gofumpt = true,
								buildFlags = { "-tags=functional,integration,unit" },
							},
						},
					})
				elseif server_name == "lua_ls" then
					-- skip
				else
					require('lsp-zero.server').setup(server_name, { capabilities = lsp_zero.get_capabilities() })
				end
			end,
		})


		-- auto installer {{{
		require("mason-tool-installer").setup({
			ensure_installed = {
				"lua-language-server", -- LSP Lua
				"luacheck",
				"misspell",
				"revive",
				"latexindent",
				"ts-standard",
				"bash-debug-adapter",
				"go-debug-adapter",
				"js-debug-adapter",
				"node-debug2-adapter",

				-- Formatters
				"stylua",
				"autopep8",
				"gofumpt",
				"golangci-lint",
				"goimports",
				"rubocop",
				"ruff",
				"sqlfmt",
				"yamllint",
				"jsonlint",
				"shellharden",
				"shfmt",
				"beautysh",
				-- "rustywind", -- TailWindCss
				"shfmt",
				"shellcheck",
				"markdownlint",
			},
			auto_update = true,
			run_on_start = true,
			start_delay = 3000,
			debounce_hours = 24,
		})
		-- }}}

		require("config").load_mapping("lspconfig")
	end,
}
-- }}}
