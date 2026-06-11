#!/usr/bin/env lua

local colors = require("helpers.colors")
local settings = require("helpers.settings")

Sbar.add("item", "skhd", {
	icon = {
		string = "N",
		color = colors.blue,
		padding_left = settings.spacing.large,
		padding_right = settings.spacing.compact,
	},
	background = {
		color = colors.surface0,
		border_color = colors.surface1,
		border_width = settings.dimensions.popup_border_width,
	},
	drawing = false,
	position = "left",
})
