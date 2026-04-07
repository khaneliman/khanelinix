#!/usr/bin/env lua

local settings = require("settings")
local colors = require("colors")
local icons = require("icons")

Sbar.exec("killall sketchy_cpu_load >/dev/null 2>&1; sketchy_cpu_load cpu_update 2.0")

local cpu = Sbar.add("item", "cpu", {
	background = {
		padding_left = 0,
		padding_right = 0,
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
		string = icons.stats.cpu,
		color = colors.blue,
		font = {
			size = 15,
		},
	},
	position = "right",
	popup = {
		align = "right",
		height = 20,
	},
})

local popupWidth = 248

local cpu_header = Sbar.add("item", "cpu.details.header", {
	position = "popup." .. cpu.name,
	width = popupWidth,
	background = {
		padding_left = 10,
		padding_right = 10,
	},
	icon = {
		drawing = false,
	},
	label = {
		string = " PID    CPU  MEM  PROC",
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

local cpu_rows = {}
local cpu_row_pids = {}
local cpu_row_commands = {}
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
	cpu_rows[i] = Sbar.add("item", "cpu.details." .. i, {
		position = "popup." .. cpu.name,
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

	cpu_rows[i]:subscribe("mouse.clicked", function(env)
		local pid = cpu_row_pids[i]
		local command = cpu_row_commands[i]
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
		ps -Arcwwwxo pid=,%cpu=,%mem=,comm= | sort -k2 -nr | awk 'NR <= 5 {
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

			for i, row in ipairs(cpu_rows) do
				local row_string = lines[i] or ""
				local pid = row_string:match("^%s*(%d+)")
				local command = row_string:match("^%s*%d+%s+[%d%.]+%s+[%d%.]+%s+(.+)$")
				cpu_row_pids[i] = pid
				cpu_row_commands[i] = command

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

cpu:subscribe("cpu_update", function(env)
	-- Also available: env.user_load, env.sys_load
	local load = tonumber(env.total_load)

	local color = colors.text
	if load > 30 then
		if load < 60 then
			color = colors.yellow
		elseif load < 80 then
			color = colors.peach
		else
			color = colors.red
		end
	end

	cpu:set({
		label = {
			string = env.total_load .. "%",
			color = color,
		},
	})

	if popupVisible then
		update_top_processes()
	end
end)

cpu:subscribe("mouse.clicked", function()
	Sbar.exec("open -a 'Activity Monitor'")
end)

cpu:subscribe("mouse.entered", function()
	popupVisible = true
	update_top_processes()
	cpu:set({ popup = { drawing = true } })
end)

cpu:subscribe({
	"mouse.exited",
	"mouse.exited.global",
}, function()
	popupVisible = false
	cpu:set({ popup = { drawing = false } })
end)

return cpu
