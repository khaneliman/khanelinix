#!/usr/bin/env lua
local colors = require("colors")
local icons = require("icons")
local power_config = require("power_config")
local settings = require("settings")

local keep_awake = Sbar.add("item", "keep_awake", {
	position = "right",
	update_freq = 60,
	icon = {
		string = icons.sleep,
		font = {
			family = settings.nerd_font,
			style = "Regular",
			size = 19.0,
		},
	},
	background = {
		drawing = false,
	},
	label = {
		drawing = false,
	},
	popup = {
		align = "right",
		height = 20,
	},
})

keep_awake.details = Sbar.add("item", "keep_awake.details", {
	position = "popup." .. keep_awake.name,
	click_script = "sketchybar --set keep_awake popup.drawing=off",
	background = {
		corner_radius = 12,
		padding_left = 5,
		padding_right = 10,
	},
	icon = {
		drawing = false,
	},
	label = {
		padding_right = 0,
		align = "center",
	},
})

local function update_item()
	Sbar.exec(power_config.clamshell .. " status", function(state)
		local enabled = (state or ""):match("on") ~= nil

		keep_awake:set({
			icon = {
				string = enabled and icons.power or icons.sleep,
				color = enabled and colors.green or colors.overlay1,
			},
		})

		keep_awake.details:set({
			label = {
				string = enabled and "Closed-lid awake enabled" or "Closed-lid awake disabled",
				color = enabled and colors.green or colors.text,
			},
		})
	end)
end

keep_awake:subscribe({
	"routine",
	"forced",
	"system_woke",
}, function(_)
	update_item()
end)

keep_awake:subscribe("mouse.clicked", function(info)
	if info.BUTTON == "right" then
		update_item()
		return
	end

	Sbar.exec(power_config.clamshell .. " status", function(state)
		local enabled = (state or ""):match("on") ~= nil
		local command = enabled and " disable" or " enable"

		Sbar.exec(power_config.clamshell .. command, function(_)
			update_item()
			DELAY(0.5, update_item)
		end)
	end)
end)

keep_awake:subscribe({
	"mouse.entered",
}, function(_)
	keep_awake:set({ popup = { drawing = true } })
end)

keep_awake:subscribe({
	"mouse.exited",
	"mouse.exited.global",
}, function(_)
	keep_awake:set({ popup = { drawing = false } })
end)

update_item()

return keep_awake
