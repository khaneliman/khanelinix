#!/usr/bin/env lua

local settings = require("settings")
local colors = require("colors")
local icons = require("icons")

local memory = Sbar.add("item", "memory", {
	background = {
		padding_left = 0,
	},
	label = {
		font = {
			family = settings.font,
			size = 12.0,
			style = "Heavy",
		},
		color = colors.text,
	},
	icon = {
		string = icons.stats.memory,
		color = colors.green,
		font = {
			size = 15,
		},
	},
	update_freq = 15,
	position = "right",
})

memory:subscribe({
	"routine",
	"forced",
	"system_woke",
}, function()
	Sbar.exec(
		"memory_pressure | grep 'System-wide memory free percentage:' | awk '{ printf(\"%02.0f\\n\", 100-$5\"%\") }'",
		function(memoryUsage)
			memory:set({ label = memoryUsage .. "%" })
		end
	)
end)

return memory
