-- Native Sbar/item/clock boundaries are inert; load the real owners and dependencies.
local utf8 = require("utf8")
local root, scenario, scratch = assert(arg[1]), assert(arg[2]), assert(arg[3])
local bar = root .. "/modules/home/programs/graphical/bars/sketchybar/"
package.path = scratch .. "/?.lua;" .. bar .. "config/?.lua;" .. bar .. "config/?/init.lua;" .. package.path
local items, timers, commands = {}, {}, {}
local payload
local function noop(...) end
Sbar = {
	add = function(_, name, options)
		if type(name) == "table" then
			options, name = name, "anonymous"
		end
		local item = { name = name, drawing = options.drawing ~= false, callbacks = {}, label = options.label }
		function item:set(values)
			for key, value in pairs(values) do
				if type(value) == "table" then
					if type(self[key]) ~= "table" then
						self[key] = {}
					end
					for field, setting in pairs(value) do
						self[key][field] = setting
					end
				else
					self[key] = value
				end
			end
		end
		function item:subscribe(events, callback)
			if type(events) == "string" then
				events = { events }
			end
			for _, event in ipairs(events) do
				self.callbacks[event] = callback
			end
		end
		function item:query()
			return { icon = { value = self.icon.string or self.icon } }
		end
		items[name] = item
		return item
	end,
	animate = function(_, _, callback)
		callback()
	end,
	delay = function(seconds, callback)
		timers[#timers + 1] = { seconds, callback }
	end,
	exec = function(command, callback)
		commands[#commands + 1] = command
		if callback then
			if command == "pbpaste" then
				callback(payload)
			else
				callback("")
			end
		end
	end,
	trigger = function(event)
		for _, item in pairs(items) do
			if item.callbacks[event] then
				item.callbacks[event]()
			end
		end
	end,
	query = function(_)
		return { frame = { w = 1728 } }
	end,
	bar = noop,
	default = noop,
	set_bar_name = noop,
}
require("helpers.logger").set_level("off")
require("helpers.utils")

if scenario == "media" then
	require("items.media")
	local media = items.media
	local notify = media.callbacks.media_change
	notify({ INFO = { app = "Music", state = "playing", artist = "Artist", title = "Track" } })
	assert(media.drawing and media.label == "Artist: Track")
	notify({ INFO = { app = "Browser", state = "playing", title = "Other track" } })
	assert(not media.drawing, "ignored app leaves a stale track visible")
	notify({ INFO = { app = "Spotify", state = "playing", artist = "New", title = "Song" } })
	assert(media.drawing and media.label == "New: Song")
	for _, invalid in ipairs({ false, "invalid" }) do
		notify({ INFO = invalid })
		assert(media.drawing and media.label == "New: Song")
	end
	notify({})
	assert(media.drawing and media.label == "New: Song")
	notify({ INFO = { app = "Spotify", state = "paused" } })
	assert(not media.drawing)
elseif scenario == "stats" then
	require("items.stats")
	local names = { "cpu", "memory", "disk", "network.up", "network.down" }
	local function drawing(expected)
		for _, name in ipairs(names) do
			assert(items[name].drawing == expected, "unexpected stats visibility: " .. name)
		end
	end
	local function drain()
		local queued = timers
		timers = {}
		assert(#queued > 0)
		for _, timer in ipairs(queued) do
			assert(timer[1] == require("helpers.settings").animation.reveal_delay)
			timer[2]()
		end
	end
	Sbar.trigger("hide_stats")
	Sbar.trigger("show_stats")
	drain()
	drawing(true)
	assert(items.separator_right.icon == "")
	assert(commands[#commands]:find("sketchy_network_load en0", 1, true))
	-- An older close must also be rejected while a newer close awaits its own timer.
	Sbar.trigger("hide_stats")
	local old = table.remove(timers, 1)
	Sbar.trigger("show_stats")
	Sbar.trigger("hide_stats")
	old[2]()
	drawing(true)
	assert(commands[#commands] == "killall sketchy_network_load >/dev/null 2>&1")
	drain()
	drawing(false)
	assert(items.separator_right.icon == "")
	Sbar.trigger("show_stats")
	drawing(true)
elseif scenario == "helper" then
	for _, unit in ipairs({ "a", "é", "日", "😀" }) do
		assert(TRUNCATE_TEXT(unit:rep(4), 3) == unit:rep(2) .. "…")
		assert(TRUNCATE_TEXT(unit:rep(3), 3) == unit:rep(3))
		assert(TRUNCATE_TEXT(unit, 3) == unit)
		assert(TRUNCATE_TEXT(unit, 1) == unit)
		assert(TRUNCATE_TEXT(unit:rep(2), 1) == "…")
		assert(TRUNCATE_TEXT(unit:rep(121), 120) == unit:rep(119) .. "…")
		for _, limit in ipairs({ 0, -1 }) do
			assert(TRUNCATE_TEXT(unit:rep(4), limit) == unit:rep(4))
		end
		assert(TRUNCATE_TEXT(unit:rep(4), nil) == unit:rep(4))
	end
	assert(TRUNCATE_TEXT(nil, 3) == "")
	assert(TRUNCATE_TEXT("", 3) == "")
	assert(TRUNCATE_TEXT("a\255bc", 3) == "a\255…")
	assert(TRUNCATE_TEXT("a\255b", 3) == "a\255b")
	assert(TRUNCATE_TEXT("a\255bc", 0) == "a\255bc")
	assert(TRUNCATE_TEXT("a\255bc", -1) == "a\255bc")
elseif scenario == "clipboard" then
	local island = bar .. "dynamic-island-sketchybar/"
	local cfg = dofile(island .. "config.lua")
	local prefix = cfg.icons.clipboard.copied .. " Copied: "
	local function preview(text, limit, expected)
		TEST_PREVIEW_LIMIT = limit
		items, timers = {}, {}
		dofile(island .. "init.lua")
		local listener, display = items.clipboardListener, items["island.clipboard_text"]
		local function poll(value)
			payload = value
			listener.callbacks.routine()
		end
		poll(nil)
		poll("")
		assert(display.label.string == nil)
		-- First nonempty clipboard value seeds the cache without an alert.
		poll(limit > 0 and "!" or "baseline")
		assert(display.label.string == nil)
		poll(text)
		assert(display.label.string == prefix .. expected, "clipboard limit " .. limit)
		if limit > 0 and utf8.len(text) then
			assert(utf8.len(expected) <= limit)
		end
	end
	for _, unit in ipairs({ "a", "é", "日", "😀" }) do
		for _, limit in ipairs({ 1, 3, 120 }) do
			preview(unit:rep(limit + 1), limit, unit:rep(limit - 1) .. "…")
			preview(unit:rep(limit), limit, unit:rep(limit))
			preview(unit, limit, unit)
		end
		-- Nonpositive limits keep the existing byte-slicing contract, even for UTF-8.
		preview(unit:rep(4), 0, unit:rep(4) .. "…")
		local bytes = unit:rep(4)
		preview(bytes, -1, bytes:sub(1, -2) .. "…")
	end
	preview("a\255bc", 1, "…")
	preview("a\255bc", 3, "a\255…")
	preview("a\255b", 3, "a\255b")
	preview("a\255bc", 120, "a\255bc")
	preview("a\255bc", 0, "a\255bc…")
	preview("a\255bc", -1, "a\255b…")
else
	error("unknown scenario: " .. scenario)
end
print("PASS " .. scenario)
