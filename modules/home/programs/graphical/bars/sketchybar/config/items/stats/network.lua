#!/usr/bin/env lua
local settings = require("settings")
local colors = require("colors")
local icons = require("icons")

local network = {}

Sbar.exec("killall sketchy_network_load >/dev/null 2>&1; sketchy_network_load en0 network_update 10.0")

network.down = Sbar.add("item", "network.down", {
	background = {
		padding_left = 0,
	},
	label = {
		font = {
			family = settings.font,
			size = 10.0,
			style = "Heavy",
		},
		color = colors.text,
	},
	icon = {
		font = {
			family = settings.nerd_font,
			size = 16.0,
			style = "Bold",
		},
		string = icons.stats.network_down,
		color = colors.green,
		highlight_color = colors.blue,
	},
	popup = {
		align = "right",
		height = 20,
	},
	position = "right",
	y_offset = -7,
})

local popupWidth = 252

network.up = Sbar.add("item", "network.up", {
	background = {
		padding_right = -70,
	},
	label = {
		font = {
			family = settings.font,
			size = 10.0,
			style = "Heavy",
		},
		color = colors.text,
	},
	icon = {
		font = {
			family = settings.nerd_font,
			size = 16.0,
			style = "Bold",
		},
		string = icons.stats.network_up,
		color = colors.green,
		highlight_color = colors.blue,
	},
	position = "right",
	y_offset = 7,
})

network.header = Sbar.add("item", "network.details.header", {
	position = "popup." .. network.down.name,
	width = popupWidth,
	background = {
		padding_left = 10,
		padding_right = 10,
	},
	icon = {
		drawing = false,
	},
	label = {
		string = " PROC              IN        OUT",
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

network.rows = {}
local updateTopConnections
local recentProcesses = {}
local recentOrder = {}
local recentTtlSeconds = 20
for i = 1, 5 do
	network.rows[i] = Sbar.add("item", "network.details." .. i, {
		position = "popup." .. network.down.name,
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
end

local popupVisible = false

local function formatBytes(bytes)
	local value = tonumber(bytes) or 0
	local units = { "B", "K", "M", "G" }
	local unitIndex = 1

	while value >= 1024 and unitIndex < #units do
		value = value / 1024
		unitIndex = unitIndex + 1
	end

	if unitIndex == 1 then
		return string.format("%4d%s", value, units[unitIndex])
	end

	return string.format("%4.1f%s", value, units[unitIndex])
end

local function touchRecentProcess(proc, inb, outb, isActive)
	recentProcesses[proc] = {
		inb = inb,
		outb = outb,
		isActive = isActive,
		lastSeen = os.time(),
	}

	for index, value in ipairs(recentOrder) do
		if value == proc then
			table.remove(recentOrder, index)
			break
		end
	end

	table.insert(recentOrder, 1, proc)
end

local function expireRecentProcesses()
	local now = os.time()
	local nextOrder = {}

	for _, proc in ipairs(recentOrder) do
		local entry = recentProcesses[proc]
		if entry ~= nil and (now - entry.lastSeen) <= recentTtlSeconds then
			table.insert(nextOrder, proc)
		else
			recentProcesses[proc] = nil
		end
	end

	recentOrder = nextOrder
end

updateTopConnections = function()
	Sbar.exec(
		[=[
		nettop -P -d -L 2 -J bytes_in,bytes_out -x -n 2>/dev/null | awk -F, '
			$2 == "bytes_in" && $3 == "bytes_out" {
				headerCount++
				next
			}
			headerCount < 2 {
				next
			}
			NF >= 4 {
				proc = $1
				sub(/\.[0-9]+$/, "", proc)
				gsub(/^ +| +$/, "", proc)
				inb = $2 + 0
				outb = $3 + 0
				total = inb + outb
				if (proc != "" && total > 0) {
					printf "%s,%s,%s,%s\n", total, proc, inb, outb
				}
			}
		' | sort -t, -k1,1nr | head -n 5
	]=],
		function(result)
			local activeProcesses = {}
			local visibleRows = {}

			for line in (result or ""):gmatch("[^\r\n]+") do
				local _, proc, inb, outb = line:match("^([^,]+),([^,]+),([^,]+),([^,]+)$")
				if proc ~= nil then
					local shortProc = proc
					if #shortProc > 16 then
						shortProc = shortProc:sub(1, 16)
					end

					touchRecentProcess(shortProc, inb, outb, true)
					activeProcesses[shortProc] = true
					table.insert(
						visibleRows,
						string.format("%-16s  %7s  %7s", shortProc, formatBytes(inb), formatBytes(outb))
					)
				end
			end

			for proc, entry in pairs(recentProcesses) do
				if not activeProcesses[proc] then
					entry.inb = 0
					entry.outb = 0
					entry.isActive = false
				end
			end

			expireRecentProcesses()

			for _, proc in ipairs(recentOrder) do
				if #visibleRows >= #network.rows then
					break
				end

				if not activeProcesses[proc] then
					local entry = recentProcesses[proc]
					if entry ~= nil then
						table.insert(
							visibleRows,
							string.format("%-16s  %7s  %7s", proc, formatBytes(entry.inb), formatBytes(entry.outb))
						)
					end
				end
			end

			for i, row in ipairs(network.rows) do
				row:set({
					label = {
						string = visibleRows[i] or "",
					},
				})
			end
		end
	)
end

network.down:subscribe("network_update", function(env)
	if IS_SYSTEM_SLEEPING then
		return
	end
	local up_color = (env.upload == "000 Bps") and colors.subtext0 or colors.green
	local down_color = (env.download == "000 Bps") and colors.subtext0 or colors.blue
	network.up:set({
		icon = { color = up_color },
		label = {
			string = env.upload,
		},
	})
	network.down:set({
		icon = { color = down_color },
		label = {
			string = env.download,
		},
	})

	if popupVisible then
		updateTopConnections()
	end
end)

local function refreshPopupLoop()
	if not popupVisible then
		return
	end

	updateTopConnections()
	DELAY(1, refreshPopupLoop)
end

local function showPopup()
	if popupVisible then
		return
	end

	popupVisible = true
	network.down:set({ popup = { drawing = true } })
	refreshPopupLoop()
end

local function hidePopup()
	popupVisible = false
	network.down:set({ popup = { drawing = false } })
end

network.down:subscribe("mouse.entered", showPopup)
network.up:subscribe("mouse.entered", showPopup)

network.down:subscribe({
	"mouse.exited",
	"mouse.exited.global",
}, hidePopup)

network.up:subscribe({
	"mouse.exited",
	"mouse.exited.global",
}, hidePopup)

return network
