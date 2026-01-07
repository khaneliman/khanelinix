#!/usr/bin/env lua

local colors = require("colors")
local wm_config = require("wm_config")

local bar_height = 40

-- Equivalent to the --bar domain
Sbar.bar({
	blur_radius = 30,
	border_color = colors.surface1,
	border_width = 2,
	color = colors.base,
	corner_radius = 9,
	height = bar_height,
	margin = 10,
	notch_width = 0,
	padding_left = 18,
	padding_right = 10,
	position = "top",
	shadow = true,
	sticky = true,
	topmost = false,
	y_offset = 10,
})

-- Set external_bar here in case we launch after sketchybar
if wm_config.use_yabai then
	Sbar.exec("yabai -m config external_bar all:" .. bar_height .. ":0")
end
