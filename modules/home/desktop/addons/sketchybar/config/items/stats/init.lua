#!/usr/bin/env lua

local separator = require("items.stats.separator_right")
local cpu = require("items.stats.cpu")
local memory = require("items.stats.memory")
local disk = require("items.stats.disk")
local network = require("items.stats.network")

local stats = {}

stats.close = function()
	Sbar.animate("tanh", 30, function()
		cpu:set({ background = { padding_right = -10 } })
		memory:set({ background = { padding_right = -50 } })
		disk:set({ background = { padding_right = -40 } })
		network.up:set({ background = { padding_right = -70 } })
		network.down:set({ background = { padding_right = -50 } })
	end)

	separator:set({ icon = "" })

	SLEEP(0.1)

	cpu:set({ drawing = false })
	memory:set({ drawing = false })
	disk:set({ drawing = false })
	network.up:set({ drawing = false })
	network.down:set({ drawing = false })
end

stats.open = function()
	separator:set({ icon = "" })

	Sbar.animate("tanh", 30, function()
		cpu:set({ drawing = true })
		memory:set({ drawing = true })
		disk:set({ drawing = true })
		network.up:set({ drawing = true })
		network.down:set({ drawing = true })

		cpu:set({ background = { padding_right = 0 } })
		memory:set({ background = { padding_right = 0 } })
		disk:set({ background = { padding_right = 0 } })
		network.up:set({ background = { padding_right = -70 } })
		network.down:set({ background = { padding_right = 0 } })
	end)
end

separator:subscribe("hide_stats", function()
	stats.close()
end)

separator:subscribe("show_stats", function()
	stats.open()
end)

separator:subscribe("toggle_stats", function()
	local state = separator:query().icon.value

	if state == "" then
		Sbar.trigger("show_stats")
	elseif state == "" then
		Sbar.trigger("hide_stats")
	end
end)
