#!/usr/bin/env lua
local icons = require("helpers.icons")
local colors = require("helpers.colors")
local settings = require("helpers.settings")
local logger = require("helpers.logger")

local dashes = "─────────────────"
local max_rows_per_section = 16
local popup_is_open = false
local refresh_generation = 0
local icon_refresh_in_flight = false
local icon_refresh_pending = false
local popup_refresh_in_flight = false
local popup_refresh_pending = false
local blueutil_in_flight = false
local blueutil_queue = {}
local cached_power_state = nil

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

local function run_next_blueutil()
	if blueutil_in_flight or #blueutil_queue == 0 then
		return
	end

	blueutil_in_flight = true
	local job = table.remove(blueutil_queue, 1)
	Sbar.exec(job.command, function(result)
		blueutil_in_flight = false
		if type(job.callback) == "function" then
			job.callback(result)
		end
		run_next_blueutil()
	end)
end

local function exec_blueutil(command, callback)
	table.insert(blueutil_queue, {
		command = command,
		callback = callback,
	})
	run_next_blueutil()
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
	if icon_refresh_in_flight then
		icon_refresh_pending = true
		logger.debug("bluetooth", "refresh_icon_coalesced", {})
		return
	end

	icon_refresh_in_flight = true
	exec_blueutil("blueutil -p", function(state)
		icon_refresh_in_flight = false
		local enabled = PARSE_NUMBER(state)
		if enabled == nil then
			logger.warn("bluetooth", "refresh_icon_parse_failed", { state = tostring(state) })
		else
			cached_power_state = enabled
			logger.debug("bluetooth", "refresh_icon", { enabled = (enabled == 1) })
			if enabled == 0 then
				bluetooth:set({ icon = icons.bluetooth_off })
			else
				bluetooth:set({ icon = icons.bluetooth })
			end
		end

		if icon_refresh_pending then
			icon_refresh_pending = false
			refresh_icon()
		end
	end)
end

local refresh_popup

local function finish_popup_refresh()
	popup_refresh_in_flight = false
	if popup_refresh_pending and popup_is_open then
		popup_refresh_pending = false
		refresh_popup()
		return
	end

	popup_refresh_pending = false
end

refresh_popup = function()
	refresh_generation = refresh_generation + 1
	local generation = refresh_generation

	if popup_refresh_in_flight then
		popup_refresh_pending = true
		logger.debug("bluetooth", "refresh_popup_coalesced", { generation = generation })
		return
	end

	popup_refresh_in_flight = true

	set_loading_row(paired_rows[1])
	hide_extra_rows(paired_rows, 2)

	set_loading_row(connected_rows[1])
	hide_extra_rows(connected_rows, 2)

	exec_blueutil("blueutil --paired", function(result)
		if generation ~= refresh_generation or not popup_is_open then
			logger.debug("bluetooth", "refresh_paired_stale", { generation = generation, current = refresh_generation })
			finish_popup_refresh()
			return
		end

		local devices = parse_devices(result)
		if #devices == 0 then
			logger.debug("bluetooth", "paired_devices_empty", { generation = generation })
		end
		render_rows(paired_rows, devices)

		exec_blueutil("blueutil --connected", function(connected_result)
			if generation ~= refresh_generation or not popup_is_open then
				logger.debug(
					"bluetooth",
					"refresh_connected_stale",
					{ generation = generation, current = refresh_generation }
				)
				finish_popup_refresh()
				return
			end
			local connected_devices = parse_devices(connected_result)
			if #connected_devices == 0 then
				logger.debug("bluetooth", "connected_devices_empty", { generation = generation })
			end
			render_rows(connected_rows, connected_devices)
			finish_popup_refresh()
		end)
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
	popup_refresh_pending = false
end)

local function apply_toggle(parsed)
	if parsed == 0 then
		logger.debug("bluetooth", "toggle_turning_on", {})
		cached_power_state = 1
		exec_blueutil("blueutil -p 1")
	else
		logger.debug("bluetooth", "toggle_turning_off", {})
		cached_power_state = 0
		exec_blueutil("blueutil -p 0")
	end

	DELAY(1, function()
		Sbar.trigger("bluetooth_update")
		if popup_is_open then
			refresh_popup()
		end
	end)
end

bluetooth:subscribe("mouse.clicked", function()
	logger.debug("bluetooth", "toggle_requested", {})
	exec_blueutil("blueutil -p", function(state)
		local parsed = PARSE_NUMBER(state)
		if parsed == nil then
			logger.warn("bluetooth", "toggle_state_parse_failed", { state = tostring(state) })
			return
		end
		apply_toggle(parsed)
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
