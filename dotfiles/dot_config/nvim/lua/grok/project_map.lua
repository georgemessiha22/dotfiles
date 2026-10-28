local M = {}

local SKIP_DIR = {
	[".git"] = true,
	[".venv"] = true,
	venv = true,
	node_modules = true,
	dist = true,
	build = true,
	target = true,
	vendor = true,
	__pycache__ = true,
	[".idea"] = true,
	[".mypy_cache"] = true,
	[".ruff_cache"] = true,
	coverage = true,
}

local CODE_EXT = {
	py = true,
	lua = true,
	go = true,
	rs = true,
	rb = true,
	js = true,
	jsx = true,
	ts = true,
	tsx = true,
	java = true,
	kt = true,
	php = true,
	c = true,
	h = true,
	cpp = true,
	hpp = true,
	cs = true,
	swift = true,
	sql = true,
	proto = true,
	vue = true,
	svelte = true,
}

local ROOT_MARKERS = { ".git", "pyproject.toml", "package.json", "go.mod", "Cargo.toml", "Gemfile", "composer.json" }
local MAX_FILES = 250
local MAX_LINES = 400
local MAX_TEXT = 3500

local cache = { key = nil, map = nil }

local function norm(path)
	return vim.fs.normalize(path)
end

function M.root(bufnr)
	bufnr = bufnr or 0
	local name = vim.api.nvim_buf_get_name(bufnr)
	local start = name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()
	if not start or start == "" then
		return nil
	end
	return vim.fs.root(start, ROOT_MARKERS) or start
end

local function rel(root, path)
	local prefix = norm(root) .. "/"
	path = norm(path)
	if vim.startswith(path, prefix) then
		return path:sub(#prefix + 1)
	end
	return path
end

local function read_lines(path)
	local ok, lines = pcall(vim.fn.readfile, path, "", MAX_LINES)
	if not ok then
		return {}
	end
	return lines
end

local function is_stub_line(line)
	local body = vim.trim(line or "")
	return body == "pass"
		or body == "..."
		or body == "pass  # pragma: no cover"
		or body:match("^raise NotImplementedError")
		or body:match("^raise%s+NotImplementedError")
		or body == "todo!()"
		or body == "unimplemented!()"
		or body == "panic!(\"todo\")"
end

local function indent_of(line)
	return #(line:match("^(%s*)") or "")
end

local function next_symbol_end(lines, index)
	local base = indent_of(lines[index] or "")
	local last = index
	for i = index + 1, #lines do
		local line = lines[i]
		if line:match("%S") and not line:match("^%s*#") and not line:match("^%s*//") then
			local ind = indent_of(line)
			if ind <= base and (line:match("^%s*def ") or line:match("^%s*class ") or line:match("^%s*async%s+def ") or line:match("^%s*function ") or line:match("^%s*func ")) then
				break
			end
			if ind < base then
				break
			end
		end
		last = i
	end
	return last
end

local function body_is_stub(lines, index, last)
	local saw = false
	for i = index + 1, last do
		local line = lines[i]
		local skip = not line:match("%S")
			or line:match("^%s*#")
			or line:match("^%s*//")
			or line:match("^%s*%-%-")
			or line:match('^%s*"""')
			or line:match("^%s*'''")
		if not skip then
			saw = true
			if not is_stub_line(line) and not line:match("^%s*@") then
				return false
			end
		end
	end
	return saw
end

local function add_symbol(symbols, file, kind, name, line, stub, last)
	if not name or name == "" then
		return
	end
	symbols[#symbols + 1] = {
		file = file,
		kind = kind,
		name = name,
		line = line,
		last = last,
		stub = stub,
	}
end

local function scan_file(root, path, symbols, empty_files)
	local ext = path:match("%.([%w]+)$")
	if not ext or not CODE_EXT[ext] then
		return
	end
	local lines = read_lines(path)
	local relative = rel(root, path)
	local nonempty = false
	for _, line in ipairs(lines) do
		if line:match("%S") and not line:match("^%s*#") and not line:match("^%s*//") then
			nonempty = true
			break
		end
	end
	if not nonempty then
		empty_files[#empty_files + 1] = { file = relative, path = path }
		return
	end

	for i, line in ipairs(lines) do
		local class_name = line:match("^%s*class%s+([%w_]+)")
		local fn_name = line:match("^%s*def%s+([%w_]+)")
			or line:match("^%s*async%s+def%s+([%w_]+)")
			or line:match("^%s*function%s+([%w_.:]+)")
			or line:match("^%s*local%s+function%s+([%w_]+)")
			or line:match("^%s*func%s+([%w_]+)")
			or line:match("^%s*fn%s+([%w_]+)")
		local todo = line:match("TODO[:%s]+(.+)") or line:match("FIXME[:%s]+(.+)")
		if class_name or fn_name then
			local last = next_symbol_end(lines, i)
			local stub = body_is_stub(lines, i, last)
			add_symbol(symbols, relative, class_name and "class" or "function", class_name or fn_name, i, stub, last)
		elseif todo then
			add_symbol(symbols, relative, "todo", vim.trim(todo), i, true, i)
		end
	end
end

local function walk(root)
	local symbols = {}
	local empty_files = {}
	local count = 0
	local function scan(dir, depth)
		if depth > 6 or count >= MAX_FILES then
			return
		end
		for name, typ in vim.fs.dir(dir) do
			if count >= MAX_FILES then
				return
			end
			if not SKIP_DIR[name] and not name:match("%.lock$") then
				local path = dir .. "/" .. name
				if typ == "directory" then
					scan(path, depth + 1)
				elseif typ == "file" then
					count = count + 1
					scan_file(root, path, symbols, empty_files)
				end
			end
		end
	end
	scan(root, 0)
	return symbols, empty_files
end

local function readme_items(root)
	local path = root .. "/README.md"
	if vim.fn.filereadable(path) == 0 then
		return {}, ""
	end
	local lines = read_lines(path)
	local items = {}
	for i, line in ipairs(lines) do
		local heading = line:match("^#+%s+(.+)")
		local open_task = line:match("^%s*%- %[ %]%s+(.+)")
		local done_task = line:match("^%s*%- %[[xX]%]%s+(.+)")
		if heading then
			items[#items + 1] = { text = vim.trim(heading), line = i, done = false, kind = "readme" }
		elseif open_task then
			items[#items + 1] = { text = open_task, line = i, done = false, kind = "task" }
		elseif done_task then
			items[#items + 1] = { text = done_task, line = i, done = true, kind = "task" }
		end
	end
	return items, table.concat(lines, "\n")
end

local function tokens(text)
	local out = {}
	for word in string.lower(text or ""):gmatch("[%w]+") do
		if #word > 3 and word ~= "create" and word ~= "this" and word ~= "from" and word ~= "with" then
			out[#out + 1] = word
		end
	end
	return out
end

local function related(item_text, symbol_name)
	local name = string.lower(symbol_name or ""):gsub("_", "")
	local hits = 0
	local words = tokens(item_text)
	if #words == 0 then
		return false
	end
	for _, word in ipairs(words) do
		if name:find(word, 1, true) or word:find(name, 1, true) then
			hits = hits + 1
		end
	end
	return hits > 0
end

local function classify(root, symbols, empty_files, readme)
	local implemented, remaining = {}, {}
	local function push_remaining(item)
		item.id = #remaining + 1
		remaining[#remaining + 1] = item
	end

	local function is_production(symbol)
		local in_tests = symbol.file:match("^tests?/") ~= nil
		if in_tests and not symbol.name:match("^test_") and not symbol.name:match("^[Tt]est") then
			return false
		end
		return true
	end

	local implemented_by_name = {}
	local bad_tests = {}
	for _, symbol in ipairs(symbols) do
		if not symbol.stub and is_production(symbol) then
			implemented[#implemented + 1] = symbol
			implemented_by_name[symbol.name] = implemented_by_name[symbol.name] or symbol
		elseif not symbol.stub and symbol.file:match("^tests?/") and symbol.kind == "class" then
			bad_tests[symbol.file] = symbol
		end
	end
	for file, symbol in pairs(bad_tests) do
		push_remaining({
			file = file,
			path = root .. "/" .. file,
			name = symbol.name,
			kind = "tests",
			line = 1,
			reason = "test file contains an implementation",
			title = "Grok: rewrite " .. file .. " as tests",
			target_file = symbol.file,
		})
	end

	local covered = {}
	for _, class_sym in ipairs(symbols) do
		if class_sym.kind == "class" then
			local methods = {}
			local all_stub = true
			for _, symbol in ipairs(symbols) do
				if symbol.file == class_sym.file and symbol.kind == "function" and symbol.line > class_sym.line and symbol.line <= (class_sym.last or symbol.line) then
					methods[#methods + 1] = symbol
					if not symbol.stub then
						all_stub = false
					end
				end
			end
			local elsewhere = nil
			for _, symbol in ipairs(implemented) do
				if symbol.name == class_sym.name and symbol.file ~= class_sym.file then
					elsewhere = symbol
					break
				end
			end
			if elsewhere and (class_sym.stub or (#methods > 0 and all_stub)) then
				push_remaining({
					file = class_sym.file,
					path = root .. "/" .. class_sym.file,
					name = class_sym.name,
					kind = "delegate",
					line = class_sym.line,
					last = class_sym.last,
					target_file = elsewhere.file,
					reason = "already implemented in " .. elsewhere.file,
					title = "Grok: replace stub " .. class_sym.name .. " with import",
				})
				covered[class_sym.file .. ":" .. class_sym.line] = true
				for _, method in ipairs(methods) do
					covered[method.file .. ":" .. method.line] = true
				end
			end
		end
	end

	local kept = {}
	for _, symbol in ipairs(implemented) do
		if not covered[symbol.file .. ":" .. symbol.line] then
			kept[#kept + 1] = symbol
		end
	end
	implemented = kept

	for _, symbol in ipairs(symbols) do
		if symbol.stub and not covered[symbol.file .. ":" .. symbol.line] then
			local elsewhere = implemented_by_name[symbol.name]
			if elsewhere and elsewhere.file ~= symbol.file then
				push_remaining({
					file = symbol.file,
					path = root .. "/" .. symbol.file,
					name = symbol.name,
					kind = "delegate",
					line = symbol.line,
					last = symbol.last,
					target_file = elsewhere.file,
					reason = "already implemented in " .. elsewhere.file,
					title = "Grok: replace stub " .. symbol.name .. " with import",
				})
			else
				push_remaining({
					file = symbol.file,
					path = root .. "/" .. symbol.file,
					name = symbol.name,
					kind = symbol.kind == "todo" and "todo" or "stub",
					line = symbol.line,
					last = symbol.last,
					reason = symbol.kind == "todo" and "TODO" or "stub",
					title = symbol.kind == "todo" and ("Grok: resolve TODO " .. symbol.name) or ("Grok: implement " .. symbol.name),
				})
			end
		end
	end

	for _, file in ipairs(empty_files) do
		if not file.file:match("__init__%.py$") then
			push_remaining({
				file = file.file,
				path = file.path,
				name = vim.fs.basename(file.file),
				kind = "empty",
				line = 1,
				reason = "empty file",
				title = "Grok: implement empty " .. file.file,
			})
		end
	end

	local tested = {}
	for _, symbol in ipairs(symbols) do
		if symbol.name:match("^test_") or symbol.file:match("^tests?/") and symbol.name:match("^[Tt]est") then
			tested[symbol.file] = true
		end
	end
	for _, symbol in ipairs(implemented) do
		if symbol.kind == "class" and not symbol.file:match("^tests?/") and not symbol.name:match("^[Tt]est") then
			local has_test = false
			for _, other in ipairs(symbols) do
				if other.file:match("^tests?/") and other.name:match("^test_") and not other.stub then
					has_test = true
					break
				end
			end
			if not has_test then
				push_remaining({
					file = symbol.file,
					path = root .. "/" .. symbol.file,
					name = symbol.name,
					kind = "tests",
					line = symbol.line,
					reason = "missing tests",
					title = "Grok: add tests for " .. symbol.name,
					target_file = symbol.file,
				})
				break
			end
		end
	end

	for _, item in ipairs(readme) do
		if not item.done then
			local linked_stub, linked_done
			for _, symbol in ipairs(symbols) do
				if related(item.text, symbol.name) then
					if symbol.stub then
						linked_stub = linked_stub or symbol
					else
						linked_done = linked_done or symbol
					end
				end
			end
			if not linked_done then
				local linked = linked_stub
				push_remaining({
					file = linked and linked.file or "README.md",
					path = linked and (root .. "/" .. linked.file) or (root .. "/README.md"),
					name = item.text,
					kind = linked and "stub" or "readme",
					line = linked and linked.line or item.line,
					last = linked and linked.last or nil,
					reason = "README: " .. item.text,
					title = "Grok: implement README — " .. item.text,
					readme = true,
				})
			end
		end
	end

	return implemented, remaining
end

local function format_map(implemented, remaining)
	local lines = {
		"Project map. Never reimplement an item listed under Implemented.",
		"Replace duplicate stubs with imports. Create missing files and tests instead of appending to an existing stub.",
		"Follow the existing package layout and TDD: tests live under test/ or tests/ and use test_ functions.",
	}
	lines[#lines + 1] = "Remaining:"
	local shown = 0
	for _, item in ipairs(remaining) do
		if shown >= 24 then
			lines[#lines + 1] = "- …"
			break
		end
		shown = shown + 1
		lines[#lines + 1] = string.format("- %s:%s %s (%s)", item.file, tostring(item.line or "?"), item.name, item.reason)
	end
	if shown == 0 then
		lines[#lines + 1] = "- none found"
	end
	lines[#lines + 1] = "Implemented:"
	shown = 0
	for _, item in ipairs(implemented) do
		if shown >= 20 then
			lines[#lines + 1] = "- …"
			break
		end
		shown = shown + 1
		lines[#lines + 1] = string.format("- %s:%s %s", item.file, item.line, item.name)
	end
	if #implemented == 0 then
		lines[#lines + 1] = "- none found"
	end
	local text = table.concat(lines, "\n")
	if #text > MAX_TEXT then
		text = text:sub(1, MAX_TEXT) .. "\n[project map truncated]"
	end
	return text
end

local function cache_key(root)
	local parts = { root }
	local stat = vim.uv.fs_stat(root .. "/README.md")
	parts[#parts + 1] = stat and tostring(stat.mtime.sec) or "0"
	return table.concat(parts, ":")
end

function M.get(bufnr)
	local root = M.root(bufnr)
	if not root then
		return nil
	end
	root = norm(root)
	local key = cache_key(root)
	if cache.key == key and cache.map then
		return cache.map
	end
	local symbols, empty_files = walk(root)
	local readme = readme_items(root)
	local implemented, remaining = classify(root, symbols, empty_files, readme)
	local map = {
		root = root,
		implemented = implemented,
		remaining = remaining,
		text = format_map(implemented, remaining),
	}
	cache.key = key
	cache.map = map
	return map
end

function M.invalidate()
	cache.key = nil
	cache.map = nil
end

function M.for_buffer(bufnr)
	local map = M.get(bufnr)
	if not map then
		return {}
	end
	local name = vim.api.nvim_buf_get_name(bufnr)
	local relative = name ~= "" and rel(map.root, name) or ""
	local items = {}
	for _, item in ipairs(map.remaining) do
		if item.file == relative or item.readme then
			items[#items + 1] = item
		end
	end
	for _, item in ipairs(map.remaining) do
		if item.file ~= relative and not item.readme then
			items[#items + 1] = item
		end
	end
	return items
end

return M
