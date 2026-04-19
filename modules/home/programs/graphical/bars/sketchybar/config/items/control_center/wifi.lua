#!/usr/bin/env lua

local icons = require("helpers.icons")
local settings = require("helpers.settings")
local colors = require("helpers.colors")
local logger = require("helpers.logger")

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
		string = icons.wifi,
	},
	width = popup_width,
	align = "center",
	label = {
		font = {
			size = 15,
			style = "Bold",
		},
		max_chars = 25,
		string = "????????????",
		color = colors.yellow,
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
		string = "",
		width = 30,
		color = colors.yellow,
	},
	label = {
		max_chars = 20,
		string = "????????????",
		width = popup_width - 30,
		align = "right",
		color = colors.white,
	},
})

local ip = Sbar.add("item", {
	position = "popup." .. wifi.name,
	icon = {
		align = "left",
		string = "",
		width = 30,
		color = colors.yellow,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width - 30,
		align = "right",
		color = colors.white,
	},
})

local mask = Sbar.add("item", {
	position = "popup." .. wifi.name,
	icon = {
		align = "left",
		string = icons.lock,
		width = 30,
		color = colors.yellow,
		font = {
			size = 14.0,
		},
	},
	label = {
		string = "???.???.???.???",
		width = popup_width - 30,
		align = "right",
		color = colors.white,
	},
})

local router = Sbar.add("item", {
	position = "popup." .. wifi.name,
	icon = {
		align = "left",
		string = icons.stats.network,
		width = 30,
		color = colors.yellow,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width - 30,
		align = "right",
		color = colors.white,
	},
})

local function refresh_status()
	Sbar.exec("ipconfig getifaddr en0", function(ip_address)
		local ip_clean = (ip_address or ""):gsub("[\r\n]", "")
		local connected = (ip_clean ~= "")
		if IS_SYSTEM_SLEEPING then
			return
		end
		logger.debug("wifi", "refresh_status", { connected = connected, ip = ip_clean })
		if connected == false then
			logger.debug("wifi", "wifi_disconnected", { ip_lookup = "failed" })
		end
		wifi:set({
			icon = {
				string = connected and icons.wifi or icons.wifi_off,
			},
		})
	end)
end

local function refresh_popup_details()
	logger.debug("wifi", "refresh_popup_details", {})
	Sbar.exec(
		[[
	network_name=$(networksetup -getcomputername 2>/dev/null)
	ip_address=$(ipconfig getifaddr en0 2>/dev/null || true)
	ssid=$(ipconfig getsummary en0 2>/dev/null | awk -F ' SSID : ' '/ SSID : / {print $2; exit}')
	network_info=$(networksetup -getinfo Wi-Fi 2>/dev/null)
		subnet=$(printf '%s\n' "$network_info" | awk -F ':' '/Subnet mask:/ {print $2}' | awk 'NR==1 {gsub(/^ +| +$/, "", $0); print; exit}')
		gateway=$(printf '%s\n' "$network_info" | awk -F ':' '/Router:/ {print $2}' | awk 'NR==1 {gsub(/^ +| +$/, "", $0); print; exit}')
		printf '%s\n%s\n%s\n%s\n%s\n' "$network_name" "$ip_address" "$ssid" "$subnet" "$gateway"
		]],
		function(result)
			if IS_EMPTY(result) then
				logger.warn("wifi", "popup_details_empty", {})
				return
			end
			local parts = STR_SPLIT(result or "", "\n")
			hostname:set({ label = parts[1] or "" })
			ip:set({ label = parts[2] or "" })
			ssid:set({ label = parts[3] or "" })
			mask:set({ label = parts[4] or "" })
			router:set({ label = parts[5] or "" })
		end
	)
end

wifi:subscribe({ "wifi_change", "system_woke", "forced" }, refresh_status)

SETUP_POPUP_HOVER(wifi, function()
	refresh_popup_details()
end)

local function copy_label_to_clipboard(env)
	local label = Sbar.query(env.NAME).label.value
	if IS_EMPTY(label) then
		logger.warn("wifi", "copy_label_empty", { item = env.NAME })
	else
		logger.debug("wifi", "copy_label", { item = env.NAME })
	end
	Sbar.exec("printf %s " .. SHELL_QUOTE(label) .. " | pbcopy")
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

refresh_status()

return wifi
