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
	popup = {
		align = "right",
		height = 20,
	},
	update_freq = 60,
	position = "right",
})

local popupVisible = false
local process_monitor = require("items.stats.process_monitor")

local monitor = process_monitor(
	memory.name,
	248,
	" PID    MEM  CPU  PROC",
	colors.green,
	[[
		ps -Arcwwwxo pid=,%mem=,%cpu=,comm= | sort -k2 -nr | awk 'NR <= 5 {
				cmd = $4
				sub(".*/", "", cmd)
				if (length(cmd) > 16) {
					cmd = substr(cmd, 1, 16)
				}
				printf "%5s  %4.1f %4.1f  %s\n", $1, $2, $3, cmd
			}'
	]],
	function(row_string)
		local pid = row_string:match("^%s*(%d+)")
		local command = row_string:match("^%s*%d+%s+[%d%.]+%s+[%d%.]+%s+(.+)$")
		return pid, command
	end
)

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

	if popupVisible then
		monitor.update()
	end
end)

memory:subscribe("mouse.clicked", function()
	Sbar.exec("open -a 'Activity Monitor'")
end)

memory:subscribe("mouse.entered", function()
	popupVisible = true
	monitor.update()
	memory:set({ popup = { drawing = true } })
end)

memory:subscribe({
	"mouse.exited",
	"mouse.exited.global",
}, function()
	popupVisible = false
	memory:set({ popup = { drawing = false } })
end)

return memory
