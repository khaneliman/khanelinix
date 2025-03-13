#!/usr/bin/env lua

local settings = require("settings")
local colors = require("colors")
local icons = require("icons")

local disk = Sbar.add("item", "disk", {
	background = {
		padding_left = 5,
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
		string = icons.stats.disk,
		color = colors.blue,
		font = {
			size = 16,
		},
	},
	update_freq = 60,
	position = "right",
})

disk:subscribe({
	"routine",
	"forced",
	"system_woke",
}, function()
	Sbar.exec("df -H | grep -E '^(/dev/disk3s1s1 ).' | awk '{ printf (\"%s\\n\", $5) }'", function(diskUsage)
		disk:set({ label = diskUsage })
	end)
end)

return disk
