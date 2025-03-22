#!/usr/bin/env lua

local settings = require("settings")
local colors = require("colors")

-- Equivalent to the --default domain
Sbar.default({
	updates = "when_shown",
	icon = {
		color = colors.text,
		font = {
			family = settings.nerd_font,
			style = "Bold",
			size = 20.0,
			features = "liga,dlig,calt,zero,ss01,ss02,ss03,ss04,ss05,ss06,ss07,ss08,ss09,ss10",
		},
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
	label = {
		color = colors.text,
		font = {
			family = settings.font,
			style = "Semibold",
			size = 13.0,
		},
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
	background = {
		corner_radius = 9,
		height = 30,
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
	popup = {
		height = 30,
		horizontal = false,
		background = {
			border_color = colors.blue,
			border_width = 2,
			color = colors.mantle,
			corner_radius = 11,
			shadow = {
				drawing = true,
			},
		},
	},
})
