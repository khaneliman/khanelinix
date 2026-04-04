#!/usr/bin/env lua
IS_SYSTEM_SLEEPING = false

local system_watcher = Sbar.add("item", {
	drawing = false,
})

system_watcher:subscribe("system_will_sleep", function()
	print("System going to sleep, setting IS_SYSTEM_SLEEPING = true")
	IS_SYSTEM_SLEEPING = true
end)

system_watcher:subscribe("system_woke", function()
	print("System woke up, setting IS_SYSTEM_SLEEPING = false")
	IS_SYSTEM_SLEEPING = false
end)

POPUP_TOGGLE = function(name)
	print("Toggling " .. name)
	Sbar.exec("sketchybar --set " .. name .. " popup.drawing=toggle")
end

POPUP_OFF = function(name)
	print("Hiding " .. name)
	Sbar.exec("sketchybar --set " .. name .. " popup.drawing=off")
end

POPUP_ON = function(name)
	print("Showing " .. name)
	Sbar.exec("sketchybar --set " .. name .. " popup.drawing=on")
end

IS_EMPTY = function(s)
	return s == nil or s == ""
end

STR_SPLIT = function(inputstr, sep)
	if inputstr == nil then
		return {}
	end
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

PRINT_TABLE = function(t)
	for key, value in pairs(t) do
		if type(value) == "table" then
			print(key, ":")
			PRINT_TABLE(value)
		else
			print(key, ":", value)
		end
	end
end

DELAY = function(seconds, callback)
	if type(callback) ~= "function" then
		return
	end

	local duration = tonumber(seconds) or 0
	if duration <= 0 then
		callback()
		return
	end

	Sbar.delay(duration, callback)
end

COLOR_TO_HEX = function(color)
	return string.format("0x%x", color)
end
