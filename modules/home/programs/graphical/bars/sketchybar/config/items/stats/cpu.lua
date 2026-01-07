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
	update_freq = 2,
	position = "right",
})

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
end)

cpu:subscribe("mouse.clicked", function()
	Sbar.exec("open -a 'Activity Monitor'")
end)

return cpu
