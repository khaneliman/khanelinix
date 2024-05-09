#!/usr/bin/env lua

local icons = require("icons")
local settings = require("settings")
local colors = require("colors")

local popup_width = 250

local wifi = Sbar.add("item", "wifi", {
	position = "right",
	align = "right",
	click_script = "sketchybar --set $NAME popup.drawing=toggle",
	icon = {
		string = icons.wifi,
		font = {
			family = settings.nerd_font,
			style = "Regular",
			size = 19.0,
		},
	},
	background = {
		padding_left = 5,
	},
	label = { drawing = false },
	update_freq = 60,
	popup = {
		align = "right",
	},
})

local ssid = Sbar.add("item", {
	position = "popup." .. wifi.name,
	icon = {
		font = {
			style = "Bold",
		},
		string = icons.wifi.router,
	},
	width = popup_width,
	align = "center",
	label = {
		font = {
			size = 15,
			style = "Bold",
		},
		max_chars = 18,
		string = "????????????",
	},
	background = {
		height = 2,
		color = colors.grey,
		y_offset = -15,
	},
})

local hostname = Sbar.add("item", {
	position = "popup." .. wifi.name,
	icon = {
		align = "left",
		string = "Hostname:",
		width = popup_width / 2,
	},
	label = {
		max_chars = 20,
		string = "????????????",
		width = popup_width / 2,
		align = "right",
	},
})

local ip = Sbar.add("item", {
	position = "popup." .. wifi.name,
	icon = {
		align = "left",
		string = "IP:",
		width = popup_width / 2,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width / 2,
		align = "right",
	},
})

local mask = Sbar.add("item", {
	position = "popup." .. wifi.name,
	icon = {
		align = "left",
		string = "Subnet mask:",
		width = popup_width / 2,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width / 2,
		align = "right",
	},
})

local router = Sbar.add("item", {
	position = "popup." .. wifi.name,
	icon = {
		align = "left",
		string = "Router:",
		width = popup_width / 2,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width / 2,
		align = "right",
	},
})

wifi:subscribe({ "wifi_change", "system_woke" }, function()
	Sbar.exec("ipconfig getifaddr en0", function(ip_address)
		local connected = (ip_address ~= "")
		wifi:set({
			icon = {
				string = connected and icons.wifi or icons.wifi_off,
			},
		})
	end)
end)

wifi:subscribe({
	"mouse.exited",
	"mouse.exited.global",
}, function(_)
	wifi:set({ popup = { drawing = false } })
end)

wifi:subscribe({
	"mouse.entered",
}, function(_)
	wifi:set({ popup = { drawing = true } })
	Sbar.exec("networksetup -getcomputername", function(result)
		hostname:set({ label = result })
	end)
	Sbar.exec("ipconfig getifaddr en0", function(result)
		ip:set({ label = result })
	end)
	Sbar.exec("ipconfig getsummary en0 | awk -F ' SSID : '  '/ SSID : / {print $2}'", function(result)
		ssid:set({ label = result })
	end)
	Sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Subnet mask: ' '/^Subnet mask: / {print $2}'", function(result)
		mask:set({ label = result })
	end)
	Sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'", function(result)
		router:set({ label = result })
	end)
end)

local function copy_label_to_clipboard(env)
	local label = Sbar.query(env.NAME).label.value
	Sbar.exec('echo "' .. label .. '" | pbcopy')
	Sbar.set(env.NAME, { label = { string = icons.clipboard, align = "center" } })
	Sbar.delay(1, function()
		Sbar.set(env.NAME, { label = { string = label, align = "right" } })
	end)
end

ssid:subscribe("mouse.clicked", copy_label_to_clipboard)
hostname:subscribe("mouse.clicked", copy_label_to_clipboard)
ip:subscribe("mouse.clicked", copy_label_to_clipboard)
mask:subscribe("mouse.clicked", copy_label_to_clipboard)
router:subscribe("mouse.clicked", copy_label_to_clipboard)

return wifi
