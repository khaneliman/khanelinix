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
	popup = {
		align = "right",
		height = 20,
	},
	update_freq = 60,
	position = "right",
})

local popupWidth = 264

local disk_header = Sbar.add("item", "disk.details.header", {
	position = "popup." .. disk.name,
	width = popupWidth,
	background = {
		padding_left = 10,
		padding_right = 10,
	},
	icon = {
		drawing = false,
	},
	label = {
		string = " PID   PGINS   FLTS  PROC",
		font = {
			family = settings.nerd_font,
			size = 11.0,
			style = "Bold",
		},
		align = "left",
		color = colors.blue,
		width = "100%",
	},
})

local disk_rows = {}
local disk_row_pids = {}
local disk_row_commands = {}
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
	disk_rows[i] = Sbar.add("item", "disk.details." .. i, {
		position = "popup." .. disk.name,
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

	disk_rows[i]:subscribe("mouse.clicked", function(env)
		local pid = disk_row_pids[i]
		local command = disk_row_commands[i]
		if env.BUTTON == "right" and pid ~= nil and not protectedProcesses[command] then
			Sbar.exec("kill -TERM " .. pid .. " >/dev/null 2>&1 || true")
			Sbar.exec("sleep 0.2", update_top_processes)
		end
	end)
end

local popupVisible = false

update_top_processes = function()
	Sbar.exec(
		[=[
		top -l 1 -o pageins -stats pid,command,pageins,faults,mem | awk '
			/^PID[[:space:]]+COMMAND/ {
				capture = 1
				next
			}
			capture && count < 5 && NF >= 5 {
				cmd = $2
				if (length(cmd) > 16) {
					cmd = substr(cmd, 1, 16)
				}
				printf "%5s  %6s  %5s  %s\n", $1, $3, $4, cmd
				count++
			}
		'
	]=],
		function(result)
			local lines = {}

			for line in (result or ""):gmatch("[^\r\n]+") do
				table.insert(lines, line)
			end

			for i, row in ipairs(disk_rows) do
				local row_string = lines[i] or ""
				local pid = row_string:match("^%s*(%d+)")
				local command = row_string:match("^%s*%d+%s+%d+%s+%d+%s+(.+)$")
				disk_row_pids[i] = pid
				disk_row_commands[i] = command

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

disk:subscribe({
	"routine",
	"forced",
	"system_woke",
}, function()
	Sbar.exec("df -H | grep -E '^(/dev/disk3s1s1 ).' | awk '{ printf (\"%s\\n\", $5) }'", function(diskUsage)
		disk:set({ label = diskUsage })
	end)

	if popupVisible then
		update_top_processes()
	end
end)

disk:subscribe("mouse.clicked", function()
	Sbar.exec("open -a 'Activity Monitor'")
end)

disk:subscribe("mouse.entered", function()
	popupVisible = true
	update_top_processes()
	disk:set({ popup = { drawing = true } })
end)

disk:subscribe({
	"mouse.exited",
	"mouse.exited.global",
}, function()
	popupVisible = false
	disk:set({ popup = { drawing = false } })
end)

return disk
