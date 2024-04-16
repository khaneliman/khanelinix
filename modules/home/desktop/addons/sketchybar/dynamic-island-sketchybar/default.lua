#!/usr/bin/env lua

local settings = require("settings")

-- Equivalent to the --default domain
Sbar.default({
	updates = "when_shown",
	icon = {
		color = settings.colors.text,
		font = {
			family = settings.nerd_font,
			style = "Bold",
			size = 14.0,
		},
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
	label = {
		color = settings.colors.text,
		font = {
			family = settings.font,
			style = "Semibold",
			size = 13.0,
		},
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
	background = {
		padding_left = settings.paddings,
		padding_right = settings.paddings,
	},
})

print("Loaded sbar.default")
