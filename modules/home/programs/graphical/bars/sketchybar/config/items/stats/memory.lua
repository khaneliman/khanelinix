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

local popupWidth = 248

local memory_header = Sbar.add("item", "memory.details.header", {
	position = "popup." .. memory.name,
	width = popupWidth,
	background = {
		padding_left = 10,
		padding_right = 10,
	},
	icon = {
		drawing = false,
	},
	label = {
		string = " PID    MEM  CPU  PROC",
		font = {
			family = settings.nerd_font,
			size = 11.0,
			style = "Bold",
		},
		align = "left",
		color = colors.green,
		width = "100%",
	},
})

local memory_rows = {}
local memory_row_pids = {}
local memory_row_commands = {}
local update_top_processes
local protectedProcesses = {
	WindowServer = true,
	kernel_task = true,
	launchd = true,
	loginwindow = true,
	SystemUIServer = true,
	tccd = true,
	nix = true,
}
for i = 1, 5 do
	memory_rows[i] = Sbar.add("item", "memory.details." .. i, {
		position = "popup." .. memory.name,
		width = popupWidth,
		background = {
			padding_left = 10,
			padding_right = 10,
		},
		icon = {
			drawing = false,
		},
		label = {
			string = "",
			font = {
				family = settings.nerd_font,
				size = 11.0,
				style = "Regular",
			},
			align = "left",
			color = colors.text,
			width = "100%",
		},
	})

	memory_rows[i]:subscribe("mouse.clicked", function(env)
		local pid = memory_row_pids[i]
		local command = memory_row_commands[i]
		if env.BUTTON == "right" and pid ~= nil and not protectedProcesses[command] then
			Sbar.exec("kill -TERM " .. pid .. " >/dev/null 2>&1 || true")
			Sbar.exec("sleep 0.2", update_top_processes)
		end
	end)
end

local popupVisible = false

update_top_processes = function()
	Sbar.exec(
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
		function(result)
			local lines = {}

			for line in (result or ""):gmatch("[^\r\n]+") do
				table.insert(lines, line)
			end

			for i, row in ipairs(memory_rows) do
				local row_string = lines[i] or ""
				local pid = row_string:match("^%s*(%d+)")
				local command = row_string:match("^%s*%d+%s+[%d%.]+%s+[%d%.]+%s+(.+)$")
				memory_row_pids[i] = pid
				memory_row_commands[i] = command

				row:set({
					label = {
						string = row_string,
						color = protectedProcesses[command] and colors.yellow or colors.text,
					},
				})
			end
		end
	)
end

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
		update_top_processes()
	end
end)

memory:subscribe("mouse.clicked", function()
	Sbar.exec("open -a 'Activity Monitor'")
end)

memory:subscribe("mouse.entered", function()
	popupVisible = true
	update_top_processes()
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
