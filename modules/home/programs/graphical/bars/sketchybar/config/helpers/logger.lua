#!/usr/bin/env lua

local LEVELS = {
	off = 0,
	error = 1,
	warn = 2,
	info = 3,
	debug = 4,
	trace = 5,
}

local function _normalize_level(value, fallback)
	if value == nil then
		return fallback
	end
	local normalized = string.lower(tostring(value))
	return LEVELS[normalized] and normalized or fallback
end

local function _coalesce(value, fallback)
	if value == nil or value == "" then
		return fallback
	end
	return value
end

local function _shell_quote(value)
	local text = tostring(value or "")
	return "'" .. text:gsub("'", [['"'"']]) .. "'"
end

local home_dir = _coalesce(os.getenv("HOME"), os.getenv("USERPROFILE") or "/tmp")
local default_log_file = home_dir .. "/Library/Logs/sketchybar/sketchybar.out.log"
local default_error_log_file = home_dir .. "/Library/Logs/sketchybar/sketchybar.err.log"
local log_file = _coalesce(os.getenv("SKETCHYBAR_LOG_FILE"), default_log_file)
local error_log_file = _coalesce(os.getenv("SKETCHYBAR_ERROR_LOG_FILE"), default_error_log_file)
local active_level = LEVELS[_normalize_level(os.getenv("SKETCHYBAR_LOG_LEVEL"), "info")] or LEVELS.info

local flush_seconds = tonumber(os.getenv("SKETCHYBAR_LOG_FLUSH_SECONDS")) or 1.0
local max_buffer_size = tonumber(os.getenv("SKETCHYBAR_LOG_MAX_BUFFER_SIZE")) or 80
local buffer_state = {}
local prepared_directories = {}
local directory_prepare_error = {}
local flush_scheduled = false

local function _ensure_log_directory(path)
	if path == nil or path == "" then
		return
	end
	if prepared_directories[path] or directory_prepare_error[path] then
		return
	end

	local dir = string.match(path, "^(.*)/[^/]+$")
	if dir == nil or dir == "" then
		return
	end

	local command = "mkdir -p " .. _shell_quote(dir)
	local ok = os.execute(command)
	if ok ~= true and ok ~= 0 then
		directory_prepare_error[path] = true
	end
	prepared_directories[path] = true
end

local function _buffer_for(path)
	local state = buffer_state[path]
	if state == nil then
		state = {
			entries = {},
			indexes = {},
		}
		buffer_state[path] = state
	end
	return state
end

local function _total_buffered_entries()
	local total = 0
	for _, state in pairs(buffer_state) do
		total = total + #state.entries
	end
	return total
end

local function _target_file(level)
	if level == LEVELS.error then
		return error_log_file
	end
	return log_file
end

local function _flush_buffer_for_file(path, state)
	if #state.entries == 0 then
		return
	end

	_ensure_log_directory(path)

	local output_lines = {}
	local total_entries = #state.entries
	for index = 1, total_entries do
		local entry = state.entries[index]
		if entry.count > 1 then
			table.insert(output_lines, entry.line .. " count=" .. tostring(entry.count))
		else
			table.insert(output_lines, entry.line)
		end
	end

	state.entries = {}
	state.indexes = {}

	local handle, err = io.open(path, "a")
	if handle == nil then
		if err and os.getenv("SKETCHYBAR_LOG_STDERR_FALLBACK") == "1" then
			io.stderr:write("logger: failed to open log file " .. tostring(path) .. ": " .. tostring(err) .. "\n")
		end
		return
	end
	handle:write(table.concat(output_lines, "\n"), "\n")
	handle:close()
end

local function _escape_value(value)
	local text = tostring(value)
	if string.find(text, "[ %z\001-\031\"'\\]") then
		return string.format("%q", text)
	end
	return text
end

local function _format_line(level, module_name, event, fields)
	local parts = {
		"timestamp=" .. os.date("!%Y-%m-%dT%H:%M:%SZ"),
		"level=" .. level,
		"module=" .. tostring(module_name),
		"event=" .. tostring(event),
	}

	local sorted_keys = {}
	for key in pairs(fields or {}) do
		table.insert(sorted_keys, key)
	end
	table.sort(sorted_keys)
	for _, key in ipairs(sorted_keys) do
		local value = fields[key]
		table.insert(parts, tostring(key) .. "=" .. _escape_value(value))
	end

	return table.concat(parts, " ")
end

local function _flush_buffer()
	if _total_buffered_entries() == 0 then
		return
	end

	for path, state in pairs(buffer_state) do
		if #state.entries > 0 then
			_flush_buffer_for_file(path, state)
		end
	end
end

local function _schedule_flush()
	if flush_scheduled then
		return
	end
	flush_scheduled = true
	Sbar.delay(flush_seconds, function()
		flush_scheduled = false
		_flush_buffer()
		if _total_buffered_entries() > 0 then
			_schedule_flush()
		end
	end)
end

local function _emit(level, module_name, event, fields)
	if level == nil or level > active_level then
		return
	end

	local path = _target_file(level)
	local state = _buffer_for(path)
	local count = state.indexes
	local line = _format_line(level, module_name, event, fields)
	local existing_index = count[line]
	if existing_index ~= nil then
		state.entries[existing_index].count = state.entries[existing_index].count + 1
	else
		table.insert(state.entries, { line = line, count = 1 })
		count[line] = #state.entries
	end

	if #state.entries >= max_buffer_size then
		_flush_buffer_for_file(path, state)
		if _total_buffered_entries() > 0 then
			_schedule_flush()
		end
	else
		_schedule_flush()
	end
end

local logger = {}

local function _log_fn(level_name, module_name, event, fields)
	local level = LEVELS[level_name]
	if level == nil then
		level = LEVELS.info
	end
	_emit(level, module_name or "unknown", event or "event", fields)
end

for name, level_value in pairs(LEVELS) do
	if level_value > 0 then
		logger[name] = function(module_name, event, fields)
			_log_fn(name, module_name, event, fields)
		end
	end
end

function logger.flush()
	_flush_buffer()
end

function logger.set_level(level)
	active_level = LEVELS[_normalize_level(level, "info")] or LEVELS.info
end

function logger.set_file(path)
	local previous = log_file
	log_file = _coalesce(path, default_log_file)
	prepared_directories[previous] = nil
	directory_prepare_error[previous] = nil
end

function logger.set_error_file(path)
	local previous = error_log_file
	error_log_file = _coalesce(path, default_error_log_file)
	prepared_directories[previous] = nil
	directory_prepare_error[previous] = nil
end

return logger
