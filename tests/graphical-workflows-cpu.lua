local root = assert(arg[1])
local loadCpu = dofile(
	root .. "/modules/home/programs/graphical/bars/sketchybar/dynamic-island-sketchybar/lua/islands/cpu_panic.lua"
)
local config = dofile(root .. "/modules/home/programs/graphical/bars/sketchybar/dynamic-island-sketchybar/config.lua")
local clock = 0
rawset(os, "time", function()
	return clock
end)
local noop = function() end

local function process(pid, cpu, name, started)
	return string.format(
		"%d %.1f %s %s",
		pid,
		cpu,
		started or "Sun Oct 11 09:00:00 2026",
		name or "/Applications/Busy App"
	)
end
local busy = process(42, 99.5)
local other = process(43, 110, "/Applications/Other App")

local function monitor(overrides)
	local objects, alerts, commands, logs = {}, {}, {}, {}
	local pending
	local Sbar = {
		add = function(_, name, options)
			local object = { callbacks = {}, label = options.label, drawing = options.drawing }
			function object:set(values)
				for key, value in pairs(values) do
					if type(value) == "table" then
						for field, setting in pairs(value) do
							self[key][field] = setting
						end
					else
						self[key] = value
					end
				end
			end
			function object:subscribe(event, fn)
				self.callbacks[event] = fn
			end
			objects[name] = object
			return object
		end,
		exec = function(command, callback)
			commands[#commands + 1] = command
			if callback then
				pending = callback
			end
		end,
	}
	local ctx = {
		Sbar = Sbar,
		hidePersistentIsland = noop,
		restorePersistentIsland = function()
			return true
		end,
		registry = {},
		islandState = { isSleeping = false },
		layout = config.layout,
		contentYOffset = config.notch.contentYOffset,
		colorWhite = config.colors.white,
		colorTransparent = config.colors.transparent,
		fontFamily = config.main.font,
		get = function(key, fallback)
			if overrides and overrides[key] ~= nil then
				return overrides[key]
			end
			local value = config
			for part in key:gmatch("[^.]+") do
				value = value and value[part]
			end
			if value == nil then
				return fallback
			end
			return value
		end,
		asNumber = function(value)
			return tonumber(value)
		end,
		expandedHalfWidth = function(_, value)
			return value
		end,
		layoutForText = function()
			return { width = 380, margin = 2 }
		end,
		animateIsland = function(value)
			alerts[#alerts + 1] = value
			value.onExpand()
		end,
		logInfo = function(value)
			logs[#logs + 1] = value
		end,
		logDebug = noop,
		subscribeItem = noop,
	}
	clock = 0
	loadCpu(ctx)
	local listener = objects.cpuPanicListener
	local function request(at)
		clock = at
		listener.callbacks.routine()
	end
	local function complete(result, code)
		local callback = assert(pending)
		pending = nil
		callback(result, code or 0)
	end
	local function poll(at, result, code)
		request(at)
		complete(result, code)
	end
	return {
		objects = objects,
		alerts = alerts,
		commands = commands,
		logs = logs,
		ctx = ctx,
		request = request,
		complete = complete,
		poll = poll,
		sustain = function(result, start)
			for at = start or 0, (start or 0) + 120, 30 do
				poll(at, result)
			end
		end,
	}
end

local function check(name, run)
	run()
	print("PASS " .. name)
end

check("brief spikes, threshold boundary, and recovery reset evidence", function()
	local m = monitor()
	m.poll(0, busy)
	m.poll(30, busy)
	m.poll(60, process(42, 90))
	m.poll(90, busy)
	m.poll(120, busy)
	m.poll(150, busy)
	m.poll(180, busy)
	assert(#m.alerts == 0)
	m.poll(210, busy)
	assert(#m.alerts == 1)
end)

check("sustained usage, actionable wording, and once per episode", function()
	local m = monitor()
	m.sustain(busy)
	assert(#m.alerts == 1 and m.alerts[1].owner == "cpu_panic")
	local title = m.objects["island.cpu_panic_text"]
	local detail = m.objects["island.cpu_panic_detail"]
	assert(title.label.string:find("CPU busy: 99.5% | Busy App", 1, true))
	assert(detail.label.string == "PID 42 | high 2m+ | Click: Activity Monitor")
	assert(title.label.color == config.colors.white)
	assert(m.logs[1]:find("one logical core", 1, true))
	title.callbacks["mouse.clicked"]()
	assert(m.commands[#m.commands] == "/usr/bin/open -b com.apple.ActivityMonitor")
	m.alerts[1].onHideContent()
	m.alerts[1].onCleanup()
	assert(not title.drawing and not detail.drawing)
	for at = 150, 2100, 30 do
		m.poll(at, busy)
	end
	assert(#m.alerts == 1, "continuous activity must not generate reminders")
end)

check("alternating leaders retain evidence and share a global cooldown", function()
	local m = monitor()
	for at = 0, 990, 30 do
		local rows = at % 60 == 0 and busy .. "\n" .. other or other .. "\n" .. busy
		m.poll(at, rows)
	end
	assert(#m.alerts == 1)
	assert(m.objects["island.cpu_panic_text"].label.string:find("Other App", 1, true))
	m.poll(1020, busy .. "\n" .. other)
	assert(#m.alerts == 2)
	assert(m.objects["island.cpu_panic_text"].label.string:find("Busy App", 1, true))
	for at = 1050, 2100, 30 do
		m.poll(at, other .. "\n" .. busy)
	end
	assert(#m.alerts == 2)
end)

check("alternating short-lived activity never shares a sustained streak", function()
	local m = monitor()
	for at = 0, 600, 30 do
		m.poll(at, at % 60 == 0 and busy or other)
	end
	assert(#m.alerts == 0)
end)

check("recovery rearms only after sustaining again and respecting cooldown", function()
	local m = monitor()
	m.sustain(busy)
	m.poll(150, process(42, 0))
	for at = 180, 990, 30 do
		m.poll(at, busy)
	end
	assert(#m.alerts == 1)
	m.poll(1020, busy)
	assert(#m.alerts == 2)
end)

check("process restarts, same names, and reused PIDs do not inherit evidence", function()
	local m = monitor()
	m.poll(0, busy)
	m.poll(30, busy)
	m.poll(60, busy)
	local restarted = process(42, 99.5, nil, "Sun Oct 11 09:01:00 2026")
	m.poll(90, restarted)
	m.poll(120, restarted)
	m.poll(150, restarted)
	m.poll(180, restarted)
	assert(#m.alerts == 0)
	m.poll(210, restarted)
	assert(#m.alerts == 1)
	-- A new PID with the same command is a new episode, but cannot bypass cooldown.
	local newPid = process(44, 99.5)
	for at = 240, 1080, 30 do
		m.poll(at, newPid)
	end
	assert(#m.alerts == 1)
	m.poll(1110, newPid)
	assert(#m.alerts == 2)
end)

check("missing processes, failed samples, polling gaps, and clock reversal reset evidence", function()
	for _, failure in ipairs({ "missing", "error", "malformed", "delayed", "backwards" }) do
		local m = monitor()
		m.poll(0, busy)
		m.poll(30, busy)
		m.poll(60, busy)
		local start = 120
		if failure == "missing" then
			m.poll(90, process(43, 0))
		elseif failure == "error" then
			m.poll(90, busy, 1)
		elseif failure == "malformed" then
			m.poll(90, "bad row")
		elseif failure == "delayed" then
			start = 300
		else
			start = 0
		end
		m.poll(start, busy)
		m.poll(start + 30, busy)
		m.poll(start + 60, busy)
		m.poll(start + 90, busy)
		assert(#m.alerts == 0, failure)
		m.poll(start + 120, busy)
		assert(#m.alerts == 1, failure)
	end
end)

check("in-flight guards and sleep reject stale samples", function()
	local m = monitor()
	m.poll(0, busy)
	m.poll(30, busy)
	m.request(60)
	m.request(90)
	assert(#m.commands == 3)
	m.objects.cpuPanicListener.callbacks.system_will_sleep()
	m.ctx.islandState.isSleeping = true
	m.request(120)
	assert(#m.commands == 3)
	m.ctx.islandState.isSleeping = false
	m.complete(busy)
	m.sustain(busy, 150)
	assert(#m.alerts == 1)
	local slow = monitor()
	slow.poll(0, busy)
	slow.request(30)
	clock = 120
	slow.complete(busy)
	slow.poll(150, busy)
	assert(#slow.alerts == 0)
end)

check("actual ps command with headerless macOS rows and case-insensitive SketchyBar exclusion", function()
	local m = monitor()
	m.request(0)
	local pipe = assert(io.popen(m.commands[1]))
	local fixture = pipe:read("*a")
	assert(pipe:close())
	m.complete(fixture)
	for at = 30, 120, 30 do
		m.poll(at, fixture)
	end
	assert(#m.alerts == 1)
	assert(m.objects["island.cpu_panic_text"].label.string:find("Busy App", 1, true))
end)
