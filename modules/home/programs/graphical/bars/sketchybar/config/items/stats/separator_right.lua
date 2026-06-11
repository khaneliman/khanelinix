#!/usr/bin/env lua

local colors = require("helpers.colors")
local settings = require("helpers.settings")
local logger = require("helpers.logger")

local separator_right = Sbar.add("item", "separator_right", {
	background = {
		padding_left = settings.spacing.large,
		padding_right = settings.spacing.large,
	},
	label = {
		drawing = false,
	},
	icon = {
		string = "",
		color = colors.text,
	},
	position = "right",
})

separator_right:subscribe("mouse.clicked", function()
	logger.debug("stats", "toggle_stats_requested", {})
	Sbar.trigger("toggle_stats")
end)

return separator_right
