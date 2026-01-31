#!/usr/bin/env lua

local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local dashes = "─────────────────"
local device_type_cache_ttl = 300
local device_type_lookup = {}
local device_type_lookup_updated = 0

local bluetooth = Sbar.add("item", "bluetooth", {
	position = "right",
	align = "right",
	update_freq = 60,
	icon = {
		drawing = true,
		string = icons.bluetooth,
		color = colors.peach,
	},
	background = {
		padding_right = 0,
	},
	popup = {
		height = 30,
	},
})

local function build_device_type_lookup(callback)
	local now = os.time()
	if device_type_lookup_updated > 0 and now - device_type_lookup_updated < device_type_cache_ttl then
		callback(device_type_lookup)
		return
	end

	Sbar.exec(
		[[system_profiler SPBluetoothDataType -json | jq -r '.SPBluetoothDataType[0] | ((.device_connected // []) + (.device_not_connected // [])) | .[] | to_entries[] | "\(.key)|\(.value.device_minorType // "")"']],
		function(result)
			local lookup = {}
			for line in result:gmatch("[^\n]+") do
				local name, minor_type = line:match("^(.-)|%s*(.*)$")
				if name and name ~= "" then
					lookup[name] = minor_type
				end
			end

			device_type_lookup = lookup
			device_type_lookup_updated = now
			callback(lookup)
		end
	)
end

local function device_icon_for(name, minor_type)
	local source = string.lower(minor_type or "")
	if source == "" and name then
		source = string.lower(name)
	end

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

bluetooth:subscribe("mouse.entered", function()
	bluetooth:set({ popup = { drawing = true } })
end)

bluetooth:subscribe({
	"mouse.exited.global",
	"mouse.exited",
}, function()
	bluetooth:set({ popup = { drawing = false } })
end)

bluetooth:subscribe("mouse.clicked", function()
	Sbar.exec("blueutil -p", function(state)
		if tonumber(state) == 0 then
			Sbar.exec("blueutil -p 1")
			bluetooth:set({ icon = icons.bluetooth })
		else
			Sbar.exec("blueutil -p 0")
			bluetooth:set({ icon = icons.bluetooth_off })
		end

		SLEEP(1)
		Sbar.trigger("bluetooth_update")
	end)
end)

bluetooth:subscribe({
	"routine",
	"forced",
	"bluetooth_update",
	"system_woke",
}, function()
	Sbar.exec("blueutil -p", function(state)
		local existingEvents = bluetooth:query()
		if existingEvents.popup and next(existingEvents.popup.items) ~= nil then
			for _, item in pairs(existingEvents.popup.items) do
				Sbar.remove(item)
			end
		end

		if tonumber(state) == 0 then
			bluetooth:set({ icon = icons.bluetooth_off })
		else
			bluetooth:set({ icon = icons.bluetooth })
		end

		Sbar.exec("blueutil --paired", function(paired)
			build_device_type_lookup(function(device_type_lookup)
				bluetooth.paired = {}

				bluetooth.paired.header = Sbar.add("item", "bluetooth.paired.header", {
					icon = { drawing = false },
					label = {
						string = "Paired Devices",
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

				for device in paired:gmatch("[^\n]+") do
					local label = device:match('"(.*)"')
					local device_icon = device_icon_for(label, device_type_lookup[label])
					bluetooth.paired.device = Sbar.add("item", "bluetooth.paired.device." .. label, {
						icon = {
							string = device_icon,
							color = colors.blue,
							padding_left = settings.paddings + 12,
							font = {
								family = settings.nerd_font,
								size = 12.0,
								style = "Bold",
							},
						},
						label = {
							string = label,
							padding_left = 6,
							font = {
								family = settings.font,
								size = 13.0,
								style = "Regular",
							},
						},
						position = "popup." .. bluetooth.name,
						click_script = "sketchybar --set $NAME popup.drawing=off",
					})
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

				Sbar.exec("blueutil --connected", function(connected)
					bluetooth.connected = {}

					bluetooth.connected.header = Sbar.add("item", "bluetooth.connected.header", {
						icon = { drawing = false },
						label = {
							string = "Connected Devices",
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

					for device in connected:gmatch("[^\n]+") do
						local label = device:match('"(.*)"')
						local device_icon = device_icon_for(label, device_type_lookup[label])
						bluetooth.connected.device = Sbar.add("item", "bluetooth.connected.device." .. label, {
							icon = {
								string = device_icon,
								color = colors.blue,
								padding_left = settings.paddings + 12,
								font = {
									family = settings.nerd_font,
									size = 12.0,
									style = "Bold",
								},
							},
							label = {
								string = label,
								padding_left = 6,
								font = {
									family = settings.font,
									size = 13.0,
									style = "Regular",
								},
							},
							position = "popup." .. bluetooth.name,
							click_script = "sketchybar --set $NAME popup.drawing=off",
						})
					end
				end)
			end)
		end)
	end)
end)

return bluetooth
