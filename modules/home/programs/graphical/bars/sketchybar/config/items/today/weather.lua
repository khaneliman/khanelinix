#!/usr/bin/env lua

local settings = require("settings")
local colors = require("colors")

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
	weather.temp:set({ popup = { drawing = false } })

	Sbar.exec("wttrbar --fahrenheit --ampm --location $(jq '.wttr.location' ~/weather_config.json)", function(forecast)
		for i, value in ipairs(STR_SPLIT(forecast.text)) do
			if i == 1 then
				weather.icon:set({ icon = { string = value } })
			end
			if i == 2 then
				weather.temp:set({ icon = "", label = { string = value .. "°" } })
			end
		end

		local existingEvents = weather.temp:query()
		if existingEvents.popup and next(existingEvents.popup.items) ~= nil then
			for _, item in pairs(existingEvents.popup.items) do
				Sbar.remove(item)
			end
		end

		weather.event = {}
		for i, line in ipairs(STR_SPLIT(forecast.tooltip, "\n")) do
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
	end)
end)

weather.temp:subscribe("mouse.entered", function()
	weather.temp:set({ popup = { drawing = true } })
end)

weather.temp:subscribe({
	"mouse.exited.global",
	"mouse.exited",
}, function()
	weather.temp:set({ popup = { drawing = false } })
end)

weather.temp:subscribe({
	"mouse.clicked",
}, function(info)
	if info.BUTTON == "left" then
		POPUP_TOGGLE(info.NAME)
	end

	if info.BUTTON == "right" then
		Sbar.trigger("weather_update")
	end
end)

weather.icon:subscribe({
	"mouse.clicked",
}, function(info)
	if info.BUTTON == "left" then
		POPUP_TOGGLE(info.NAME)
	end

	if info.BUTTON == "right" then
		Sbar.trigger("weather_update")
	end
end)
