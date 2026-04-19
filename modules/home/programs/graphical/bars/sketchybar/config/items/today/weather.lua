#!/usr/bin/env lua

local settings = require("helpers.settings")
local colors = require("helpers.colors")
local logger = require("helpers.logger")

local weather = {}

weather.icon = Sbar.add("item", "weather.icon", {
	icon = {
		align = "right",
		padding_left = 12,
		padding_right = 2,
		string = "",
	},
	background = {
		padding_right = -15,
	},
	position = "right",
	y_offset = 6,
})

weather.temp = Sbar.add("item", "weather.temp", {
	icon = "",
	label = {
		align = "right",
		padding_left = 0,
		padding_right = 0,
		string = "",
	},
	background = {
		padding_right = -30,
		padding_left = 5,
	},
	popup = {
		align = "right",
		height = 20,
	},
	update_freq = 900,
	position = "right",
	y_offset = -8,
})

weather.details = Sbar.add("item", "weather.details", {
	icon = {
		background = {
			height = 2,
			y_offset = -12,
		},
		font = {
			family = settings.font,
			style = "Bold",
			size = 14.0,
		},
	},
	background = {
		corner_radius = 12,
	},
	drawing = false,
	padding_right = 7,
	padding_left = 7,
	click_script = "sketchybar --set $NAME popup.drawing=off",
})

weather.temp:subscribe({ "routine", "forced", "system_woke", "weather_update" }, function()
	if IS_SYSTEM_SLEEPING then
		logger.debug("weather", "update_skipped_sleeping", {})
		return
	end

	weather.temp:set({ popup = { drawing = false } })

	Sbar.exec("wttrbar --fahrenheit --ampm --location $(jq '.wttr.location' ~/weather_config.json)", function(forecast)
		if IS_EMPTY(forecast) or IS_EMPTY(forecast.text) then
			logger.warn("weather", "empty_forecast", {})
			return
		end

		logger.debug("weather", "forecast_updated", { text = forecast.text })
		for i, value in ipairs(STR_SPLIT(forecast.text)) do
			if i == 1 then
				weather.icon:set({ icon = { string = value } })
			end
			if i == 2 then
				weather.temp:set({ icon = "", label = { string = value .. "°" } })
			end
		end

		CLEAR_POPUP_ITEMS(weather.temp.name)

		local line_count = 0
		weather.event = {}
		for i, line in ipairs(STR_SPLIT(forecast.tooltip, "\n")) do
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
								size = 10.0,
							},
						},
						label = {
							drawing = false,
						},
						background = {
							height = 1,
						},
						padding_left = 0,
						padding_right = 0,
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
							size = 16.0,
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
							size = 13.0,
							style = "Bold",
						},
					},
					position = "popup." .. weather.temp.name,
					click_script = "sketchybar --set $NAME popup.drawing=off",
				})

				Sbar.add("item", "weather.event.padding_highlow_" .. i, {
					icon = { drawing = false },
					label = { drawing = false },
					background = { height = 8 },
					position = "popup." .. weather.temp.name,
					width = "100%",
				})
			else
				-- Clean up and align the line
				local time, icon, temp, desc = line:match("^(%S+)%s+(%S+)%s+(%S+)%s+(.*)$")
				if time then
					-- Pad time to fixed length (e.g., 5 chars)
					local padded_time = string.format("%-5s", time)

					-- Truncate description at first comma
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
							size = 12.0,
						},
					},
					position = "popup." .. weather.temp.name,
					click_script = "sketchybar --set $NAME popup.drawing=off",
				})
			end
		end
		logger.debug("weather", "forecast_tooltip_rendered", { lines = line_count })
	end)
end)

SETUP_STANDARD_CLICKS(weather.temp, "weather_update")
SETUP_POPUP_HOVER(weather.temp)

SETUP_STANDARD_CLICKS(weather.icon, "weather_update")
