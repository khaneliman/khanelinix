#!/usr/bin/env lua

local settings = require("helpers.settings")
local colors = require("helpers.colors")
local logger = require("helpers.logger")

local weather = {}

weather.icon = Sbar.add("item", "weather.icon", {
	icon = {
		align = "right",
		padding_left = settings.spacing.wide,
		padding_right = settings.spacing.tight,
		string = "",
		width = settings.widths.temperature_label,
	},
	background = {
		padding_right = settings.offsets.weather_icon_overlap,
	},
	position = "right",
	y_offset = settings.offsets.stack_top_y,
})

weather.temp = Sbar.add("item", "weather.temp", {
	icon = "",
	label = {
		align = "right",
		font = {
			features = settings.numeric_font_features,
			typographical_width = true,
		},
		padding_left = settings.spacing.none,
		padding_right = settings.spacing.none,
		string = "",
		width = settings.widths.temperature_label,
	},
	background = {
		padding_left = settings.spacing.compact,
		padding_right = settings.offsets.weather_temp_overlap,
	},
	popup = {
		align = "right",
		height = settings.dimensions.popup_height,
	},
	update_freq = 900,
	position = "right",
	y_offset = settings.offsets.stack_bottom_y,
})

weather.details = Sbar.add("item", "weather.details", {
	icon = {
		background = {
			height = settings.dimensions.rule_height,
			y_offset = settings.offsets.weather_rule_y,
		},
		font = {
			family = settings.font,
			style = "Bold",
			size = settings.font_sizes.popup_header,
		},
	},
	background = {
		corner_radius = settings.dimensions.popup_corner_radius,
	},
	drawing = false,
	padding_left = settings.spacing.regular,
	padding_right = settings.spacing.regular,
	click_script = "sketchybar --set $NAME popup.drawing=off",
})

local popupVisible = false
local latestForecast = nil
local lastRenderedSignature = nil

local function forecast_signature(forecast)
	return tostring(forecast.text or "") .. "|" .. tostring(forecast.tooltip or "")
end

local function apply_forecast_summary(forecast)
	logger.debug("weather", "forecast_updated", { text = forecast.text })
	for i, value in ipairs(STR_SPLIT(forecast.text)) do
		if i == 1 then
			weather.icon:set({ icon = { string = value } })
		end
		if i == 2 then
			weather.temp:set({ icon = "", label = { string = value .. "°" } })
		end
	end
end

local function render_forecast_tooltip()
	if latestForecast == nil or IS_EMPTY(latestForecast.tooltip) then
		return
	end

	local signature = forecast_signature(latestForecast)
	if signature == lastRenderedSignature then
		return
	end
	lastRenderedSignature = signature

	CLEAR_POPUP_ITEMS(weather.temp.name)

	local line_count = 0
	weather.event = {}
	for i, line in ipairs(STR_SPLIT(latestForecast.tooltip, "\n")) do
		line_count = line_count + 1
		if string.find(line, "<b>") then
			local replacedString = string.gsub(line, "<b>", "")
			replacedString = string.gsub(replacedString, "</b>", "")

			if i > 1 then
				weather.event.separator = Sbar.add("item", "weather.event.separator_" .. i, {
					icon = {
						string = "─────────────────",
						color = colors.grey,
						align = "center",
						font = {
							size = settings.font_sizes.stats_network_label,
						},
					},
					label = {
						drawing = false,
					},
					background = {
						height = settings.dimensions.separator_height,
					},
					padding_left = settings.spacing.none,
					padding_right = settings.spacing.none,
					position = "popup." .. weather.temp.name,
					click_script = "sketchybar --set $NAME popup.drawing=off",
				})
			end

			weather.event.title = Sbar.add("item", "weather.event.title_" .. i, {
				icon = {
					drawing = true,
					string = replacedString,
					font = {
						style = "Bold",
						size = settings.font_sizes.popup_title,
					},
					color = colors.yellow,
				},
				label = {
					drawing = false,
				},
				position = "popup." .. weather.temp.name,
				click_script = "sketchybar --set $NAME popup.drawing=off",
			})
		elseif string.find(line, "⬆") or string.find(line, "⬇") then
			weather.event[i] = Sbar.add("item", "weather.event." .. i, {
				icon = {
					drawing = false,
				},
				label = {
					string = line,
					drawing = true,
					font = {
						size = settings.font_sizes.popup_row,
						style = "Bold",
					},
				},
				position = "popup." .. weather.temp.name,
				click_script = "sketchybar --set $NAME popup.drawing=off",
			})

			Sbar.add("item", "weather.event.padding_highlow_" .. i, {
				icon = { drawing = false },
				label = { drawing = false },
				background = { height = settings.spacing.medium },
				position = "popup." .. weather.temp.name,
				width = "100%",
			})
		else
			local time, icon, temp, desc = line:match("^(%S+)%s+(%S+)%s+(%S+)%s+(.*)$")
			if time then
				local padded_time = string.format("%-5s", time)
				local short_desc = desc:match("^([^,]+)") or desc

				line = padded_time .. " " .. icon .. " " .. temp .. " " .. short_desc
			end

			weather.event[i] = Sbar.add("item", "weather.event." .. i, {
				icon = {
					drawing = false,
				},
				label = {
					string = line,
					drawing = true,
					font = {
						size = settings.font_sizes.popup_message,
					},
				},
				position = "popup." .. weather.temp.name,
				click_script = "sketchybar --set $NAME popup.drawing=off",
			})
		end
	end

	logger.debug("weather", "forecast_tooltip_rendered", { lines = line_count })
end

weather.temp:subscribe({ "routine", "forced", "system_woke", "weather_update" }, function()
	if IS_SYSTEM_SLEEPING then
		logger.debug("weather", "update_skipped_sleeping", {})
		return
	end

	Sbar.exec("wttrbar --fahrenheit --ampm --location $(jq '.wttr.location' ~/weather_config.json)", function(forecast)
		if IS_EMPTY(forecast) or IS_EMPTY(forecast.text) then
			logger.warn("weather", "empty_forecast", {})
			return
		end

		local signature = forecast_signature(forecast)
		latestForecast = forecast
		apply_forecast_summary(forecast)
		if popupVisible and signature ~= lastRenderedSignature then
			render_forecast_tooltip()
		end
	end)
end)

SETUP_STANDARD_CLICKS(weather.temp, "weather_update")
SETUP_POPUP_HOVER(weather.temp, function()
	popupVisible = true
	if latestForecast == nil then
		Sbar.trigger("weather_update")
		return
	end

	render_forecast_tooltip()
end, function()
	popupVisible = false
end)

SETUP_STANDARD_CLICKS(weather.icon, "weather_update")
