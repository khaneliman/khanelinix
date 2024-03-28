#!/usr/bin/env lua

local colors = require("colors")

Sbar.add("item", "skhd", {
	icon = {
		string = "N",
		color = colors.blue,
		padding_left = 10,
		padding_right = 5,
	},
	background = {
		color = colors.surface0,
		border_color = colors.surface1,
		border_width = 2,
	},
	drawing = false,
	position = "left",
})
