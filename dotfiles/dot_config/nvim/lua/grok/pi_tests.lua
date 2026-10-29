local M = {}

local function file_text(path)
	if vim.fn.filereadable(path) ~= 1 then
		return ""
	end
	return table.concat(vim.fn.readfile(path), "\n")
end

function M.test_command(root)
	local pyproject = file_text(root .. "/pyproject.toml")
	local requirements = file_text(root .. "/requirements.txt") .. "\n" .. file_text(root .. "/requirements-dev.txt")
	local python = pyproject ~= "" or vim.fn.filereadable(root .. "/setup.py") == 1 or vim.fn.isdirectory(root .. "/src") == 1
	if python then
		local has_pytest = pyproject:find("pytest", 1, true) or requirements:find("pytest", 1, true)
		local uv = (vim.fn.filereadable(root .. "/uv.lock") == 1 or vim.fn.isdirectory(root .. "/.venv") == 1) and vim.fn.executable("uv") == 1
		local cmd = "python -m pytest"
		if uv and not has_pytest then
			cmd = "uv run --with pytest pytest"
		elseif uv then
			cmd = "uv run pytest"
		end
		if vim.fn.isdirectory(root .. "/src") == 1 and not pyproject:find("pythonpath", 1, true) then
			cmd = "PYTHONPATH=src " .. cmd
		end
		return cmd
	end
	if vim.fn.filereadable(root .. "/go.mod") == 1 then
		return "go test ./..."
	end
	if vim.fn.filereadable(root .. "/package.json") == 1 then
		return "npm test"
	end
	return "python -m pytest"
end

function M.prompt_for(item, command)
	local symbol_kind = item.symbol_kind or "symbol"
	local file = item.target_file or item.file or "unknown"
	local lines = {
		"Add high-quality pytest tests for this " .. symbol_kind .. ": " .. tostring(item.name) .. ".",
		"File: " .. file .. " line " .. tostring(item.line or 1) .. ".",
		"Read that file and the files it imports or calls so the tests match the real behavior.",
		"Use pytest: plain test_ functions and assert. Do not use unittest.TestCase.",
		"Import the package path, never src. or a relative src import.",
		"Each test builds a fresh object. Cover normal behavior, boundaries, and failures. Do not leave empty test files.",
		"If a test file for this symbol already exists, replace it. Call only methods and fields that exist on the implementation. Do not invent constructor arguments or attributes.",
		"Where the target mutates shared state, add a race test that calls it from several threads using threading.Barrier. Assert no exception, no lost update, and a consistent final state. Do not use sleep as the only synchronization.",
		"Write tests only. Do not change production code and do not reimplement a symbol that already exists.",
		"You are not done until this command exits 0 and reports that tests ran. Exit code 5, no tests collected, import errors, and collection errors are failures. If it fails because a test is wrong, fix the test. Do not change production code to make a test pass.",
		"Run: " .. command,
	}
	if item.reason == "test file contains an implementation" then
		lines[#lines + 1] = "This test file contains an implementation. Rewrite " .. tostring(item.file) .. " so it only contains tests."
	end
	return table.concat(lines, "\n")
end

local function is_test_path(path)
	return path:match("^tests?/") ~= nil
		or path:match("/tests?/") ~= nil
		or path:match("test_") ~= nil
		or path:match("_test%.") ~= nil
		or path:match("%.test%.") ~= nil
end

function M.start(project, item)
	if type(project) ~= "table" or not project.root then
		vim.notify("No project root found", vim.log.levels.WARN)
		return
	end
	if type(item) ~= "table" or not item.name then
		vim.notify("Missing test target", vim.log.levels.ERROR)
		return
	end
	local command = M.test_command(project.root)
	require("grok.pi_job").start({
		root = project.root,
		name = item.name,
		prefix = "grok-tests",
		title = "Writing tests",
		prompt = M.prompt_for(item, command),
		start_message = "Pi is writing tests for " .. item.name .. " in the background",
		fail_message = "Pi could not write tests for " .. item.name,
		on_success = function(_, _, files)
			local tests = {}
			for _, path in ipairs(files or {}) do
				if is_test_path(path) then
					tests[#tests + 1] = path
				end
			end
			if #tests == 0 then
				vim.notify("Pi finished for " .. item.name .. " but no test files changed.", vim.log.levels.WARN)
				return
			end
			vim.notify("Pi wrote tests for " .. item.name .. ": " .. table.concat(tests, ", ") .. ". Running " .. command, vim.log.levels.INFO)
			vim.system({ "bash", "-lc", command }, { cwd = project.root, text = true }, function(result)
				vim.schedule(function()
					local detail = vim.trim(result.stdout or result.stderr or "")
					if #detail > 500 then
						detail = detail:sub(#detail - 499)
					end
					if result.code == 0 then
						vim.notify("Tests passed for " .. item.name .. "\n" .. detail, vim.log.levels.INFO)
					else
						vim.notify("Tests failed for " .. item.name .. " (exit " .. tostring(result.code) .. ")\n" .. detail, vim.log.levels.ERROR)
					end
				end)
			end)
		end,
	})
end

return M
