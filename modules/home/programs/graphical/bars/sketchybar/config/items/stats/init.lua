#!/usr/bin/env lua
local settings = require("helpers.settings")
local separator = require("items.stats.separator_right")
local cpu = require("items.stats.cpu")
local memory = require("items.stats.memory")
local disk = require("items.stats.disk")
local network = require("items.stats.network")

local stats = {}

local function activate_stats()
	cpu.activate()
	memory.activate()
	disk.activate()
	network.activate()
end

local function deactivate_stats()
	cpu.deactivate()
	memory.deactivate()
	disk.deactivate()
	network.deactivate()
end

stats.close = function()
	deactivate_stats()

	Sbar.animate("tanh", settings.animation.default_duration, function()
		cpu:set({ background = { padding_right = settings.collapse_padding.cpu } })
		memory:set({ background = { padding_right = settings.collapse_padding.memory } })
		disk:set({ background = { padding_right = settings.collapse_padding.disk } })
		network.up:set({ background = { padding_right = settings.offsets.network_stack_overlap } })
		network.down:set({ background = { padding_right = settings.collapse_padding.network } })
	end)

	separator:set({ icon = "" })

	DELAY(settings.animation.reveal_delay, function()
		cpu:set({ drawing = false })
		memory:set({ drawing = false })
		disk:set({ drawing = false })
		network.up:set({ drawing = false })
		network.down:set({ drawing = false })
	end)
end

stats.open = function()
	activate_stats()
	separator:set({ icon = "" })

	Sbar.animate("tanh", settings.animation.default_duration, function()
		cpu:set({ drawing = true })
		memory:set({ drawing = true })
		disk:set({ drawing = true })
		network.up:set({ drawing = true })
		network.down:set({ drawing = true })

		cpu:set({ background = { padding_right = settings.spacing.none } })
		memory:set({ background = { padding_right = settings.spacing.none } })
		disk:set({ background = { padding_right = settings.spacing.none } })
		network.up:set({ background = { padding_right = settings.offsets.network_stack_overlap } })
		network.down:set({ background = { padding_right = settings.spacing.none } })
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
