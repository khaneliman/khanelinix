#!/usr/bin/env lua

local settings = require("helpers.settings")
local colors = require("helpers.colors")
local icons = require("helpers.icons")
local logger = require("helpers.logger")

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

local helper_command = "killall sketchy_cpu_load >/dev/null 2>&1; sketchy_cpu_load cpu_update 2.0"
local stop_helper_command = "killall sketchy_cpu_load >/dev/null 2>&1"
local popupVisible = false
local isActive = true
local process_monitor = require("items.stats.process_monitor")

local monitor = process_monitor(
	cpu.name,
	248,
	" PID    CPU  MEM  PROC",
	colors.blue,
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
	function(row_string)
		local pid = row_string:match("^%s*(%d+)")
		local command = row_string:match("^%s*%d+%s+[%d%.]+%s+[%d%.]+%s+(.+)$")
		return pid, command
	end
)

local function start_helper()
	Sbar.exec(helper_command)
end

local function stop_helper()
	Sbar.exec(stop_helper_command)
end

start_helper()

cpu:subscribe("cpu_update", function(env)
	if not isActive then
		return
	end
	-- Also available: env.user_load, env.sys_load
	local load = tonumber(env.total_load)
	if load == nil then
		logger.warn("cpu", "parse_failed", { payload = tostring(env.total_load) })
		return
	end

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
	logger.debug("cpu", "load_updated", { load = load, color = tostring(color) })

	if popupVisible then
		monitor.update()
	end
end)

cpu:subscribe("mouse.clicked", function()
	logger.debug("cpu", "open_activity_monitor", {})
	Sbar.exec("open -a 'Activity Monitor'")
end)

cpu:subscribe("mouse.entered", function()
	popupVisible = true
	monitor.update()
	cpu:set({ popup = { drawing = true } })
	logger.debug("cpu", "popup_opened", {})
end)

cpu:subscribe({
	"mouse.exited",
	"mouse.exited.global",
}, function()
	popupVisible = false
	cpu:set({ popup = { drawing = false } })
	logger.debug("cpu", "popup_closed", {})
end)

function cpu.activate()
	if isActive then
		return
	end

	isActive = true
	start_helper()
end

function cpu.deactivate()
	if not isActive then
		return
	end

	isActive = false
	popupVisible = false
	cpu:set({ popup = { drawing = false } })
	stop_helper()
end

return cpu
