#!/usr/bin/env lua

local settings = require("settings")
local colors = require("colors")
local icons = require("icons")

local network = {}

Sbar.exec("killall sketchy_network_load >/dev/null 2>&1; sketchy_network_load en0 network_update 2.0")

network.down = Sbar.add("item", "network.down", {
	background = {
		padding_left = 0,
	},
	label = {
		font = {
			family = settings.font,
			size = 10.0,
			style = "Heavy",
		},
		color = colors.text,
	},
	icon = {
		font = {
			family = settings.nerd_font,
			size = 16.0,
			style = "Bold",
		},
		string = icons.stats.network_down,
		color = colors.green,
		highlight_color = colors.blue,
	},
	update_freq = 1,
	position = "right",
	y_offset = -7,
})

network.up = Sbar.add("item", "network.up", {
	background = {
		padding_right = -70,
	},
	label = {
		font = {
			family = settings.font,
			size = 10.0,
			style = "Heavy",
		},
		color = colors.text,
	},
	icon = {
		font = {
			family = settings.nerd_font,
			size = 16.0,
			style = "Bold",
		},
		string = icons.stats.network_up,
		color = colors.green,
		highlight_color = colors.blue,
	},
	update_freq = 1,
	position = "right",
	y_offset = 7,
})

network.down:subscribe("network_update", function(env)
	local up_color = (env.upload == "000 Bps") and colors.subtext0 or colors.green
	local down_color = (env.download == "000 Bps") and colors.subtext0 or colors.blue
	network.up:set({
		icon = { color = up_color },
		label = {
			string = env.upload,
		},
	})
	network.down:set({
		icon = { color = down_color },
		label = {
			string = env.download,
		},
	})
end)

return network
