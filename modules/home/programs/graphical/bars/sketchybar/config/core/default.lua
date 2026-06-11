#!/usr/bin/env lua

local settings = require("helpers.settings")
local colors = require("helpers.colors")

-- Equivalent to the --default domain
Sbar.default({
	updates = "when_shown",
	icon = {
		color = colors.text,
		font = {
			family = settings.nerd_font,
			style = "Bold",
			size = settings.font_sizes.default_icon,
			features = settings.nerd_font_features,
		},
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
	label = {
		color = colors.text,
		font = {
			family = settings.font,
			style = "Semibold",
			size = settings.font_sizes.default_label,
			features = settings.font_features,
		},
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
	background = {
		corner_radius = settings.dimensions.item_corner_radius,
		height = settings.dimensions.item_height,
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
	popup = {
		height = settings.dimensions.item_height,
		horizontal = false,
		background = {
			border_color = colors.blue,
			border_width = settings.dimensions.popup_border_width,
			color = colors.mantle,
			corner_radius = settings.dimensions.popup_background_corner_radius,
			shadow = {
				drawing = true,
			},
		},
	},
})
