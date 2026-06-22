#!/usr/bin/env lua
local settings = require("helpers.settings")
local colors = require("helpers.colors")
local icons = require("helpers.icons")
local logger = require("helpers.logger")
local last_events = nil
local item_index = 0

local ical = Sbar.add("item", "ical", {
	icon = {
		align = "right",
		padding_left = settings.spacing.none,
		padding_right = settings.spacing.none,
		string = icons.ical,
		width = settings.widths.stack_item,
		font = {
			family = settings.nerd_font,
			style = "Black",
			size = settings.font_sizes.today_date,
		},
	},
	label = {
		drawing = false,
	},
	background = {
		padding_left = settings.spacing.none,
		padding_right = settings.spacing.none,
	},
	popup = {
		align = "right",
		height = settings.dimensions.popup_height,
	},
	position = "right",
	width = settings.widths.stack_item,
	y_offset = settings.offsets.stack_bottom_y,
	update_freq = 900,
})

local calendar_popup = {
	item = ical,
}
local popup_anchor = ical
local hover_targets = {}
local popup_targets = {}

local function popup_position()
	return "popup." .. popup_anchor.name
end

local function popup_off_script()
	return "sketchybar --set " .. popup_anchor.name .. " popup.drawing=off"
end

local function show_popup()
	popup_anchor:set({ popup = { drawing = true } })
end

local function hide_popup()
	popup_anchor:set({ popup = { drawing = false } })
end

local function setup_hover_target(target)
	if target == nil or target.name == nil or hover_targets[target.name] then
		return
	end

	hover_targets[target.name] = true

	target:subscribe("mouse.entered", function()
		show_popup()
	end)
	target:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
		hide_popup()
	end)
end

local function add_popup_item(name, config)
	local item = Sbar.add("item", name, config)
	setup_hover_target(item)
	return item
end

local function setup_popup_target(target)
	if target == nil or target.name == nil or popup_targets[target.name] then
		return
	end

	popup_targets[target.name] = true
	setup_hover_target(target)

	target:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "left" then
			POPUP_TOGGLE(popup_anchor.name)
		elseif env.BUTTON == "right" then
			Sbar.trigger("ical_update")
		end
	end)
end

function calendar_popup.attach_popup_targets(targets)
	for _, target in ipairs(targets) do
		setup_popup_target(target)
	end
end

function calendar_popup.set_popup_anchor(anchor)
	if anchor == nil or anchor.name == nil then
		return
	end

	if popup_anchor.name ~= anchor.name then
		hide_popup()
		CLEAR_POPUP_ITEMS(popup_anchor.name)
		last_events = nil
	end

	popup_anchor = anchor
	setup_hover_target(popup_anchor)
	popup_anchor:set({
		popup = {
			align = "right",
			height = settings.dimensions.popup_height,
		},
	})
end

local function update_events()
	item_index = 0

	if IS_SYSTEM_SLEEPING then
		logger.debug("ical", "update_skipped_sleeping", {})
		return
	end
	local SEP = "%"

	Sbar.exec("icalBuddy -nc -nrd -eed -iep datetime,title -b '' -ps '|" .. SEP .. "|' eventsToday", function(events)
		if IS_EMPTY(events) then
			logger.warn("ical", "empty_events", {})
			CLEAR_POPUP_ITEMS(popup_anchor.name)
			return
		end

		if events == last_events then
			return
		end
		last_events = events
		CLEAR_POPUP_ITEMS(popup_anchor.name)

		local has_all_day_header = false
		local has_separator = false
		local lines = STR_SPLIT(events, "\n")
		local max_length = 0
		local line_count = 0

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
			line_count = line_count + 1
			local title, time = line:match("^(.-)%s*%%(.*)$")

			if title and time then
				if has_all_day_header and not has_separator then
					local dashes = string.rep("─", math.floor(max_length * 0.65))
					add_popup_item(next_item_name("separator"), {
						icon = {
							string = "",
							width = settings.spacing.none,
						},
						label = {
							string = dashes,
							color = colors.grey,
							align = "center",
						},
						background = {
							height = settings.dimensions.separator_height,
						},
						padding_left = settings.spacing.none,
						padding_right = settings.spacing.none,
						position = popup_position(),
					})
					has_separator = true
				end
				add_popup_item(next_item_name("timed"), {
					icon = {
						string = time,
						color = colors.yellow,
						font = {
							style = "Bold",
							size = settings.font_sizes.popup_message,
						},
					},
					label = {
						string = title,
					},
					position = popup_position(),
					click_script = popup_off_script(),
				})
			else
				if not has_all_day_header then
					add_popup_item(next_item_name("all_day_header"), {
						icon = {
							string = "All Day",
							color = colors.yellow,
							font = {
								style = "Bold",
								size = settings.font_sizes.popup_message,
							},
						},
						label = {
							string = "",
						},
						position = popup_position(),
						click_script = popup_off_script(),
					})
					has_all_day_header = true
				end

				add_popup_item(next_item_name("all_day"), {
					icon = {
						string = "•",
						color = colors.white,
						font = {
							size = settings.font_sizes.popup_message,
						},
					},
					label = {
						string = line,
					},
					position = popup_position(),
					click_script = popup_off_script(),
				})
			end
		end

		add_popup_item(next_item_name("width_floor"), {
			icon = {
				drawing = false,
			},
			label = {
				drawing = false,
			},
			background = {
				height = settings.spacing.hairline,
			},
			padding_left = settings.spacing.none,
			padding_right = settings.spacing.none,
			position = popup_position(),
			width = settings.widths.today_popup_min,
		})

		logger.info("ical", "events_rendered", { count = line_count, total_lines = #lines })
	end)
end

ical:subscribe({ "routine", "forced", "ical_update" }, update_events)

setup_popup_target(ical)

return calendar_popup
