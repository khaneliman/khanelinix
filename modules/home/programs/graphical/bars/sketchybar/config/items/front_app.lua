#!/usr/bin/env lua
-- luacheck: globals IS_SYSTEM_SLEEPING

local settings = require("settings")
local icons = require("icons")
local colors = require("colors")
local wm_config = require("wm_config")

if wm_config.use_yabai then
	local yabai = Sbar.add("item", "yabai", {
		icon = {
			color = colors.peach,
			font = {
				family = settings.font,
				size = 16.0,
				style = "Bold",
			},
			width = 30,
			string = icons.yabai.grid,
		},
		label = { drawing = false },
	})

	local is_sleeping = false
	local update_yabai_icon = false

	local function do_yabai_update()
		if is_sleeping then
			update_yabai_icon = false
			return
		end

		Sbar.exec("yabai -m query --windows --window", function(window)
			local stackIndex = tonumber(window["stack-index"])
			local isFloating = window["is-floating"]

			if stackIndex and stackIndex > 0 then
				Sbar.exec("yabai -m query --windows --window stack.last", function(lastWindow)
					local lastStackIndex = tonumber(lastWindow["stack-index"])

					yabai:set({
						icon = {
							string = icons.yabai.stack,
							color = colors.red,
						},
						label = {
							string = string.format("[%s/%s]", stackIndex, lastStackIndex),
							drawing = true,
						},
					})

					Sbar.exec("borders active_color=" .. COLOR_TO_HEX(colors.red))
				end)
			else
				if isFloating == true then
					yabai:set({
						icon = {
							string = icons.yabai.float,
							color = colors.maroon,
						},
					})
				elseif window["has-fullscreen-zoom"] == true then
					yabai:set({
						icon = {
							string = icons.yabai.fullscreen_zoom,
							color = colors.green,
						},
					})
				elseif window["has-parent-zoom"] == true then
					yabai:set({
						icon = {
							string = icons.yabai.parent_zoom,
							color = colors.blue,
						},
					})
				else
					yabai:set({
						icon = {
							string = icons.yabai.grid,
							color = colors.peach,
						},
					})
				end
			end

			yabai:set({
				label = {
					drawing = false,
				},
			})

			Sbar.exec("borders active_color=" .. COLOR_TO_HEX(colors.blue))
			update_yabai_icon = false
		end)
	end

	yabai:subscribe("window_focus", function()
		if is_sleeping or update_yabai_icon then
			return
		end
		update_yabai_icon = true
		Sbar.exec("sleep 0.1", do_yabai_update)
	end)

	yabai:subscribe("system_will_sleep", function()
		is_sleeping = true
	end)

	yabai:subscribe("system_woke", function()
		is_sleeping = false
		if not update_yabai_icon then
			update_yabai_icon = true
			Sbar.exec("sleep 2.0", do_yabai_update)
		end
	end)
end

local front_app = Sbar.add("item", "front_app", {
	icon = {
		drawing = false,
	},
	background = {
		padding_left = 0,
	},
	display = "active",
	label = {
		color = colors.text,
		font = {
			family = settings.font,
			style = "Black",
			size = 12.0,
		},
	},
})

front_app:subscribe("front_app_switched", function(env)
	if IS_SYSTEM_SLEEPING then
		return
	end
	local window_name = env.INFO

	local window_rewrite_map = {
		["wezterm-gui"] = "WezTerm",
	}

	if window_rewrite_map[window_name] then
		window_name = window_rewrite_map[window_name]
	end

	front_app:set({
		label = {
			string = window_name,
		},
	})
end)
