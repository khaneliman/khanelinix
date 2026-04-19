#!/usr/bin/env lua
IS_SYSTEM_SLEEPING = false

local function _popup_item_name(target)
	if type(target) == "table" and type(target.name) == "string" then
		return target.name
	end
	if type(target) == "string" then
		return target
	end
	return nil
end

local function _is_popup_drawing(item_name)
	local query = Sbar.query(item_name)
	if query == nil or query.popup == nil then
		return false
	end

	local drawing = query.popup.drawing
	if drawing == true or drawing == "on" or drawing == "1" then
		return true
	end
	if drawing == false or drawing == "off" or drawing == "0" then
		return false
	end

	return false
end

local system_watcher = Sbar.add("item", {
	drawing = false,
})

system_watcher:subscribe("system_will_sleep", function()
	IS_SYSTEM_SLEEPING = true
end)

system_watcher:subscribe("system_woke", function()
	IS_SYSTEM_SLEEPING = false
end)

POPUP_TOGGLE = function(name)
	local popup_name = _popup_item_name(name)
	if popup_name == nil then
		return
	end

	local currently_open = _is_popup_drawing(popup_name)
	Sbar.set(popup_name, { popup = { drawing = not currently_open } })
end

POPUP_OFF = function(name)
	local popup_name = _popup_item_name(name)
	if popup_name == nil then
		return
	end

	Sbar.set(popup_name, { popup = { drawing = false } })
end

POPUP_ON = function(name)
	local popup_name = _popup_item_name(name)
	if popup_name == nil then
		return
	end

	Sbar.set(popup_name, { popup = { drawing = true } })
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

TRUNCATE_TEXT = function(value, maxLength)
	if value == nil then
		return ""
	end

	local text = tostring(value)
	local limit = tonumber(maxLength)
	if limit == nil or limit <= 0 or #text <= limit then
		return text
	end

	if limit == 1 then
		return "…"
	end

	return text:sub(1, limit - 1) .. "…"
end

SHELL_QUOTE = function(value)
	local text = tostring(value or "")
	return "'" .. text:gsub("'", [['"'"']]) .. "'"
end

CLEAR_POPUP_ITEMS = function(item_name)
	local query = Sbar.query(item_name)
	if query.popup and next(query.popup.items) ~= nil then
		for _, child in pairs(query.popup.items) do
			Sbar.remove(child)
		end
	end
end

SETUP_POPUP_HOVER = function(item, additional_entered_logic, additional_exited_logic)
	item:subscribe("mouse.entered", function()
		item:set({ popup = { drawing = true } })
		if additional_entered_logic then
			additional_entered_logic()
		end
	end)
	item:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
		item:set({ popup = { drawing = false } })
		if additional_exited_logic then
			additional_exited_logic()
		end
	end)
end

SETUP_STANDARD_CLICKS = function(item, update_trigger_name)
	item:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "left" then
			POPUP_TOGGLE(env.NAME)
		elseif env.BUTTON == "right" and update_trigger_name then
			Sbar.trigger(update_trigger_name)
		end
	end)
end

EXEC_IF_AWAKE = function(command, callback)
	if IS_SYSTEM_SLEEPING then
		return
	end
	Sbar.exec(command, callback)
end
