local M = {}

local jobs = {}
local BAR_WIDTH = 20

local function slug(name)
	local cleaned = string.lower(name or "task"):gsub("[^%w]+", "-"):gsub("^-+", ""):gsub("-+$", "")
	cleaned = cleaned:sub(1, 32)
	if cleaned == "" then
		return "task"
	end
	return cleaned
end

local function tail(text, limit)
	text = vim.trim(text or "")
	if #text <= limit then
		return text
	end
	return text:sub(#text - limit + 1)
end

function M.new_state()
	return {
		pending = "",
		completed = 0,
		settled = false,
		label = "starting",
		edited = {},
		assistant = "",
	}
end

local function tool_args(event)
	local args = event.args
	if type(args) == "string" then
		local ok, decoded = pcall(vim.json.decode, args)
		if ok and type(decoded) == "table" then
			return decoded
		end
		return {}
	end
	if type(args) == "table" then
		return args
	end
	return {}
end

local function tool_label(event)
	local name = event.toolName or "tool"
	local args = tool_args(event)
	local command = args.command
	if type(command) == "string" and (command:find("unittest", 1, true) or command:find("pytest", 1, true)) then
		return "running tests"
	end
	if type(args.path) == "string" and args.path ~= "" then
		return name .. " " .. args.path
	end
	if type(command) == "string" and command ~= "" then
		command = command:gsub("%s+", " ")
		if #command > 42 then
			command = command:sub(1, 39) .. "..."
		end
		return name .. " " .. command
	end
	return name
end

function M.progress_lines(completed, settled, label)
	local filled = settled and BAR_WIDTH or math.min(completed or 0, BAR_WIDTH - 1)
	local bar = "[" .. string.rep("#", filled) .. string.rep(".", BAR_WIDTH - filled) .. "]"
	local text = label or "starting"
	if #text > 46 then
		text = text:sub(1, 43) .. "..."
	end
	return { bar, text }
end

local function apply_event(state, event)
	if type(event) ~= "table" then
		return
	end
	if event.type == "tool_execution_start" or event.type == "tool_execution_end" then
		state.label = tool_label(event)
	end
	if event.type == "tool_execution_end" then
		state.completed = state.completed + 1
		if not event.isError and (event.toolName == "edit" or event.toolName == "write") then
			local path = tool_args(event).path
			if type(path) == "string" and path ~= "" then
				state.edited[path] = true
			end
		end
	elseif event.type == "agent_settled" then
		state.settled = true
		state.label = "done"
	elseif event.type == "message_end" and type(event.message) == "table" and event.message.role == "assistant" then
		local content = event.message.content
		if type(content) == "string" then
			state.assistant = content
		elseif type(content) == "table" then
			local parts = {}
			for _, block in ipairs(content) do
				if type(block) == "table" and block.type == "text" and type(block.text) == "string" then
					parts[#parts + 1] = block.text
				end
			end
			if #parts > 0 then
				state.assistant = table.concat(parts, "\n")
			end
		end
	end
end

function M.ingest(state, chunk)
	state.pending = (state.pending or "") .. (chunk or "")
	while true do
		local nl = state.pending:find("\n", 1, true)
		if not nl then
			break
		end
		local line = state.pending:sub(1, nl - 1):gsub("\r$", "")
		state.pending = state.pending:sub(nl + 1)
		if line ~= "" then
			local ok, decoded = pcall(vim.json.decode, line)
			if ok then
				apply_event(state, decoded)
			end
		end
	end
end

function M.finish_pending(state)
	if state.pending and state.pending ~= "" then
		M.ingest(state, "\n")
	end
end

function M.porcelain_path(line)
	local path = line:match("^.. (.+)$")
	if not path then
		return nil
	end
	path = path:match("^.+ %-> (.+)$") or path
	if path:sub(1, 1) == '"' then
		path = path:sub(2, -2):gsub('\\"', '"')
	end
	return path
end

function M.union_files(root, before, porcelain, edited)
	local seen = {}
	local files = {}
	local prefix = vim.fs.normalize(root) .. "/"
	local function add(path)
		if type(path) ~= "string" or path == "" then
			return
		end
		local full = path
		if not path:match("^/") then
			full = root .. "/" .. path
		end
		full = vim.fs.normalize(full)
		if not vim.startswith(full, prefix) then
			return
		end
		local rel = full:sub(#prefix + 1)
		if rel == "" or seen[rel] then
			return
		end
		seen[rel] = true
		files[#files + 1] = rel
	end
	for path in pairs(edited or {}) do
		add(path)
	end
	for line in (porcelain or ""):gmatch("[^\n]+") do
		if not before[line] then
			add(M.porcelain_path(line))
		end
	end
	table.sort(files)
	return files
end

local function load_buffers(root, files)
	vim.cmd("checktime")
	local loaded = {}
	for _, rel in ipairs(files) do
		local full = vim.fs.normalize(root .. "/" .. rel)
		if vim.fn.filereadable(full) == 1 then
			local buf = vim.fn.bufadd(full)
			vim.bo[buf].buflisted = true
			vim.fn.bufload(buf)
			loaded[#loaded + 1] = rel
		end
	end
	return loaded
end

local function open_progress(title)
	local width = math.min(48, math.max(24, vim.o.columns - 2))
	if vim.o.columns < 24 or vim.o.lines < 4 then
		return nil, nil
	end
	local ok, buf = pcall(vim.api.nvim_create_buf, false, true)
	if not ok then
		return nil, nil
	end
	vim.bo[buf].bufhidden = "wipe"
	local win_ok, win = pcall(vim.api.nvim_open_win, buf, false, {
		relative = "editor",
		anchor = "SE",
		width = width,
		height = 2,
		row = math.max(1, vim.o.lines - 3),
		col = vim.o.columns - 1,
		focusable = false,
		style = "minimal",
		border = "rounded",
		title = " " .. (title or "Pi") .. " ",
		noautocmd = true,
	})
	if not win_ok then
		return buf, nil
	end
	return buf, win
end

local function update_progress(buf, completed, settled, label, title)
	local lines = M.progress_lines(completed, settled, label)
	pcall(vim.api.nvim_echo, { { (title or "Pi") .. " " .. lines[1] .. " " .. lines[2], "ModeMsg" } }, false, {})
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

local function close_progress(win)
	if win and vim.api.nvim_win_is_valid(win) then
		pcall(vim.api.nvim_win_close, win, true)
	end
end

local function git_status(root, callback)
	vim.system({ "git", "status", "--porcelain", "-uall" }, { cwd = root, text = true }, function(status)
		local lines = {}
		local text = ""
		if status.code == 0 then
			text = status.stdout or ""
			for line in text:gmatch("[^\n]+") do
				lines[line] = true
			end
		end
		vim.schedule(function()
			callback(lines, text)
		end)
	end)
end

function M.start(opts)
	opts = opts or {}
	if type(opts.root) ~= "string" or opts.root == "" then
		vim.notify("No project root found", vim.log.levels.WARN)
		return
	end
	if type(opts.prompt) ~= "string" or opts.prompt == "" then
		vim.notify("Missing Pi prompt", vim.log.levels.ERROR)
		return
	end
	if jobs[opts.root] then
		vim.notify("Pi is already working in this project", vim.log.levels.WARN)
		return
	end
	if vim.fn.exepath("pi") == "" then
		vim.notify("pi is not on PATH, so the request was not started", vim.log.levels.ERROR)
		return
	end

	jobs[opts.root] = true
	local name = opts.name or "task"
	local prefix = opts.prefix or "grok"
	local id = string.format("%s-%s-%d", prefix, slug(name), os.time())
	local cmd = {
		"pi",
		"--mode",
		"json",
		"--approve",
		"--no-plan",
		"--session-id",
		id,
		"--name",
		prefix .. "-" .. slug(name),
		opts.prompt,
	}
	local root = opts.root

	local function launch(before)
		local state = M.new_state()
		local stderr = ""
		local title = opts.title or "Pi"
		local buf, win = open_progress(title)
		update_progress(buf, 0, false, "starting", title)
		vim.notify((opts.start_message or ("Pi is working on " .. name)) .. " (" .. id .. ")", vim.log.levels.INFO)
		local function finish(result)
			jobs[root] = nil
			M.finish_pending(state)
			update_progress(buf, state.completed, true, state.label, title)
			close_progress(win)
			if result.code ~= 0 then
				vim.notify(
					(opts.fail_message or ("Pi could not finish " .. name))
						.. " (exit "
						.. tostring(result.code)
						.. "). Resume with pi --session-id "
						.. id
						.. "\n"
						.. tail(stderr ~= "" and stderr or state.assistant, 600),
					vim.log.levels.ERROR
				)
				return
			end
			git_status(root, function(_, porcelain)
				local files = M.union_files(root, before or {}, porcelain, state.edited)
				local loaded = load_buffers(root, files)
				if #loaded > 0 then
					vim.notify("Pi edited " .. table.concat(loaded, ", ") .. ". Loaded as buffers. Review before saving.", vim.log.levels.INFO)
				end
				if opts.on_success then
					opts.on_success({
						code = result.code,
						stdout = state.assistant,
						stderr = stderr,
					}, id, loaded)
				end
			end)
		end
		local ok, job = pcall(vim.system, cmd, {
			cwd = root,
			stdout = function(_, data)
				if not data or data == "" then
					return
				end
				vim.schedule(function()
					M.ingest(state, data)
					update_progress(buf, state.completed, state.settled, state.label, title)
				end)
			end,
			stderr = function(_, data)
				if data then
					stderr = stderr .. data
				end
			end,
		}, function(result)
			vim.schedule(function()
				finish(result)
			end)
		end)
		if not ok then
			jobs[root] = nil
			close_progress(win)
			vim.notify("Could not start Pi: " .. tostring(job), vim.log.levels.ERROR)
			return
		end
		jobs[root] = job
	end

	git_status(root, function(before)
		if jobs[root] then
			launch(before)
		end
	end)
end

return M
