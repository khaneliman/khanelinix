#!/usr/bin/env lua

local colors = require("helpers.colors")
local icons = require("helpers.icons")
local logger = require("helpers.logger")

local volume = {}

volume.slider = Sbar.add("slider", "volume.slider", 100, {
	position = "right",
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
	position = "right",
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

volume.slider:subscribe("mouse.clicked", function(env)
	logger.debug("volume", "slider_set", { percentage = tostring(env.PERCENTAGE) })
	Sbar.exec("osascript -e 'set volume output volume " .. env["PERCENTAGE"] .. "'")
end)

volume.slider:subscribe("volume_change", function(env)
	local new_volume = tonumber(env.INFO)
	if new_volume == nil then
		logger.warn("volume", "invalid_volume", { payload = tostring(env.INFO) })
		return
	end

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

	volume.icon:set({ label = icon })
	volume.slider:set({ slider = { percentage = new_volume } })
	logger.debug("volume", "volume_changed", { volume = new_volume, icon = tostring(icon) })
end)

local function animate_slider_width(width)
	Sbar.animate("tanh", 30.0, function()
		volume.slider:set({ slider = { width = width } })
	end)
end

volume.icon:subscribe("mouse.clicked", function()
	if tonumber(volume.slider:query().slider.width) > 0 then
		logger.debug("volume", "slider_hidden", {})
		animate_slider_width(0)
	else
		logger.debug("volume", "slider_shown", {})
		animate_slider_width(100)
	end
end)

return volume
