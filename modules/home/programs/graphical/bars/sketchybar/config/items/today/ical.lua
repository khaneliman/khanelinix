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
		local has_all_day_header = false
		local has_separator = false
		local lines = STR_SPLIT(events, "\n")
		local max_length = 0

		for _, line in ipairs(lines) do
			if #line > max_length then
				max_length = #line
			end
		end

		for _, line in ipairs(lines) do
			local title, time = line:match("^(.-)%s*%%(.*)$")

			if title and time then
				if has_all_day_header and not has_separator then
					local dashes = string.rep("─", math.floor(max_length * 0.65))

					Sbar.add("item", "ical_event_separator", {
						icon = {
							string = "",
							width = 0,
						},
						label = {
							string = dashes,
							color = colors.grey,
							align = "center",
						},
						background = {
							height = 1,
						},
						padding_left = 0,
						padding_right = 0,
						position = "popup." .. ical.name,
					})
					has_separator = true
				end
				Sbar.add("item", "ical_event_" .. title, {
					icon = {
						string = time,
						color = colors.yellow,
						font = {
							style = "Bold",
							size = 12.0,
						},
					},
					label = {
						string = title,
					},
					position = "popup." .. ical.name,
					click_script = "sketchybar --set $NAME popup.drawing=off",
				})
			else
				if not has_all_day_header then
					Sbar.add("item", "ical_event_all_day_header", {
						icon = {
							string = "All Day",
							color = colors.yellow,
							font = {
								style = "Bold",
								size = 12.0,
							},
						},
						label = {
							string = "",
						},
						position = "popup." .. ical.name,
						click_script = "sketchybar --set $NAME popup.drawing=off",
					})
					has_all_day_header = true
				end

				Sbar.add("item", "ical_event_" .. line, {
					icon = {
						string = "•",
						color = colors.white,
						font = {
							size = 12.0,
						},
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
