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
local event_limit = settings.calendar.event_limit
local title_width = settings.calendar.title_width
local char_width = settings.calendar.char_width
local separator = "|%|"
local separator_arg = "/" .. separator .. "/"

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

local function next_item_name(prefix)
	item_index = item_index + 1
	return "ical.popup." .. prefix .. "." .. tostring(item_index)
end

local function split_lines(value)
	local lines = {}
	for line in (tostring(value or "") .. "\n"):gmatch("([^\r\n]*)\r?\n") do
		if line ~= "" then
			table.insert(lines, line)
		end
	end
	return lines
end

local function split_plain(value, sep)
	local parts = {}
	local start = 1

	while true do
		local next_start, next_end = tostring(value or ""):find(sep, start, true)
		if next_start == nil then
			table.insert(parts, tostring(value or ""):sub(start))
			break
		end

		table.insert(parts, tostring(value or ""):sub(start, next_start - 1))
		start = next_end + 1
	end

	return parts
end

local function compact_time_part(value)
	local text = STR_TRIM(value):gsub("^%d%d%d%d%-%d%d%-%d%d%s+", "")
	local hour, minute, suffix = text:match("^(%d?%d):(%d%d)%s*([AP]M)$")

	if hour == nil then
		return text
	end

	local hour_number = tonumber(hour) or 0
	local compact_minute = minute == "00" and "" or ":" .. minute
	return tostring(hour_number) .. compact_minute .. suffix:sub(1, 1):lower()
end

local function compact_datetime(value)
	local text = STR_TRIM(value)
	if text == "" or text:match("^%d%d%d%d%-%d%d%-%d%d$") then
		return "All day"
	end

	local left, right = text:match("^(.-)%s+%-%s+(.*)$")
	if left and right then
		local start_time = compact_time_part(left)
		local end_time = compact_time_part(right)
		local start_suffix = start_time:sub(-1)
		local end_suffix = end_time:sub(-1)

		if (start_suffix == "a" or start_suffix == "p") and start_suffix == end_suffix then
			start_time = start_time:sub(1, -2)
		end

		return start_time .. "-" .. end_time
	end

	if text:match("%d?%d:%d%d%s*[AP]M") then
		return compact_time_part(text)
	end

	return "All day"
end

local function minutes_from_datetime(value)
	local text = STR_TRIM(value):gsub("^%d%d%d%d%-%d%d%-%d%d%s+", "")
	local hour, minute, suffix = text:match("^(%d?%d):(%d%d)%s*([AP]M)")

	if hour == nil then
		return -1
	end

	local hour_number = tonumber(hour) or 0
	if suffix == "PM" and hour_number < 12 then
		hour_number = hour_number + 12
	elseif suffix == "AM" and hour_number == 12 then
		hour_number = 0
	end

	return hour_number * 60 + (tonumber(minute) or 0)
end

local function weekday_label(year, month, day)
	local weekday_names = {
		[0] = "Sat",
		[1] = "Sun",
		[2] = "Mon",
		[3] = "Tue",
		[4] = "Wed",
		[5] = "Thu",
		[6] = "Fri",
	}
	local month_names = {
		"Jan",
		"Feb",
		"Mar",
		"Apr",
		"May",
		"Jun",
		"Jul",
		"Aug",
		"Sep",
		"Oct",
		"Nov",
		"Dec",
	}

	local normalized_year = year
	local normalized_month = month
	if normalized_month < 3 then
		normalized_month = normalized_month + 12
		normalized_year = normalized_year - 1
	end

	local year_of_century = normalized_year % 100
	local zero_based_century = math.floor(normalized_year / 100)
	local weekday = (
		day
		+ math.floor((13 * (normalized_month + 1)) / 5)
		+ year_of_century
		+ math.floor(year_of_century / 4)
		+ math.floor(zero_based_century / 4)
		+ (5 * zero_based_century)
	) % 7

	return weekday_names[weekday] .. " " .. month_names[month] .. " " .. tostring(day)
end

local function date_label(value)
	local year, month, day = tostring(value or ""):match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
	if year == nil then
		return value
	end

	local parsed_year = tonumber(year)
	local parsed_month = tonumber(month)
	local parsed_day = tonumber(day)
	if parsed_year == nil or parsed_month == nil or parsed_day == nil then
		return value
	end

	local today = os.date("%Y-%m-%d")
	local tomorrow = os.date("%Y-%m-%d", os.time() + 86400)

	if value == today then
		return "Today"
	elseif value == tomorrow then
		return "Tomorrow"
	end

	return weekday_label(parsed_year, parsed_month, parsed_day)
end

local function has_url(value)
	return tostring(value or ""):match("^https?://") ~= nil
end

local function has_attendees(value)
	local text = tostring(value or "")
	return text:match("@") ~= nil or text:match(",") ~= nil
end

local function event_badge(event)
	local badges = {}

	for _, detail in ipairs(event.details) do
		local text = STR_TRIM(detail)
		local lower = text:lower()

		if has_url(text) then
			table.insert(badges, "󰖟")
		elseif has_attendees(text) then
			table.insert(badges, "󰀉")
		elseif lower:find("microsoft teams", 1, true) then
			table.insert(badges, "")
		elseif text ~= "" then
			table.insert(badges, "")
		end
	end

	return table.concat(badges, " ")
end

local function event_label(event)
	local badge = event_badge(event)
	return badge == "" and event.title or badge .. "  " .. event.title
end

local function text_length(value)
	local text = tostring(value or "")
	local _, count = text:gsub("[^\128-\191]", "")
	return count
end

local function rendered_layout(groups)
	local max_label_length = #"No events in next 7 days"
	local rendered = 0

	for _, group in ipairs(groups) do
		if #group.events > 0 and rendered < event_limit then
			max_label_length = math.max(max_label_length, text_length(date_label(group.date)))

			for _, event in ipairs(group.events) do
				if rendered < event_limit then
					max_label_length =
						math.max(max_label_length, math.min(text_length(event_label(event)), title_width))
					rendered = rendered + 1
				end
			end
		end
	end

	local desired_label_width = math.ceil(max_label_length * char_width) + settings.spacing.popup_wide
	local popup_width = math.min(
		settings.widths.today_popup_max,
		math.max(settings.widths.today_popup, settings.widths.today_popup_time + desired_label_width)
	)

	return {
		popup_width = popup_width,
		label_width = popup_width - settings.widths.today_popup_time,
		time_width = settings.widths.today_popup_time,
	}
end

local function truncate_to_width(value, label_width)
	local limit = math.floor((label_width - settings.spacing.popup_wide) / char_width)
	return TRUNCATE_TEXT(value, math.min(title_width, math.max(12, limit)))
end

local function parse_events(output)
	local groups = {}
	local current_group = nil

	for _, raw_line in ipairs(split_lines(output)) do
		local line = STR_TRIM(raw_line)

		if line ~= "" and line:match("^%-+$") == nil then
			if line:find(separator, 1, true) == nil then
				local section_date = line:match("(%d%d%d%d%-%d%d%-%d%d)")
				if section_date ~= nil then
					current_group = {
						date = section_date,
						events = {},
					}
					table.insert(groups, current_group)
				elseif current_group ~= nil then
					table.insert(current_group.events, {
						title = line,
						datetime = "",
						details = {},
					})
				end
			elseif current_group ~= nil then
				local parts = split_plain(line, separator)
				local title = STR_TRIM(parts[1])
				local datetime = STR_TRIM(parts[2])
				local details = {}

				for index = 3, #parts do
					local detail = STR_TRIM(parts[index])
					if detail ~= "" then
						table.insert(details, detail)
					end
				end

				if title ~= "" then
					table.insert(current_group.events, {
						title = title,
						datetime = datetime,
						details = details,
					})
				end
			end
		end
	end

	for _, group in ipairs(groups) do
		table.sort(group.events, function(left, right)
			local left_minutes = minutes_from_datetime(left.datetime)
			local right_minutes = minutes_from_datetime(right.datetime)

			if left_minutes ~= right_minutes then
				return left_minutes < right_minutes
			end

			return left.title < right.title
		end)
	end

	return groups
end

local function add_message_row(message, color, layout)
	local row_layout = layout
		or {
			label_width = settings.widths.today_popup_label,
			time_width = settings.widths.today_popup_time,
		}
	add_popup_item(next_item_name("message"), {
		icon = {
			string = icons.ical,
			color = color or colors.yellow,
			font = {
				family = settings.nerd_font,
				size = settings.font_sizes.popup_message,
			},
			width = row_layout.time_width,
		},
		label = {
			string = truncate_to_width(message, row_layout.label_width),
			width = row_layout.label_width,
		},
		position = popup_position(),
		click_script = popup_off_script(),
	})
end

local function add_width_floor(layout)
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
		width = (layout and layout.popup_width) or settings.widths.today_popup,
	})
end

local function add_day_spacer(layout)
	add_popup_item(next_item_name("day_spacer"), {
		icon = {
			drawing = false,
		},
		label = {
			drawing = false,
		},
		background = {
			height = settings.spacing.medium,
		},
		padding_left = settings.spacing.none,
		padding_right = settings.spacing.none,
		position = popup_position(),
		width = (layout and layout.popup_width) or settings.widths.today_popup,
	})
end

local function render_groups(groups)
	local rendered = 0
	local omitted = 0
	local has_rendered_group = false
	local layout = rendered_layout(groups)

	for _, group in ipairs(groups) do
		if #group.events > 0 then
			if rendered >= event_limit then
				omitted = omitted + #group.events
			else
				if has_rendered_group then
					add_day_spacer(layout)
				end

				add_popup_item(next_item_name("day"), {
					icon = {
						string = date_label(group.date),
						color = colors.blue,
						font = {
							style = "Bold",
							size = settings.font_sizes.popup_message,
						},
						width = layout.time_width,
					},
					label = {
						string = "",
						width = layout.label_width,
					},
					position = popup_position(),
					click_script = popup_off_script(),
				})
				has_rendered_group = true

				for _, event in ipairs(group.events) do
					if rendered >= event_limit then
						omitted = omitted + 1
					else
						local label = truncate_to_width(event_label(event), layout.label_width)

						add_popup_item(next_item_name("event"), {
							icon = {
								string = compact_datetime(event.datetime),
								color = colors.yellow,
								font = {
									style = "Bold",
									size = settings.font_sizes.popup_message,
									features = settings.numeric_font_features,
								},
								width = layout.time_width,
							},
							label = {
								string = label,
								width = layout.label_width,
							},
							position = popup_position(),
							click_script = popup_off_script(),
						})

						rendered = rendered + 1
					end
				end
			end
		end
	end

	if rendered == 0 and omitted == 0 then
		add_message_row("No events in next 7 days", colors.subtext0, layout)
	elseif omitted > 0 then
		add_popup_item(next_item_name("omitted"), {
			icon = {
				string = "",
				width = layout.time_width,
			},
			label = {
				string = "+ " .. tostring(omitted) .. " more",
				color = colors.subtext0,
				width = layout.label_width,
			},
			position = popup_position(),
			click_script = popup_off_script(),
		})
	end

	add_width_floor(layout)
	return rendered, omitted
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

	local command = "icalBuddy -sd -nrd -npn -df '%Y-%m-%d' -tf '%I:%M %p' -b '' -ps "
		.. SHELL_QUOTE(separator_arg)
		.. " -po title,datetime,location,url,notes,attendees"
		.. " -iep title,datetime,location,url,notes,attendees"
		.. " -nnr ' ' -nnc 180 -na 8 eventsToday+7"

	Sbar.exec(command, function(events)
		if events == last_events then
			return
		end

		last_events = events
		CLEAR_POPUP_ITEMS(popup_anchor.name)

		if IS_EMPTY(events) then
			add_message_row("No events in next 7 days", colors.subtext0)
			add_width_floor()
			logger.warn("ical", "empty_events", {})
			return
		end

		if events:match("^%s*error:") then
			add_message_row(TRUNCATE_TEXT(STR_TRIM(events), title_width), colors.red)
			add_width_floor()
			logger.warn("ical", "command_error", { message = STR_TRIM(events) })
			return
		end

		local groups = parse_events(events)
		local rendered, omitted = render_groups(groups)
		logger.info("ical", "events_rendered", { count = rendered, omitted = omitted, groups = #groups })
	end)
end

ical:subscribe({ "routine", "forced", "ical_update" }, update_events)

setup_popup_target(ical)

return calendar_popup
