local M = {}

local token_script = vim.fn.stdpath("config") .. "/scripts/pi-xai-token.mjs"
local cache = { access = nil, expires = 0 }
local last_error = nil

local function redact(text)
	return (text or ""):gsub("eyJ[%w_%-]+%.[%w_%-]+%.[%w_%-]+", "[redacted-token]")
end

local function unix_ms()
	local sec, usec = vim.uv.gettimeofday()
	return sec * 1000 + math.floor(usec / 1000)
end

function M.error()
	return last_error
end

function M.token()
	if cache.access and unix_ms() + 60000 < cache.expires then
		return cache.access
	end
	if vim.fn.executable("node") ~= 1 then
		last_error = "node is not on PATH; cannot read Pi's xAI login"
		return nil
	end

	local result = vim.system({ "node", token_script }, { text = true }):wait(20000)
	if result.code ~= 0 then
		cache.access = nil
		last_error = redact(vim.trim((result.stderr or "") .. (result.stdout or "")))
		if last_error == "" then
			last_error = "Pi xAI token helper exited " .. tostring(result.code)
		end
		return nil
	end

	local meta_line, access = (result.stdout or ""):match("^(.-)\n(.+)$")
	local ok, meta = pcall(vim.json.decode, meta_line or "")
	if not ok or type(meta) ~= "table" or type(access) ~= "string" or access == "" then
		cache.access = nil
		last_error = "Pi xAI token helper returned an unexpected payload"
		return nil
	end

	cache.access = access
	cache.expires = tonumber(meta.expires) or 0
	last_error = nil
	return access
end

function M.clear()
	cache.access = nil
	cache.expires = 0
end

return M
