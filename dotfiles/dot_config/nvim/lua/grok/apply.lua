local M = {}

local function stub_line(line)
	local body = vim.trim(line or "")
	return body == "pass"
		or body == "..."
		or body:match("^raise NotImplementedError")
		or body:match("^raise%s+NotImplementedError")
end

local function header(line)
	return line:match("^%s*def%s+")
		or line:match("^%s*async%s+def%s+")
		or line:match("^%s*class%s+")
		or line:match("^%s*function%s+")
		or line:match("^%s*func%s+")
end

function M.ghost_text()
	local ns = vim.api.nvim_get_namespaces()["minuet.virtualtext"]
	if not ns then
		return nil
	end
	local mark = vim.api.nvim_buf_get_extmark_by_id(0, ns, 1, { details = true })
	local details = mark and mark[3]
	if not details then
		return nil
	end
	local lines = {}
	if details.virt_text and details.virt_text[1] then
		lines[1] = details.virt_text[1][1] or ""
	end
	for _, virt in ipairs(details.virt_lines or {}) do
		lines[#lines + 1] = virt[1] and virt[1][1] or ""
	end
	if #lines == 0 then
		return nil
	end
	return table.concat(lines, "\n")
end

local function dismiss()
	pcall(function()
		require("minuet.virtualtext").action.dismiss()
	end)
end

local function symbol_covering(bufnr, lnum)
	local project = require("grok.project_map").get(bufnr)
	if not project then
		return nil
	end
	local name = vim.api.nvim_buf_get_name(bufnr)
	local prefix = project.root .. "/"
	local normalized = vim.fs.normalize(name)
	local relative = vim.startswith(normalized, prefix) and normalized:sub(#prefix + 1) or name
	local best
	local function consider(item)
		if item.file == relative and item.line and item.line <= lnum and lnum <= (item.last or item.line) then
			if not best or item.line > best.line then
				best = item
			end
		end
	end
	for _, item in ipairs(project.implemented) do
		consider(item)
	end
	for _, item in ipairs(project.remaining) do
		consider(item)
	end
	return best
end

function M.replace_lines(bufnr, start_line, end_line, text)
	local lines = type(text) == "table" and text or vim.split(text, "\n", { plain = true })
	if #lines > 0 and lines[#lines] == "" then
		table.remove(lines)
	end
	vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, lines)
end

function M.accept_ghost()
	local text = M.ghost_text()
	if not text or vim.trim(text) == "" then
		return false
	end
	local bufnr = vim.api.nvim_get_current_buf()
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local current = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
	local buffer = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
	if buffer:find(vim.trim(text), 1, true) then
		dismiss()
		vim.notify("Skipped a Grok suggestion that is already in this file", vim.log.levels.INFO)
		return true
	end

	local symbol = symbol_covering(bufnr, lnum)
	local suggestion = vim.split(text, "\n", { plain = true })
	local first = vim.trim(suggestion[1] or "")
	local suggested_name = first:match("def%s+([%w_]+)") or first:match("class%s+([%w_]+)")
	local same_symbol = symbol and suggested_name and symbol.name == suggested_name
	local replacing = stub_line(current) or (symbol and (symbol.kind == "stub" or symbol.kind == "delegate")) or same_symbol
	if replacing then
		local start_line = lnum
		local end_line = lnum
		if symbol and symbol.line and (same_symbol or symbol.kind == "delegate" or header(first)) then
			start_line = symbol.line
			end_line = symbol.last or symbol.line
		elseif stub_line(current) then
			start_line = lnum
			end_line = lnum
		elseif symbol and symbol.line then
			start_line = math.min(symbol.line + 1, symbol.last or symbol.line)
			end_line = symbol.last or symbol.line
		end
		if #suggestion == 0 then
			dismiss()
			return true
		end
		M.replace_lines(bufnr, start_line, end_line, suggestion)
		dismiss()
		return true
	end
	return false
end

local function safe_path(root, relative)
	if type(relative) ~= "string" or relative == "" or relative:find("^/") or relative:find("%.%.") then
		return nil
	end
	local path = vim.fs.normalize(root .. "/" .. relative)
	local prefix = vim.fs.normalize(root) .. "/"
	if not vim.startswith(path, prefix) then
		return nil
	end
	return path
end

function M.parse_plan(text)
	text = text:gsub("^%s*```[%w_+%-]*%s*\n", ""):gsub("\n```%s*$", "")
	local ok, decoded = pcall(vim.json.decode, text)
	if ok and type(decoded) == "table" and type(decoded.files) == "table" then
		return decoded
	end
	local start_at = text:find("{", 1, true)
	if not start_at then
		return nil
	end
	for i = #text, start_at, -1 do
		if text:sub(i, i) == "}" then
			local chunk = text:sub(start_at, i)
			local parsed_ok, parsed = pcall(vim.json.decode, chunk)
			if parsed_ok and type(parsed) == "table" and type(parsed.files) == "table" then
				return parsed
			end
			break
		end
	end
	return nil
end

function M.write_plan(root, plan)
	local written = {}
	for _, file in ipairs(plan.files or {}) do
		local path = safe_path(root, file.path)
		if path and type(file.content) == "string" then
			vim.fn.mkdir(vim.fs.dirname(path), "p")
			local lines = vim.split(file.content:gsub("\n$", ""), "\n", { plain = true })
			vim.fn.writefile(lines, path)
			written[#written + 1] = file.path
		end
	end
	return written
end

function M.module_name(file)
	local module = file:gsub("^src/", ""):gsub("%.py$", ""):gsub("/__init__$", ""):gsub("/", ".")
	return module
end

function M.replace_with_import(item)
	local project = require("grok.project_map").get(0)
	if not project or not item.target_file or not item.path then
		vim.notify("No existing implementation to import", vim.log.levels.WARN)
		return
	end
	vim.cmd.edit(item.path)
	local bufnr = vim.api.nvim_get_current_buf()
	M.replace_lines(bufnr, item.line, item.last or item.line, {})
	local import_line = string.format("from %s import %s", M.module_name(item.target_file), item.name)
	if not table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n"):find(import_line, 1, true) then
		vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, { import_line, "" })
	end
	vim.notify("Replaced stub " .. item.name .. " with an import. Review before saving.", vim.log.levels.INFO)
end

return M
