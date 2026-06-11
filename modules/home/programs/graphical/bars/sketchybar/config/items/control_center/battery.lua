#!/usr/bin/env lua

local icons = require("helpers.icons")
local settings = require("helpers.settings")
local colors = require("helpers.colors")
local logger = require("helpers.logger")
local percent = 0

local battery = Sbar.add("item", "battery", {
	position = "right",
	click_script = "sketchybar --set $NAME popup.drawing=toggle",
	icon = {
		font = {
			family = settings.nerd_font,
			style = "Regular",
			size = settings.font_sizes.control_icon,
		},
	},
	label = {
		drawing = false,
		font = {
			features = settings.numeric_font_features,
			typographical_width = true,
		},
		align = "right",
		width = settings.widths.percent_label,
	},
	update_freq = 120,
})

battery.details = Sbar.add("item", "battery.details", {
	position = "popup." .. battery.name,
	click_script = "sketchybar --set $NAME popup.drawing=off",
	background = {
		corner_radius = settings.dimensions.popup_corner_radius,
		padding_left = settings.spacing.compact,
		padding_right = settings.spacing.large,
	},
	icon = {
		background = {
			height = settings.dimensions.rule_height,
			y_offset = settings.offsets.battery_rule_y,
		},
	},
	label = {
		padding_right = settings.spacing.none,
		align = "center",
		font = {
			features = settings.numeric_font_features,
			typographical_width = true,
		},
		width = settings.widths.percent_label,
	},
})

battery:subscribe({
	"routine",
	"forced",
	"power_source_change",
	"system_woke",
}, function(_)
	logger.debug("battery", "refresh", {})
	Sbar.exec("pmset -g batt", function(batt_info)
		if IS_EMPTY(batt_info) then
			logger.warn("battery", "pmset_empty", {})
			return
		end

		local icon = "!"
		local color = colors.green
		local charging = string.find(batt_info, "AC Power")
		local previous_percent = percent

		local thresholds = {
			{
				percent = 100,
				charging_icon = icons.battery.charging._100,
				non_charging_icon = icons.battery.non_charging._100,
				color = colors.green,
			},
			{
				percent = 90,
				charging_icon = icons.battery.charging._90,
				non_charging_icon = icons.battery.non_charging._90,
				color = colors.green,
			},
			{
				percent = 80,
				charging_icon = icons.battery.charging._80,
				non_charging_icon = icons.battery.non_charging._80,
				color = colors.green,
			},
			{
				percent = 70,
				charging_icon = icons.battery.charging._70,
				non_charging_icon = icons.battery.non_charging._70,
				color = colors.green,
			},
			{
				percent = 60,
				charging_icon = icons.battery.charging._60,
				non_charging_icon = icons.battery.non_charging._60,
				color = colors.yellow,
			},
			{
				percent = 50,
				charging_icon = icons.battery.charging._50,
				non_charging_icon = icons.battery.non_charging._50,
				color = colors.yellow,
			},
			{
				percent = 40,
				charging_icon = icons.battery.charging._40,
				non_charging_icon = icons.battery.non_charging._40,
				color = colors.peach,
			},
			{
				percent = 30,
				charging_icon = icons.battery.charging._30,
				non_charging_icon = icons.battery.non_charging._30,
				color = colors.peach,
			},
			{
				percent = 20,
				charging_icon = icons.battery.charging._20,
				non_charging_icon = icons.battery.non_charging._20,
				color = colors.red,
			},
			{
				percent = 10,
				charging_icon = icons.battery.charging._10,
				non_charging_icon = icons.battery.non_charging._10,
				color = colors.red,
			},
			{
				percent = 0,
				charging_icon = icons.battery.charging._0,
				non_charging_icon = icons.battery.non_charging._0,
				color = colors.red,
			},
		}

		local found, _, charge = batt_info:find("(%d+)%%")
		if found then
			local parsedPercent = tonumber(charge)
			if parsedPercent then
				percent = parsedPercent
			end
		else
			logger.warn("battery", "percent_parse_failed", { output = batt_info })
		end

		if percent ~= previous_percent then
			logger.info("battery", "charge_changed", { previous = previous_percent, current = percent })
		end

		if percent <= 15 then
			logger.warn("battery", "low_battery", { percent = percent, charging = (charging ~= nil) })
		end

		for _, threshold in ipairs(thresholds) do
			if percent >= threshold.percent then
				icon = charging and threshold.charging_icon or threshold.non_charging_icon
				color = threshold.color
				break
			end
		end

		battery:set({
			icon = {
				string = icon,
				color = color,
			},
			label = percent .. "%",
		})

		if percent < 50 then
			battery:set({
				label = { string = percent .. "%", drawing = true },
			})
		else
			battery:set({
				label = { string = percent .. "%", drawing = false },
			})
		end
	end)
end)

battery:subscribe({
	"mouse.exited",
	"mouse.exited.global",
}, function(_)
	battery:set({ popup = { drawing = false } })
end)

battery:subscribe({
	"mouse.entered",
}, function(_)
	if percent > 49 then
		battery:set({ popup = { drawing = true } })
	end

	battery.details:set({ label = percent .. "%" })
end)

return battery
