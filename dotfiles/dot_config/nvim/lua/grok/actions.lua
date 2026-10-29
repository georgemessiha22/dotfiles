local map = require("grok.project_map")
local auth = require("grok.auth")

local M = {}
local ns = vim.api.nvim_create_namespace("grok-project-map")
local client_name = "grok-project-map"
local attached = {}

local function model()
	return vim.g.grok_implement_model or vim.g.grok_completion_model or vim.env.GROK_COMPLETION_MODEL or "grok-4.20-non-reasoning"
end

local function severity_name(severity)
	if severity == vim.diagnostic.severity.ERROR then
		return "ERROR"
	end
	if severity == vim.diagnostic.severity.WARN then
		return "WARN"
	end
	return "INFO"
end

local function lsp_diagnostics(bufnr, line)
	local found = {}
	for _, diagnostic in ipairs(vim.diagnostic.get(bufnr)) do
		local relevant = diagnostic.namespace ~= ns
			and (diagnostic.severity == vim.diagnostic.severity.ERROR or diagnostic.severity == vim.diagnostic.severity.WARN)
		if relevant and (line == nil or diagnostic.lnum == line) then
			found[#found + 1] = diagnostic
		end
	end
	table.sort(found, function(a, b)
		if a.lnum == b.lnum then
			return a.col < b.col
		end
		return a.lnum < b.lnum
	end)
	return found
end

local function lsp_action(title, scope)
	return {
		title = title,
		kind = "quickfix",
		command = {
			title = title,
			command = "grok.fix_lsp",
			arguments = { { scope = scope } },
		},
	}
end

local function relative_path(bufnr, project)
	local name = vim.api.nvim_buf_get_name(bufnr)
	if not project or name == "" then
		return ""
	end
	local prefix = project.root .. "/"
	local normalized = vim.fs.normalize(name)
	if vim.startswith(normalized, prefix) then
		return normalized:sub(#prefix + 1)
	end
	return ""
end

local function cursor_test_item(bufnr, cursor_line)
	if cursor_line == nil then
		return nil
	end
	local project = map.get(bufnr)
	if not project or not project.symbols then
		return nil
	end
	local relative = relative_path(bufnr, project)
	if relative == "" or relative:match("^tests?/") then
		return nil
	end
	local lnum = cursor_line + 1
	local best
	for _, symbol in ipairs(project.symbols) do
		local covers = symbol.file == relative
			and (symbol.kind == "class" or symbol.kind == "function")
			and symbol.line
			and symbol.line <= lnum
			and lnum <= (symbol.last or symbol.line)
		if covers and (not best or symbol.line > best.line) then
			best = symbol
		end
	end
	if not best or best.name:match("^test_") or best.name:match("^[Tt]est") then
		return nil
	end
	return {
		file = best.file,
		path = project.root .. "/" .. best.file,
		name = best.name,
		kind = "tests",
		symbol_kind = best.kind,
		line = best.line,
		reason = "missing tests",
		title = "Grok: add tests for " .. best.name,
		target_file = best.file,
	}
end

local function actions_for(bufnr, params)
	local items = map.for_buffer(bufnr)
	local actions = {}
	local seen = {}
	local name = vim.api.nvim_buf_get_name(bufnr):lower()
	if name:match("readme%.md$") then
		actions[#actions + 1] = {
			title = "Grok: outline architecture in this README",
			kind = "quickfix",
			command = {
				title = "Grok: outline architecture in this README",
				command = "grok.outline_readme",
				arguments = { { bufnr = bufnr } },
			},
		}
	end
	local diagnostics = lsp_diagnostics(bufnr)
	if #diagnostics > 0 then
		actions[#actions + 1] = lsp_action(
			string.format("Grok: fix all %d LSP errors and warnings", #diagnostics),
			"buffer"
		)
	end
	local cursor_line = params and params.range and params.range.start and params.range.start.line
	if cursor_line then
		local on_line = lsp_diagnostics(bufnr, cursor_line)
		if #on_line > 0 and #on_line < #diagnostics then
			actions[#actions + 1] = lsp_action(
				string.format("Grok: fix %d LSP issue%s on this line", #on_line, #on_line == 1 and "" or "s"),
				"line"
			)
		end
	end
	local cursor_tests = cursor_test_item(bufnr, cursor_line)
	if cursor_tests then
		local key = cursor_tests.title .. ":" .. cursor_tests.file .. ":" .. tostring(cursor_tests.line)
		seen[key] = true
		actions[#actions + 1] = {
			title = cursor_tests.title,
			kind = "quickfix",
			command = {
				title = cursor_tests.title,
				command = "grok.add_tests",
				arguments = { cursor_tests },
			},
		}
	end
	for _, item in ipairs(items) do
		local key = item.title .. ":" .. item.file .. ":" .. tostring(item.line)
		if not seen[key] and #actions < 14 then
			seen[key] = true
			local command_name = item.kind == "tests" and "grok.add_tests" or "grok.implement"
			actions[#actions + 1] = {
				title = item.title,
				kind = "quickfix",
				command = {
					title = item.title,
					command = command_name,
					arguments = { item },
				},
			}
		end
	end
	return actions
end

local function refresh_diagnostics(bufnr)
	local items = map.for_buffer(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	local relative = ""
	local project = map.get(bufnr)
	if project and name ~= "" then
		local prefix = project.root .. "/"
		local normalized = vim.fs.normalize(name)
		if vim.startswith(normalized, prefix) then
			relative = normalized:sub(#prefix + 1)
		end
	end
	local diagnostics = {}
	for _, item in ipairs(items) do
		if item.file == relative and item.line then
			diagnostics[#diagnostics + 1] = {
				lnum = item.line - 1,
				col = 0,
				severity = vim.diagnostic.severity.HINT,
				source = "grok-project-map",
				message = "Not implemented: " .. item.name .. " (" .. item.reason .. "). Use gra or <leader>gra.",
			}
		end
	end
	vim.diagnostic.set(ns, bufnr, diagnostics)
end

local function rpc()
	local closing = false
	return {
		request = function(method, params, callback)
			if method == "initialize" then
				callback(nil, {
					capabilities = {
						codeActionProvider = true,
					},
					serverInfo = { name = client_name, version = "0.1" },
				})
			elseif method == "textDocument/codeAction" then
				local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
				callback(nil, actions_for(bufnr, params))
			elseif method == "shutdown" then
				callback(nil, nil)
			else
				callback(nil, nil)
			end
			return true, 1
		end,
		notify = function()
			return true
		end,
		is_closing = function()
			return closing
		end,
		terminate = function()
			closing = true
		end,
	}
end

local function strip_fences(text)
	text = text:gsub("^%s*```[%w_+%-]*%s*\n", "")
	text = text:gsub("\n```%s*$", "")
	text = text:gsub("^%s*```[%w_+%-]*", "")
	text = text:gsub("```%s*$", "")
	return text
end

local function generate(prompt, callback, opts)
	opts = opts or {}
	local token = auth.token()
	if not token then
		callback(nil, auth.error() or "No Pi xAI login")
		return
	end
	local body = vim.json.encode({
		model = model(),
		temperature = 0.2,
		max_tokens = opts.max_tokens or 700,
		messages = {
			{
				role = "system",
				content = opts.system
					or "You implement one missing piece of an existing project. Follow SOLID, TDD, DRY, and KISS. Match the project's style. Return only code, no markdown fences, no commentary.",
			},
			{ role = "user", content = prompt },
		},
	})
	local tmp = vim.fn.tempname()
	vim.fn.writefile({ body }, tmp)
	vim.system({
		"curl",
		"-sS",
		"--max-time",
		tostring(opts.timeout or 25),
		"https://api.x.ai/v1/chat/completions",
		"-H",
		"Authorization: Bearer " .. token,
		"-H",
		"Content-Type: application/json",
		"--data-binary",
		"@" .. tmp,
	}, { text = true }, function(result)
		vim.uv.fs_unlink(tmp)
		vim.schedule(function()
			if result.code ~= 0 then
				callback(nil, "Grok request failed")
				return
			end
			local ok, decoded = pcall(vim.json.decode, result.stdout or "")
			local content = ok and decoded.choices and decoded.choices[1] and decoded.choices[1].message and decoded.choices[1].message.content
			if type(content) ~= "string" or content == "" then
				callback(nil, "Grok returned no code")
				return
			end
			callback(strip_fences(content))
		end)
	end)
end

local function diagnostic_line(bufnr, diagnostic, file)
	local start_line = diagnostic.lnum + 1
	local start_col = diagnostic.col + 1
	local location = string.format("%s:%d:%d", file, start_line, start_col)
	if diagnostic.end_lnum then
		location = string.format("%s-%d:%d", location, diagnostic.end_lnum + 1, (diagnostic.end_col or 0) + 1)
	end
	local code = diagnostic.code
	if type(code) == "table" then
		code = code.value or code.code
	end
	local header = string.format(
		"- %s [%s] %s%s: %s",
		location,
		severity_name(diagnostic.severity),
		diagnostic.source or "lsp",
		code and (" (" .. tostring(code) .. ")") or "",
		diagnostic.message
	)
	local source = vim.api.nvim_buf_get_lines(bufnr, diagnostic.lnum, diagnostic.lnum + 1, false)[1]
	if source and source ~= "" then
		return header .. "\n  source: " .. source
	end
	return header
end

function M.lsp_prompt(bufnr, line, scope)
	local diagnostics = lsp_diagnostics(bufnr, line)
	if #diagnostics == 0 then
		return nil
	end
	local project = map.get(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	local file = relative_path(bufnr, project)
	if file == "" then
		file = name
	end
	local listed = {}
	for _, diagnostic in ipairs(diagnostics) do
		listed[#listed + 1] = diagnostic_line(bufnr, diagnostic, file)
	end
	local instructions = {
		"Fix the listed LSP errors and warnings in " .. file .. ".",
		"Read that file and whatever it imports. Edit that file. Edit another file only when a diagnostic cannot be cleared otherwise.",
		"Change only what these diagnostics require and any other new diagnostic appears after applying the fix. Do not refactor, reimplement, or add tests.",
	}
	if scope == "line" and line ~= nil then
		instructions[#instructions + 1] = "Clear only the diagnostics on line " .. tostring(line + 1) .. ". Leave every other issue alone."
	end
	return table.concat({
		table.concat(instructions, "\n"),
		"",
		"Diagnostics:",
		table.concat(listed, "\n"),
	}, "\n")
end

function M.fix_lsp(opts)
	opts = opts or {}
	local bufnr = vim.api.nvim_get_current_buf()
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then
		vim.notify("Write the buffer to a file before asking Pi to fix LSP diagnostics", vim.log.levels.WARN)
		return
	end
	if vim.api.nvim_get_option_value("modified", { buf = bufnr }) then
		vim.notify("Write the buffer first so Pi and the diagnostics see the same file", vim.log.levels.WARN)
		return
	end
	local line = nil
	if opts.scope == "line" then
		line = vim.api.nvim_win_get_cursor(0)[1] - 1
	end
	local diagnostics = lsp_diagnostics(bufnr, line)
	if #diagnostics == 0 then
		vim.notify("No LSP errors or warnings to fix", vim.log.levels.INFO)
		return
	end
	local project = map.get(bufnr)
	local root = project and project.root or vim.fs.dirname(name)
	local file = relative_path(bufnr, project)
	if file == "" then
		file = vim.fs.basename(name)
	end
	local prompt = M.lsp_prompt(bufnr, line, opts.scope)
	require("grok.pi_job").start({
		root = root,
		name = file,
		prefix = "grok-lsp",
		prompt = prompt,
		start_message = string.format("Pi is fixing %d LSP diagnostic%s in the background", #diagnostics, #diagnostics == 1 and "" or "s"),
		fail_message = "Pi could not fix the LSP diagnostics",
		on_success = function()
			vim.cmd("checktime")
			local left = #lsp_diagnostics(bufnr, opts.scope == "line" and line or nil)
			vim.notify(
				string.format("Pi finished the LSP fix for %s. %d error%s and warning%s still listed. Review before saving.", file, left, left == 1 and "" or "s", left == 1 and "" or "s"),
				left == 0 and vim.log.levels.INFO or vim.log.levels.WARN
			)
		end,
	})
end

local architecture_start = "<!-- grok:architecture -->"
local architecture_end = "<!-- /grok:architecture -->"

local function is_readme(bufnr)
	return vim.api.nvim_buf_get_name(bufnr):lower():match("readme%.md$") ~= nil
end

function M.needs_architecture(bufnr)
	if not is_readme(bufnr) then
		return false
	end
	local text = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
	return not text:find("grok:architecture", 1, true)
end

function M.outline_readme(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not is_readme(bufnr) then
		vim.notify("Open a README.md to outline the architecture", vim.log.levels.WARN)
		return
	end
	local project = map.get(bufnr)
	local current = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
	local prompt = table.concat({
		project and project.text or "New project. No code has been implemented yet.",
		"",
		"Current README:",
		current == "" and "(empty)" or current,
		"",
		"Write the architecture section for this README.",
		"Return only markdown, starting with " .. architecture_start .. " and ending with " .. architecture_end .. ".",
		"Keep the user's goal. Do not repeat the existing title outside the markers.",
		"Use checkbox points. Mark a point [x] only when the project map already has a real implementation; otherwise [ ].",
		"For a new project, spell out what to implement and how, in build order.",
		"Follow clean architecture: entities, use cases, repository ports, adapters, and delivery. Keep it as small as the README goal allows.",
		"SOLID and TDD are mandatory. Each behavior point names the single responsibility, the dependency direction, and the failing test to write first.",
		"Include the target path for each new file or folder. Do not reimplement items listed as Implemented.",
	}, "\n")
	vim.notify("Grok is outlining the architecture in README.md", vim.log.levels.INFO)
	generate(prompt, function(text, err)
		if not vim.api.nvim_buf_is_valid(bufnr) then
			return
		end
		if not text then
			vim.notify(err or "Grok could not outline the architecture", vim.log.levels.ERROR)
			return
		end
		text = text:gsub("^%s*```[%w_+%-]*%s*\n", ""):gsub("\n```%s*$", "")
		if not text:find("grok:architecture", 1, true) then
			text = architecture_start .. "\n" .. text .. "\n" .. architecture_end
		end
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local joined = table.concat(lines, "\n")
		local start_at = joined:find(architecture_start, 1, true)
		local end_at = start_at and joined:find(architecture_end, start_at, true)
		if start_at and end_at then
			local before = joined:sub(1, start_at - 1):gsub("%s*$", "")
			local after = joined:sub(end_at + #architecture_end):gsub("^%s*", "")
			joined = before .. (before == "" and "" or "\n\n") .. vim.trim(text) .. (after == "" and "" or "\n\n" .. after)
		else
			joined = joined:gsub("%s*$", "")
			joined = (joined == "" and "" or joined .. "\n\n") .. vim.trim(text) .. "\n"
		end
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(joined, "\n", { plain = true }))
		map.invalidate()
		vim.notify("Architecture outline written into README.md. Review it before saving.", vim.log.levels.INFO)
	end, {
		max_tokens = 2500,
		timeout = 45,
		system = "You write a concise README architecture checklist for a clean-architecture application. SOLID and TDD are mandatory. Return markdown only, no surrounding commentary.",
	})
end

function M.add_tests(item)
	local project = map.get(0)
	if not project then
		vim.notify("No project root found", vim.log.levels.WARN)
		return
	end
	require("grok.pi_tests").start(project, item)
end

function M.implement(item)
	if type(item) ~= "table" then
		vim.notify("Missing project-map target", vim.log.levels.ERROR)
		return
	end
	if item.kind == "tests" then
		M.add_tests(item)
		return
	end
	if item.kind == "delegate" then
		require("grok.apply").replace_with_import(item)
		map.invalidate()
		refresh_diagnostics(vim.api.nvim_get_current_buf())
		return
	end
	local project = map.get(0)
	if not project then
		vim.notify("No project root found", vim.log.levels.WARN)
		return
	end
	local prompt = table.concat({
		project.text,
		"",
		"Implement only this remaining item: " .. item.name .. " (" .. item.reason .. ").",
		"Return JSON only, with complete file contents. Do not return a fragment to append.",
		'{"files":[{"path":"relative/path.py","content":"full file"}]}',
		"Create missing folders by using the full relative path.",
		"Keep clean architecture: entities, repositories, and services stay in their existing packages.",
		"Do not create or modify files under test/ or tests/. A separate action writes tests.",
		"Never copy an implementation into a test file, and never reimplement a symbol listed as Implemented.",
		"If a stub duplicates an existing class, replace that stub file with imports instead of rewriting the class.",
	}, "\n")
	vim.notify("Grok is preparing files for " .. item.name, vim.log.levels.INFO)
	generate(prompt, function(text, err)
		if not text then
			vim.notify(err or "Grok implementation failed", vim.log.levels.ERROR)
			return
		end
		local apply = require("grok.apply")
		local plan = apply.parse_plan(text)
		if not plan then
			vim.notify("Grok did not return a file plan, so nothing was inserted", vim.log.levels.ERROR)
			return
		end
		local production = { files = {} }
		local skipped_tests = false
		for _, file in ipairs(plan.files or {}) do
			local path = type(file.path) == "string" and file.path or ""
			if path:match("^tests?/") or path:match("/tests?/") or path:match("test_") or path:match("_test%.") or path:match("%.test%.") then
				skipped_tests = true
			else
				production.files[#production.files + 1] = file
			end
		end
		local written = apply.write_plan(project.root, production)
		if skipped_tests then
			M.add_tests({
				name = item.name,
				symbol_kind = item.kind,
				file = item.file,
				target_file = item.target_file or item.file,
				line = item.line,
				reason = item.reason,
			})
		end
		if #written == 0 then
			if not skipped_tests then
				vim.notify("Grok's file plan had no usable files", vim.log.levels.WARN)
			end
			return
		end
		map.invalidate()
		vim.cmd.edit(project.root .. "/" .. written[1])
		refresh_diagnostics(vim.api.nvim_get_current_buf())
		vim.notify("Wrote " .. table.concat(written, ", ") .. ". Review before saving.", vim.log.levels.INFO)
	end, {
		max_tokens = 4096,
		timeout = 45,
		system = "You create or replace whole production files for one missing piece of a clean-architecture project. Return JSON only. Do not create or modify test files. Never append a second copy of existing code.",
	})
end

function M.attach(bufnr)
	local root = map.root(bufnr)
	if not root then
		return
	end
	local id = vim.lsp.start({
		name = client_name,
		cmd = rpc,
		root_dir = root,
		commands = {
			["grok.implement"] = function(command)
				local item = command.arguments and command.arguments[1]
				M.implement(item)
			end,
			["grok.add_tests"] = function(command)
				local item = command.arguments and command.arguments[1]
				M.add_tests(item)
			end,
			["grok.fix_lsp"] = function(command)
				local args = command.arguments and command.arguments[1] or {}
				M.fix_lsp(args)
			end,
			["grok.outline_readme"] = function(command)
				local args = command.arguments and command.arguments[1] or {}
				M.outline_readme(args.bufnr)
			end,
		},
	}, { bufnr = bufnr })
	if id then
		attached[bufnr] = id
		refresh_diagnostics(bufnr)
	end
end

function M.refresh(bufnr)
	map.invalidate()
	refresh_diagnostics(bufnr)
end

return M
