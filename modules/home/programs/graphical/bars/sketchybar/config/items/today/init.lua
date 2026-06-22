#!/usr/bin/env lua

local calendar = require("items.today.calendar")
local ical = require("items.today.ical")

ical.set_popup_anchor(calendar.clock)
ical.attach_popup_targets({
	calendar.cal,
	calendar.clock,
})

require("items.today.weather")
