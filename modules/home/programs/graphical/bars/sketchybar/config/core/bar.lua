#!/usr/bin/env lua

local colors = require("helpers.colors")
local settings = require("helpers.settings")
local wm_config = require("helpers.wm_config")

-- Equivalent to the --bar domain
Sbar.bar({
	blur_radius = settings.dimensions.bar_blur_radius,
	border_color = colors.surface1,
	border_width = settings.dimensions.bar_border_width,
	color = colors.base,
	corner_radius = settings.dimensions.item_corner_radius,
	height = settings.dimensions.bar_height,
	margin = settings.dimensions.bar_margin,
	notch_width = settings.spacing.none,
	padding_left = settings.spacing.bar_left,
	padding_right = settings.spacing.large,
	position = "top",
	shadow = true,
	sticky = true,
	topmost = false,
	y_offset = settings.offsets.bar_y,
})

-- Set external_bar here in case we launch after sketchybar
if wm_config.use_yabai then
	Sbar.exec("yabai -m config external_bar all:" .. settings.dimensions.bar_height .. ":0")
end
