-- Run with Lua 5.4 and a repository root argument. Native commands are mocked.
local root = assert(arg[1])
local bar = root .. "/modules/home/programs/graphical/bars/sketchybar/"
package.path = bar .. "config/?.lua;" .. bar .. "config/?/init.lua;" .. package.path
local noop = function() end
package.loaded["helpers.logger"] = { debug = noop, warn = noop, info = noop }
package.loaded["helpers.colors"] = {}
IS_SYSTEM_SLEEPING = false
IS_EMPTY = function(x)
	return x == nil or x == ""
end
SHELL_QUOTE = function(x)
	return "'" .. x .. "'"
end
SETUP_STANDARD_CLICKS = noop
DELAY = function(_, fn)
	fn()
end
local objects, bracket, hover, payload, clears, triggers = {}, nil, nil, nil, 0, 0
Sbar = {
	add = function(kind, name, options, ...)
		if kind == "bracket" then
			bracket = name
			return {}
		end
		if type(name) == "table" then
			options = name
			name = "anonymous." .. (#objects + 1)
		end
		local object = { name = name, options = options, events = {} }
		function object:set(value)
			self.last = value
		end
		function object:subscribe(events, fn)
			if type(events) == "string" then
				events = { events }
			end
			for _, event in ipairs(events) do
				self.events[event] = fn
			end
		end
		objects[#objects + 1] = object
		objects[name] = object
		return object
	end,
	exec = function(command, callback)
		if command == "gh api notifications" then
			callback(payload)
		elseif command == "ipconfig getifaddr en0" then
			callback("")
		else
			callback(payload)
		end
	end,
	trigger = function(...)
		triggers = triggers + 1
	end,
}
CLEAR_POPUP_ITEMS = function()
	clears = clears + 1
end
SETUP_POPUP_HOVER = function(_, fn)
	hover = fn
end

-- Bracket membership remains dense with or without the optional first item.
for _, enabled in ipairs({ false, true }) do
	for _, name in ipairs({ "battery", "wifi", "bluetooth", "brew", "github", "keep_awake" }) do
		package.loaded["items.control_center." .. name] = { name = name }
	end
	package.loaded["items.control_center.volume"] = { icon = { name = "volume" } }
	package.loaded["helpers.power_config"] = { use_closed_lid_awake = enabled }
	dofile(bar .. "config/items/control_center/init.lua")
	assert(
		table.concat(assert(bracket), ",")
			== (enabled and "keep_awake," or "") .. "battery,wifi,bluetooth,brew,github,volume"
	)
end

local utils_file = assert(io.open(bar .. "config/helpers/utils.lua"))
local utils = utils_file:read("a")
utils_file:close()
assert(load(assert(utils:match("(STR_SPLIT = function.-)\n\nPRINT_TABLE"))))()
objects = {}
local wifi = dofile(bar .. "config/items/control_center/wifi.lua")
for _, fields in ipairs({
	{ "host", "", "SSID", "", "router" },
	{ "", "IP", "", "mask", "" },
	{ "", "", "", "", "" },
	{ "host", "IP", "SSID", "mask", "router" },
}) do
	payload = table.concat(fields, "\n") .. "\n"
	assert(hover)()
	-- Creation order: wifi, ssid, hostname, ip, mask, router.
	for field, index in ipairs({ 3, 4, 2, 5, 6 }) do
		assert(objects[index].last.label == fields[field], "wifi field " .. field)
	end
end

objects = {}
local github = dofile(bar .. "config/items/control_center/github.lua")
payload = {}
for i = 1, 17 do
	payload[i] = {
		id = tostring(i),
		updated_at = "2026-10-10",
		repository = { full_name = string.format("owner/repo%02d", i) },
		subject = { title = "title" .. i, type = "Issue" },
	}
end
github.events.routine()
assert(clears == 1 and triggers == 1)
local first_count = #objects
github.events.routine()
assert(clears == 1 and #objects == first_count, "unchanged payload should stay cached")
payload[17].updated_at = "2026-10-11"
payload[17].subject.title = "changed seventeenth"
github.events.routine()
assert(clears == 2 and triggers == 2, "seventeenth update must invalidate cache")
assert(objects[#objects].options.label.string == "changed seventeenth")
payload = {}
github.events.routine()
assert(clears == 3 and objects.github.last.label == 0)
print("PASS Lua bracket, Wi-Fi field positions, full GitHub cache invalidation")
