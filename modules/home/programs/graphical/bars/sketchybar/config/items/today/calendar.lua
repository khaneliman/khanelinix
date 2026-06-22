#!/usr/bin/env lua
local settings = require("helpers.settings")
local logger = require("helpers.logger")

local today = {}

today.cal = Sbar.add("item", "date", {
	icon = {
		align = "left",
		padding_left = settings.offsets.today_date_indent,
		padding_right = settings.spacing.none,
		font = {
			family = settings.font,
			style = "Black",
			size = settings.font_sizes.today_date,
			features = settings.numeric_font_features,
			typographical_width = true,
		},
		width = settings.widths.date_label,
	},
	position = "right",
	update_freq = 60,
	width = settings.widths.stack_item,
	y_offset = settings.offsets.stack_top_y,
})

today.clock = Sbar.add("item", "clock", {
	icon = {
		align = "left",
		padding_left = settings.offsets.today_time_indent,
		padding_right = settings.spacing.none,
		font = {
			family = settings.font,
			style = "Bold",
			size = settings.font_sizes.today_time,
			features = settings.numeric_font_features,
			typographical_width = true,
		},
		width = settings.widths.time_label,
	},
	label = {
		padding_left = settings.offsets.clock_label_overlap,
	},
	background = {
		padding_left = settings.spacing.none,
		padding_right = settings.offsets.clock_background_overlap,
	},
	popup = {
		align = "right",
		height = settings.dimensions.popup_height,
	},
	position = "right",
	update_freq = 1,
	y_offset = settings.offsets.stack_bottom_y,
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
	local time = os.date("%I:%M:%S %p")
	today.clock:set({ icon = time })
end

today.cal:subscribe({ "forced", "routine" }, date_update)
today.clock:subscribe({ "forced", "routine" }, clock_update)

return today
