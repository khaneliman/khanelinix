#!/usr/bin/env lua

local settings = require("settings")

-- Equivalent to the --bar domain
Sbar.bar({
	color = settings.colors.crust,
	corner_radius = settings.corner_radius,
	display = settings.display,
	height = settings.default.height,
	margin = settings.monitor.horizontal_resolution / 2 - settings.default.width,
	notch_width = 0,
	padding_left = 0,
	padding_right = 0,
	position = "top",
	shadow = false,
	sticky = false,
	topmost = true,
	y_offset = settings.y_offset,
})

print("sbar::bar::set")
