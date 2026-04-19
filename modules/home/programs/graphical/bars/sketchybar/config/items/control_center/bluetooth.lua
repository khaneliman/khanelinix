#!/usr/bin/env lua
local icons = require("helpers.icons")
local colors = require("helpers.colors")
local settings = require("helpers.settings")
local logger = require("helpers.logger")

local dashes = "─────────────────"
local max_rows_per_section = 16
local popup_is_open = false
local refresh_generation = 0

local bluetooth = Sbar.add("item", "bluetooth", {
	position = "right",
	align = "right",
	update_freq = 120,
	icon = {
		drawing = true,
		string = icons.bluetooth,
		color = colors.peach,
	},
	background = {
		padding_right = 0,
	},
	popup = {
		align = "right",
	},
})

local function trim(value)
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function parse_state_number(state)
	local normalized = trim((state or ""):gsub("[\r\n]", ""))
	if normalized == "" then
		return nil
	end

	return tonumber(normalized)
end

local function parse_device_label(device)
	local quoted_label = device:match('"(.-)"')
	if quoted_label and quoted_label ~= "" then
		return trim(quoted_label)
	end
	return trim(device)
end

local function parse_devices(result)
	local devices = {}
	for line in result:gmatch("[^\n]+") do
		local label = parse_device_label(line)
		if label ~= "" then
			table.insert(devices, label)
		end
	end
	return devices
end

local function device_icon_for(name)
	local source = string.lower(name or "")

	if source:find("head") or source:find("airpods") then
		return icons.bluetooth_devices.headphones
	end
	if source:find("phone") or source:find("iphone") then
		return icons.bluetooth_devices.phone
	end
	if source:find("watch") then
		return icons.bluetooth_devices.watch
	end
	if source:find("speaker") or source:find("home theater") or source:find("sound") then
		return icons.bluetooth_devices.speaker
	end
	if source:find("keyboard") then
		return icons.bluetooth_devices.keyboard
	end
	if source:find("mouse") then
		return icons.bluetooth_devices.mouse
	end
	if source:find("controller") or source:find("game") then
		return icons.bluetooth_devices.controller
	end

	return icons.bluetooth_devices.default
end

local function create_header(name, title)
	return Sbar.add("item", name, {
		icon = { drawing = false },
		label = {
			string = title,
			color = colors.blue,
			padding_left = settings.paddings,
			padding_right = settings.paddings,
			font = {
				family = settings.font,
				size = 14.0,
				style = "Bold",
			},
		},
		position = "popup." .. bluetooth.name,
		click_script = "sketchybar --set $NAME popup.drawing=off",
	})
end

local function create_device_row(name)
	return Sbar.add("item", name, {
		icon = { drawing = false },
		label = { drawing = false },
		position = "popup." .. bluetooth.name,
		click_script = "sketchybar --set $NAME popup.drawing=off",
	})
end

local function hide_row(row)
	row:set({
		drawing = false,
		icon = {
			drawing = false,
		},
		label = {
			drawing = false,
		},
	})
end

local function set_none_row(row)
	row:set({
		drawing = true,
		icon = {
			drawing = false,
		},
		label = {
			drawing = true,
			string = "None",
			color = colors.grey,
			padding_left = settings.paddings + 12,
			font = {
				family = settings.font,
				size = 13.0,
				style = "Italic",
			},
		},
	})
end

local function set_device_row(row, label)
	row:set({
		drawing = true,
		icon = {
			drawing = true,
			string = device_icon_for(label),
			color = colors.blue,
			padding_left = settings.paddings + 12,
			font = {
				family = settings.nerd_font,
				size = 12.0,
				style = "Bold",
			},
		},
		label = {
			drawing = true,
			string = label,
			padding_left = 6,
			font = {
				family = settings.font,
				size = 13.0,
				style = "Regular",
			},
		},
	})
end

local function set_loading_row(row)
	row:set({
		drawing = true,
		icon = {
			drawing = false,
		},
		label = {
			drawing = true,
			string = "Loading...",
			color = colors.grey,
			padding_left = settings.paddings + 12,
			font = {
				family = settings.font,
				size = 13.0,
				style = "Italic",
			},
		},
	})
end

local function hide_extra_rows(rows, from_index)
	for i = from_index, #rows do
		hide_row(rows[i])
	end
end

local function render_rows(rows, devices)
	if #devices == 0 then
		set_none_row(rows[1])
		hide_extra_rows(rows, 2)
		return
	end

	for i = 1, #rows do
		local label = devices[i]
		if label then
			set_device_row(rows[i], label)
		else
			hide_row(rows[i])
		end
	end
end

CLEAR_POPUP_ITEMS(bluetooth.name)

create_header("bluetooth.paired.header", "Paired Devices")
local paired_rows = {}
for i = 1, max_rows_per_section do
	paired_rows[i] = create_device_row("bluetooth.paired.device." .. i)
	hide_row(paired_rows[i])
end

Sbar.add("item", "bluetooth.separator", {
	icon = {
		string = "",
		width = 0,
	},
	label = {
		string = dashes,
		color = colors.grey,
		align = "center",
	},
	background = {
		height = 1,
	},
	padding_left = 0,
	padding_right = 0,
	position = "popup." .. bluetooth.name,
	click_script = "sketchybar --set $NAME popup.drawing=off",
})

create_header("bluetooth.connected.header", "Connected Devices")
local connected_rows = {}
for i = 1, max_rows_per_section do
	connected_rows[i] = create_device_row("bluetooth.connected.device." .. i)
	hide_row(connected_rows[i])
end

local function refresh_icon()
	Sbar.exec("blueutil -p", function(state)
		local enabled = parse_state_number(state)
		if enabled == nil then
			logger.warn("bluetooth", "refresh_icon_parse_failed", { state = tostring(state) })
			return
		end
		logger.debug("bluetooth", "refresh_icon", { enabled = (enabled == 1) })
		if enabled == 0 then
			bluetooth:set({ icon = icons.bluetooth_off })
		else
			bluetooth:set({ icon = icons.bluetooth })
		end
	end)
end

local function refresh_popup()
	refresh_generation = refresh_generation + 1
	local generation = refresh_generation

	set_loading_row(paired_rows[1])
	hide_extra_rows(paired_rows, 2)

	set_loading_row(connected_rows[1])
	hide_extra_rows(connected_rows, 2)

	Sbar.exec("blueutil --paired", function(result)
		if generation ~= refresh_generation or not popup_is_open then
			logger.debug("bluetooth", "refresh_paired_stale", { generation = generation, current = refresh_generation })
			return
		end

		local devices = parse_devices(result)
		if #devices == 0 then
			logger.debug("bluetooth", "paired_devices_empty", { generation = generation })
		end
		render_rows(paired_rows, devices)
	end)

	Sbar.exec("blueutil --connected", function(result)
		if generation ~= refresh_generation or not popup_is_open then
			logger.debug(
				"bluetooth",
				"refresh_connected_stale",
				{ generation = generation, current = refresh_generation }
			)
			return
		end
		local devices = parse_devices(result)
		if #devices == 0 then
			logger.debug("bluetooth", "connected_devices_empty", { generation = generation })
		end
		render_rows(connected_rows, devices)
	end)
end

SETUP_POPUP_HOVER(bluetooth, function()
	if popup_is_open then
		return
	end

	popup_is_open = true
	refresh_popup()
end, function()
	popup_is_open = false
	refresh_generation = refresh_generation + 1
end)

bluetooth:subscribe("mouse.clicked", function()
	logger.debug("bluetooth", "toggle_requested", {})
	Sbar.exec("blueutil -p", function(state)
		local parsed = parse_state_number(state)
		if parsed == nil then
			logger.warn("bluetooth", "toggle_state_parse_failed", { state = tostring(state) })
			return
		end
		if parsed == 0 then
			logger.debug("bluetooth", "toggle_turning_on", {})
			Sbar.exec("blueutil -p 1")
		else
			logger.debug("bluetooth", "toggle_turning_off", {})
			Sbar.exec("blueutil -p 0")
		end

		DELAY(1, function()
			Sbar.trigger("bluetooth_update")
			if popup_is_open then
				refresh_popup()
			end
		end)
	end)
end)

bluetooth:subscribe({
	"routine",
	"forced",
	"bluetooth_update",
	"system_woke",
}, function()
	refresh_icon()
end)

return bluetooth
