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

local function _positive_number(value, fallback)
	local parsed = tonumber(value)
	if parsed == nil or parsed <= 0 then
		return fallback
	end
	return parsed
end

local function _positive_integer(value, fallback)
	local parsed = tonumber(value)
	if parsed == nil or parsed < 1 then
		return fallback
	end
	return math.floor(parsed)
end

local function _escape_value(value)
	local text = tostring(value)
	if string.find(text, "[ %z\001-\031\"'\\]") then
		return string.format("%q", text)
	end
	return text
end

local function _emit_line(level_name, module_name, event, fields)
	local parts = {
		"timestamp=" .. os.date("!%Y-%m-%dT%H:%M:%SZ"),
		"level=" .. tostring(level_name),
		"module=" .. tostring(module_name),
		"event=" .. tostring(event),
	}
	local keys = {}
	for key in pairs(fields or {}) do
		table.insert(keys, key)
	end
	table.sort(keys)
	for _, key in ipairs(keys) do
		table.insert(parts, tostring(key) .. "=" .. _escape_value(fields[key]))
	end

	return table.concat(parts, " ")
end

local function create(options)
	local cfg = options or {}
	local level = _normalize_level(_coalesce(cfg.level, "info"), "info")
	local current_level = level
	local flush_seconds = _positive_number(_coalesce(cfg.flush_seconds, 1.0), 1.0)
	local max_buffer_size = _positive_integer(_coalesce(cfg.max_buffer_size, 80), 80)

	flush_seconds = _positive_number(cfg.env_flush_seconds, flush_seconds)
	max_buffer_size = _positive_integer(cfg.env_max_buffer_size, max_buffer_size)

	local active_level = LEVELS[level] or LEVELS.info
	local stream_state = {
		stdout = { entries = {}, indexes = {} },
		stderr = { entries = {}, indexes = {} },
	}
	local flush_scheduled = false

	local function _should_log(level_name)
		local value = LEVELS[level_name]
		return value ~= nil and value <= active_level
	end

	local function _flush_stream(stream_name)
		local state = stream_state[stream_name]
		if state == nil or #state.entries == 0 then
			return
		end

		local handle = stream_name == "stderr" and io.stderr or io.stdout
		for _, entry in ipairs(state.entries) do
			if entry.count > 1 then
				handle:write(entry.line, " count=", tostring(entry.count), "\n")
			else
				handle:write(entry.line, "\n")
			end
		end
		handle:flush()

		state.entries = {}
		state.indexes = {}
	end

	local function _flush()
		_flush_stream("stdout")
		_flush_stream("stderr")
	end

	local function _schedule_flush()
		if flush_scheduled then
			return
		end
		flush_scheduled = true
		if Sbar and type(Sbar.delay) == "function" then
			Sbar.delay(flush_seconds, function()
				flush_scheduled = false
				_flush()
				if #stream_state.stdout.entries > 0 or #stream_state.stderr.entries > 0 then
					_schedule_flush()
				end
			end)
		else
			flush_scheduled = false
			_flush()
		end
	end

	local function _emit(level_name, line)
		local stream_name = level_name == "error" and "stderr" or "stdout"
		local state = stream_state[stream_name]
		local index = state.indexes[line]

		if index ~= nil then
			state.entries[index].count = state.entries[index].count + 1
			return
		end

		table.insert(state.entries, { line = line, count = 1 })
		state.indexes[line] = #state.entries

		if #state.entries >= max_buffer_size then
			_flush_stream(stream_name)
		else
			_schedule_flush()
		end
	end

	local logger = {
		raw = function(level_name, message)
			local resolved_level = _normalize_level(level_name, "info")
			if not _should_log(resolved_level) then
				return
			end
			_emit(resolved_level, os.date("%Y-%m-%d %H:%M:%S") .. " [" .. resolved_level .. "] " .. tostring(message))
		end,
		debug = function(module_name, event, fields)
			if not _should_log("debug") then
				return
			end
			_emit("debug", _emit_line("debug", module_name or "unknown", event or "event", fields or {}))
		end,
		info = function(module_name, event, fields)
			if not _should_log("info") then
				return
			end
			_emit("info", _emit_line("info", module_name or "unknown", event or "event", fields or {}))
		end,
		warn = function(module_name, event, fields)
			if not _should_log("warn") then
				return
			end
			_emit("warn", _emit_line("warn", module_name or "unknown", event or "event", fields or {}))
		end,
		error = function(module_name, event, fields)
			if not _should_log("error") then
				return
			end
			_emit("error", _emit_line("error", module_name or "unknown", event or "event", fields or {}))
		end,
		flush = _flush,
		set_level = function(level_name)
			local next_level = _normalize_level(level_name, level)
			active_level = LEVELS[next_level] or LEVELS.info
			current_level = next_level
		end,
		set_runtime = function(level_name, next_flush_seconds, next_max_buffer_size)
			local next_level = _normalize_level(_coalesce(level_name, current_level), current_level)
			active_level = LEVELS[next_level] or LEVELS.info
			current_level = next_level
			flush_seconds = _positive_number(next_flush_seconds, flush_seconds)
			max_buffer_size = _positive_integer(next_max_buffer_size, max_buffer_size)
		end,
	}

	return logger
end

return {
	create = create,
}
