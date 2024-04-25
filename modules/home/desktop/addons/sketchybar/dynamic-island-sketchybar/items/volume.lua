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

local update_co = nil -- Stores the running coroutine
local delay_finished = false

local function animate_show()
	print("Animating showing volume")
	Sbar.animate("tanh", 30.0, function()
		volume.slider:set({ slider = { width = 100 } })
		volume.icon:set({ label = { width = 25 } })
		Sbar.bar({ height = 80 })
	end)
	delay_finished = false
end

local function animate_hide()
	print("Animating hiding volume")
	Sbar.animate("tanh", 30.0, function()
		volume.slider:set({ slider = { width = 0 } })
		volume.icon:set({ label = { width = 0 } })
		Sbar.bar({ height = settings.default.height })
	end)
	delay_finished = true
end

volume.slider:subscribe("volume_change", function(env)
	local new_volume = tonumber(env.INFO)
	local icon = get_volume_icon(new_volume)

	volume.icon:set({ label = icon })
	volume.slider:set({ slider = { percentage = new_volume } })

	print("Updating volume")
	animate_show()

	if update_co and coroutine.status(update_co) == "running" then
		print("Closing coroutine")
		coroutine.close(update_co)
	end

	-- Create a new delay coroutine
	update_co = coroutine.create(function()
		print("Delay coroutine created")
		local start_time = os.time()
		local target_duration = 1

		while os.time() < start_time + target_duration do
			if delay_finished == true then
				print("Delay finished")
				return
			end
			os.execute("sleep .1")
		end

		print("Animating hiding volume")
		animate_hide()
	end)

	print("Resuming coroutine")
	coroutine.resume(update_co)
end)
return volume
