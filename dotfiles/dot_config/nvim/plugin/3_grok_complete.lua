-- Cursor-style ghost text from Grok, authenticated with Pi's xAI OAuth login.
-- Suggestions include the nearest README.md so completions follow the project.

local project_map = require("grok.project_map")
local grok_actions = require("grok.actions")
local token_script = vim.fn.stdpath("config") .. "/scripts/pi-xai-token.mjs"
local readme_names = { "README.md", "README.markdown", "Readme.md", "readme.md" }
local readme_max_chars = 6000
local readme_cache = { path = nil, mtime = nil, text = "" }
local token_cache = { access = nil, expires = 0 }
local token_error = nil

local function redact(text)
	return (text or ""):gsub("eyJ[%w_%-]+%.[%w_%-]+%.[%w_%-]+", "[redacted-token]")
end

local function unix_ms()
	local sec, usec = vim.uv.gettimeofday()
	return sec * 1000 + math.floor(usec / 1000)
end

local function pi_xai_token()
	if token_cache.access and unix_ms() + 60000 < token_cache.expires then
		return token_cache.access
	end

	if vim.fn.executable("node") ~= 1 then
		token_error = "node is not on PATH; cannot read Pi's xAI login"
		return nil
	end

	local result = vim.system({ "node", token_script }, { text = true }):wait(20000)
	if result.code ~= 0 then
		token_cache.access = nil
		token_error = redact(vim.trim((result.stderr or "") .. (result.stdout or "")))
		if token_error == "" then
			token_error = "Pi xAI token helper exited " .. tostring(result.code)
		end
		return nil
	end

	local meta_line, access = (result.stdout or ""):match("^(.-)\n(.+)$")
	local ok, meta = pcall(vim.json.decode, meta_line or "")
	if not ok or type(meta) ~= "table" or type(access) ~= "string" or access == "" then
		token_cache.access = nil
		token_error = "Pi xAI token helper returned an unexpected payload"
		return nil
	end

	token_cache.access = access
	token_cache.expires = tonumber(meta.expires) or 0
	token_error = nil
	return access
end

local function project_readme()
	local name = vim.api.nvim_buf_get_name(0)
	local start = name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()
	if not start or start == "" then
		return ""
	end

	local found = vim.fs.find(readme_names, { path = start, upward = true, type = "file", limit = 1 })[1]
	if not found then
		return ""
	end
	if name ~= "" and vim.fs.normalize(found) == vim.fs.normalize(name) then
		return ""
	end

	local stat = vim.uv.fs_stat(found)
	local mtime = stat and (stat.mtime.sec + stat.mtime.nsec / 1e9) or 0
	if readme_cache.path == found and readme_cache.mtime == mtime then
		return readme_cache.text
	end

	local ok, lines = pcall(vim.fn.readfile, found, "", 250)
	if not ok then
		return ""
	end
	local text = table.concat(lines, "\n")
	if #text > readme_max_chars then
		text = text:sub(1, readme_max_chars) .. "\n[README truncated]"
	end
	readme_cache.path = found
	readme_cache.mtime = mtime
	readme_cache.text = text
	return text
end

local function project_context()
	local parts = {}
	local file = vim.api.nvim_buf_get_name(0)
	if file ~= "" then
		table.insert(parts, "Current file: " .. file)
	end
	local readme = project_readme()
	if readme ~= "" then
		table.insert(
			parts,
			"Project README.md (use this to infer what the user is about to write; do not repeat it):\n" .. readme
		)
	else
		table.insert(parts, "No project README.md was found.")
	end
	local map_ok, map = pcall(project_map.get, 0)
	if map_ok and map and map.text ~= "" then
		table.insert(parts, map.text)
	end
	return table.concat(parts, "\n")
end

local function strip_fences(text)
	if type(text) ~= "string" then
		return text
	end
	text = text:gsub("^%s*```[%w_+%-]*%s*\n", "")
	text = text:gsub("\n```%s*$", "")
	text = text:gsub("^%s*```[%w_+%-]*", "")
	text = text:gsub("```%s*$", "")
	return text
end

local function install_fence_filter()
	local common = require("minuet.backends.common")
	if common._grok_fence_filter then
		return
	end
	local original = common.parse_completion_items
	common.parse_completion_items = function(items_raw, provider)
		return original(strip_fences(items_raw), provider)
	end
	common._grok_fence_filter = true
end

local function ghost_highlight()
	vim.api.nvim_set_hl(0, "MinuetVirtualText", { fg = "#8b93a7", italic = true })
end

local function setup_minuet()
	local ok, minuet = pcall(require, "minuet")
	if not ok then
		vim.notify("minuet-ai.nvim is not installed yet. Restart Neovim to finish installing Grok autocomplete.", vim.log.levels.WARN)
		return
	end

	local defaults = require("minuet.config")
	-- grok-code-fast-1 only streams reasoning tokens, which never appear as ghost text.
	local model = vim.g.grok_completion_model or vim.env.GROK_COMPLETION_MODEL or "grok-4.20-non-reasoning"
	install_fence_filter()
	ghost_highlight()
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("GrokGhostText", { clear = true }),
		callback = ghost_highlight,
	})

	minuet.setup({
		provider = "openai_compatible",
		n_completions = 1,
		context_window = 12000,
		context_ratio = 0.75,
		throttle = 800,
		debounce = 300,
		request_timeout = 8,
		notify = "warn",
		virtualtext = {
			auto_trigger_ft = { "*" },
			auto_trigger_ignore_ft = {
				"help",
				"qf",
				"terminal",
				"prompt",
				"TelescopePrompt",
				"snacks_picker_input",
				"snacks_input",
				"Avante",
				"AvanteInput",
				"AvantePromptInput",
				"codecompanion",
				"minifiles",
				"gitcommit",
				"gitrebase",
			},
			-- Keep ghost text visible while blink.cmp's menu is open.
			show_on_completion_menu = true,
			keymap = {
				accept = "<C-g><C-y>",
				accept_line = "<M-l>",
				accept_n_lines = "<M-L>",
				next = "<M-]>",
				prev = "<M-[>",
				dismiss = "<M-e>",
			},
		},
		provider_options = {
			openai_compatible = {
				model = model,
				name = "Grok",
				end_point = "https://api.x.ai/v1/chat/completions",
				api_key = pi_xai_token,
				stream = true,
				system = {
					prompt = function()
						return defaults.default_system_prefix_first.prompt
							.. "\n\nSuggest only the next missing piece at the cursor. Never repeat an implemented symbol. "
							.. "If the cursor is on pass or NotImplementedError, return only the replacement for that stub. "
							.. "Do not emit a second copy of an existing function or class. Never wrap the completion in markdown fences. "
						.. "Follow the existing package layout, clean architecture, and TDD. "
						.. "Do not reimplement anything listed as implemented."
					end,
				},
				chat_input = {
					template = "{{{language}}}\n{{{tab}}}\n{{{project}}}\n<contextBeforeCursor>\n{{{context_before_cursor}}}<cursorPosition>\n<contextAfterCursor>\n{{{context_after_cursor}}}",
					project = function()
						return project_context()
					end,
				},
				optional = {
					max_tokens = 192,
					temperature = 0.2,
				},
			},
		},
		enable_predicates = {
			function()
				return pi_xai_token() ~= nil
			end,
		},
	})

	-- Terminals send Tab and <C-i> as the same key. GogoNvim binds insert <C-i> to
	-- vim.lsp.buf.implementation on LspAttach, which overwrites this mapping.
	local function accept_or_tab()
		local vt_ok, vt = pcall(require, "minuet.virtualtext")
		if vt_ok and vt.action.is_visible() then
			if not require("grok.apply").accept_ghost() then
				vt.action.accept()
			end
			return ""
		end
		local ls_ok, ls = pcall(require, "luasnip")
		if ls_ok and ls.jumpable(1) then
			ls.jump(1)
			return ""
		end
		-- Literal tab. Returning "<Tab>" would invoke the <C-i> implementation map.
		return "\t"
	end

	local function map_tab()
		local opts = {
			expr = true,
			silent = true,
			desc = "Accept Grok suggestion or insert tab",
		}
		-- Physical Tab is delivered as <C-i> unless the terminal uses the kitty protocol.
		vim.keymap.set("i", "<C-i>", accept_or_tab, opts)
		vim.keymap.set("i", "<Tab>", accept_or_tab, opts)
	end

	map_tab()
	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("GrokTab", { clear = true }),
		callback = function()
			-- Run after GogoNvim's LspAttach, which rebinds <C-i> to implementation.
			vim.schedule(map_tab)
		end,
	})

	vim.api.nvim_create_user_command("GrokComplete", function()
		require("minuet.virtualtext").action.next()
	end, { desc = "Request a Grok ghost-text suggestion" })

	vim.api.nvim_create_user_command("GrokCompleteToggle", function()
		require("minuet.virtualtext").action.toggle_auto_trigger()
	end, { desc = "Toggle automatic Grok ghost text" })

	vim.api.nvim_create_user_command("GrokCompleteAuth", function()
		token_cache.access = nil
		local access = pi_xai_token()
		if access then
			vim.notify("Grok autocomplete is using Pi's xAI login", vim.log.levels.INFO)
		else
			vim.notify(token_error or "Could not read Pi's xAI login", vim.log.levels.ERROR)
		end
	end, { desc = "Check Pi xAI login used by Grok autocomplete" })

	vim.schedule(function()
		pi_xai_token()
	end)

	local ignored_ft = {
		help = true,
		qf = true,
		terminal = true,
		prompt = true,
		TelescopePrompt = true,
		snacks_picker_input = true,
	}
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
		group = vim.api.nvim_create_augroup("GrokProjectMap", { clear = true }),
		callback = function(args)
			if args.event == "BufWritePost" then
				project_map.invalidate()
			end
			if ignored_ft[vim.bo[args.buf].filetype] or vim.api.nvim_buf_get_name(args.buf) == "" then
				return
			end
			grok_actions.attach(args.buf)
			local readme = vim.api.nvim_buf_get_name(args.buf):lower():match("readme%.md$")
			if args.event == "BufEnter" and readme and grok_actions.needs_architecture(args.buf) and not vim.b[args.buf].grok_outline_started then
				local current = project_map.get(args.buf)
				local thin = #vim.api.nvim_buf_get_lines(args.buf, 0, -1, false) <= 20
				local fresh = not current or #current.implemented <= 2
				if thin or fresh then
					vim.b[args.buf].grok_outline_started = true
					vim.schedule(function()
						if vim.api.nvim_buf_is_valid(args.buf) then
							grok_actions.outline_readme(args.buf)
						end
					end)
				end
			end
		end,
	})
	vim.api.nvim_create_user_command("GrokOutline", function()
		grok_actions.outline_readme(0)
	end, { desc = "Write the Grok architecture outline into README.md" })
	vim.keymap.set({ "n", "x" }, "<leader>gra", function()
		grok_actions.attach(0)
		vim.lsp.buf.code_action()
	end, { desc = "Grok and LSP code actions" })
	vim.api.nvim_create_user_command("GrokProjectMap", function()
		local current = project_map.get(0)
		vim.notify(current and current.text or "No project map", vim.log.levels.INFO)
	end, { desc = "Show the extracted project map" })
end

setup_minuet()
