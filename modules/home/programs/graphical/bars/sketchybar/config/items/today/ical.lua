#!/usr/bin/env lua
-- luacheck: globals IS_SYSTEM_SLEEPING

local settings = require("settings")
local colors = require("colors")
local icons = require("icons")
local popup_items = {}
local last_events = nil
local item_index = 0

local function clear_popup_items()
	for _, item_name in ipairs(popup_items) do
		Sbar.remove(item_name)
	end
	popup_items = {}
end

local function add_popup_item(item_name, properties)
	table.insert(popup_items, item_name)
	return Sbar.add("item", item_name, properties)
end

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

-- Update function
ical:subscribe({ "routine", "forced" }, function()
	if IS_SYSTEM_SLEEPING then
		return
	end
	local SEP = "%"

	Sbar.exec("icalBuddy -nc -nrd -eed -iep datetime,title -b '' -ps '|" .. SEP .. "|' eventsToday", function(events)
		if events == last_events then
			return
		end
		last_events = events
		clear_popup_items()

		local has_all_day_header = false
		local has_separator = false
		local lines = STR_SPLIT(events, "\n")
		local max_length = 0

		local function next_item_name(prefix)
			item_index = item_index + 1
			return "ical.popup." .. prefix .. "." .. tostring(item_index)
		end

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

					add_popup_item(next_item_name("separator"), {
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
				add_popup_item(next_item_name("timed"), {
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
					add_popup_item(next_item_name("all_day_header"), {
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

				add_popup_item(next_item_name("all_day"), {
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
