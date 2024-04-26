#!/usr/bin/env lua

local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- Unload the macOS on screen indicator overlay for volume change
Sbar.exec("launchctl unload -F /System/Library/LaunchAgents/com.apple.OSDUIHelper.plist >/dev/null 2>&1 &")

local volume = {}

volume.slider = Sbar.add("slider", "volume.slider", 100, {
	position = "center",
	updates = true,
	label = { drawing = false },
	icon = { drawing = false },
	slider = {
		highlight_color = colors.blue,
		width = 0,
		background = {
			height = 6,
			corner_radius = 3,
			color = colors.bg2,
		},
		knob = {
			string = "􀀁",
			drawing = false,
		},
	},
})

volume.icon = Sbar.add("item", "volume.icon", {
	position = "center",
	icon = {
		string = icons.volume._100,
		width = 0,
		align = "left",
		color = colors.grey,
		font = {
			style = "Regular",
			size = 14.0,
		},
	},
	label = {
		width = 25,
		align = "left",
		font = {
			style = "Regular",
			size = 14.0,
		},
	},
})

local function get_volume_icon(new_volume)
	local icon = icons.volume._0

	if new_volume > 60 then
		icon = icons.volume._100
	elseif new_volume > 30 then
		icon = icons.volume._66
	elseif new_volume > 10 then
		icon = icons.volume._33
	elseif new_volume > 0 then
		icon = icons.volume._10
	end

	return icon
end

local animation_co = nil -- Stores the running coroutine
local sleep_co = nil -- Stores the running coroutine
local end_time = nil

local function animate_show()
	print("Animating showing volume")
	Sbar.animate("tanh", 30.0, function()
		volume.slider:set({ slider = { width = 100 } })
		volume.icon:set({ label = { width = 25 } })
		Sbar.bar({ height = 80 })
	end)
end

local function animate_hide()
	print("Animating hiding volume")
	Sbar.animate("tanh", 30.0, function()
		volume.slider:set({ slider = { width = 0 } })
		volume.icon:set({ label = { width = 0 } })
		Sbar.bar({ height = settings.default.height })
	end)
end

volume.slider:subscribe("volume_change", function(env)
	print("--")
	local new_volume = tonumber(env.INFO)
	local icon = get_volume_icon(new_volume)

	volume.icon:set({ label = icon })
	volume.slider:set({ slider = { percentage = new_volume } })

	-- Create a new delay coroutine
	animation_co = coroutine.create(function()
		print("Delay coroutine created")

		print("Showing overlay")
		animate_show()

		print("Pausing animation routine")
		coroutine.yield()

		print("Hiding overlay")
		animate_hide()
	end)

	print("Starting animation coroutine")
	coroutine.resume(animation_co)

	if end_time then
		print("end time: " .. end_time)
	end

	print("current time: " .. os.time())
	if end_time == nil then
		end_time = os.time() + 3
	end

	print("Creating sleep coroutine")
	sleep_co = coroutine.create(function()
		print("starting sleep loop")
		print("current time: " .. os.time())
		print("end time: " .. end_time)
		while os.time() < end_time do
			-- print("yielding sleep routine")
			coroutine.yield()
		end

		print("Continuing animation coroutine")
		coroutine.resume(animation_co)
		end_time = nil
		sleep_co = nil
	end)

	print("Starting sleep coroutine")
	coroutine.resume(sleep_co)

	print("continuing to check for resuming sleep routine")
	if sleep_co and coroutine.status(sleep_co) == "suspended" then
		print("Resuming sleep coroutine since it's suspended")
		-- coroutine.close(sleep_co)
		-- while os.time() < end_time do
		coroutine.resume(sleep_co)
		-- end
	end
	-- while os.time() < start_time + target_duration do
	-- coroutine.resume(sleep_co)
	-- end
end)

return volume
