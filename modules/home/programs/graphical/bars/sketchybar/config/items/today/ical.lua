#!/usr/bin/env lua

local settings = require("settings")
local colors = require("colors")
local icons = require("icons")

local ical = Sbar.add("item", "ical", {
	icon = {
		align = "left",
		padding_right = 0,
		string = icons.ical,
		font = {
			family = settings.nerd_font,
			style = "Black",
			size = 14.0,
		},
	},
	background = {
		padding_left = 10,
	},
	popup = {
		align = "right",
		height = 20,
	},
	position = "right",
	y_offset = -8,
	update_freq = 900,
})

ical.details = Sbar.add("item", "ical.details", {
	icon = {
		drawing = false,
		background = {
			corner_radius = 12,
		},
		padding_left = 7,
		padding_right = 7,
		font = {
			family = settings.font,
			style = "Bold",
			size = 14.0,
		},
	},
	position = "popup." .. ical.name,
	click_script = "sketchybar --set $NAME popup.drawing=off",
})

-- Update function
ical:subscribe({ "routine", "forced" }, function()
	-- Constants
	local SEP = "%" -- Separator for icalBuddy output

	-- Reset popup state
	ical:set({ popup = { drawing = false } })

	-- Fetch events from calendar
	Sbar.exec("icalBuddy -nc -nrd -eed -iep datetime,title -b '' -ps '|" .. SEP .. "|' eventsToday", function(events)
		-- Clear existing events
		local existingEvents = ical:query()
		if existingEvents.popup and next(existingEvents.popup.items) ~= nil then
			for _, item in pairs(existingEvents.popup.items) do
				Sbar.remove(item)
			end
		end

		-- Parse and organize events
		for _, line in ipairs(STR_SPLIT(events, "\n")) do
			local title, time = line:match("^(.-)%s*%%(.*)$")

			if title and time then
				Sbar.add("item", "ical_event_" .. title, {
					icon = {
						string = time,
						color = colors.yellow,
					},
					label = {
						string = title,
					},
					position = "popup." .. ical.name,
					click_script = "sketchybar --set $NAME popup.drawing=off",
				})
			else
				Sbar.add("item", "ical_event_" .. line, {
					icon = {
						color = colors.yellow,
					},
					label = {
						string = line,
					},
					position = "popup." .. ical.name,
					click_script = "sketchybar --set $NAME popup.drawing=off",
				})
			end
		end
	end)
end)

ical:subscribe("mouse.entered", function()
	ical:set({ popup = { drawing = true } })
end)

ical:subscribe({
	"mouse.exited.global",
	"mouse.exited",
}, function()
	ical:set({ popup = { drawing = false } })
end)

ical:subscribe({
	"mouse.clicked",
}, function(info)
	if info.BUTTON == "left" then
		POPUP_TOGGLE(info.NAME)
	end

	if info.BUTTON == "right" then
		Sbar.trigger("brew_update")
	end
end)
