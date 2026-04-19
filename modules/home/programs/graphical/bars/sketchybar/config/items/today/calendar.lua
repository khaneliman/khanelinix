#!/usr/bin/env lua
local settings = require("helpers.settings")
local logger = require("helpers.logger")

local today = {}

today.cal = Sbar.add("item", "date", {
	icon = {
		align = "right",
		padding_right = 0,
		font = {
			family = settings.font,
			style = "Black",
			size = 14.0,
		},
	},
	position = "right",
	update_freq = 60,
	width = 30,
	y_offset = 6,
})

today.clock = Sbar.add("item", "clock", {
	icon = {
		align = "right",
		padding_right = 0,
		font = {
			family = settings.font,
			style = "Bold",
			size = 12.0,
		},
	},
	label = {
		padding_left = -50,
	},
	background = {
		padding_left = 0,
		padding_right = -20,
	},
	position = "right",
	update_freq = 60,
	y_offset = -8,
})

local function date_update()
	if IS_SYSTEM_SLEEPING then
		logger.debug("today", "date_update_skipped_sleeping", {})
		return
	end
	local date = os.date("%a. %d %b.")
	today.cal:set({ icon = date })
end

local function clock_update()
	if IS_SYSTEM_SLEEPING then
		logger.debug("today", "clock_update_skipped_sleeping", {})
		return
	end
	local time = os.date("%I:%M %p")
	today.clock:set({ icon = time })
end

today.cal:subscribe({ "forced", "routine" }, date_update)
today.clock:subscribe({ "forced", "routine" }, clock_update)
