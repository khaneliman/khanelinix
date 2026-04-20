#!/usr/bin/env lua

local settings = require("helpers.settings")
local colors = require("helpers.colors")
local icons = require("helpers.icons")
local logger = require("helpers.logger")

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

local popupVisible = false
local isActive = true
local process_monitor = require("items.stats.process_monitor")

local monitor = process_monitor(
	disk.name,
	264,
	" PID   PGINS   FLTS  PROC",
	colors.blue,
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
	function(row_string)
		local pid = row_string:match("^%s*(%d+)")
		local command = row_string:match("^%s*%d+%s+%d+%s+%d+%s+(.+)$")
		return pid, command
	end
)

local function refresh_disk()
	if not isActive then
		return
	end

	Sbar.exec("df -H | grep -E '^(/dev/disk3s1s1 ).' | awk '{ printf (\"%s\\n\", $5) }'", function(diskUsage)
		if IS_EMPTY(diskUsage) then
			logger.warn("disk", "empty_usage", {})
			return
		end
		disk:set({ label = diskUsage })
	end)

	if popupVisible then
		monitor.update()
	end
end

disk:subscribe({
	"routine",
	"forced",
	"system_woke",
}, refresh_disk)

disk:subscribe("mouse.clicked", function()
	logger.debug("disk", "open_activity_monitor", {})
	Sbar.exec("open -a 'Activity Monitor'")
end)

disk:subscribe("mouse.entered", function()
	popupVisible = true
	monitor.update()
	disk:set({ popup = { drawing = true } })
	logger.debug("disk", "popup_opened", {})
end)

disk:subscribe({
	"mouse.exited",
	"mouse.exited.global",
}, function()
	popupVisible = false
	disk:set({ popup = { drawing = false } })
	logger.debug("disk", "popup_closed", {})
end)

function disk.activate()
	if isActive then
		return
	end

	isActive = true
	refresh_disk()
end

function disk.deactivate()
	if not isActive then
		return
	end

	isActive = false
	popupVisible = false
	disk:set({ popup = { drawing = false } })
end

return disk
