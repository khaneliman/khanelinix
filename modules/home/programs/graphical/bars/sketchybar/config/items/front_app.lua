#!/usr/bin/env lua
local settings = require("helpers.settings")
local icons = require("helpers.icons")
local colors = require("helpers.colors")
local wm_config = require("helpers.wm_config")
local logger = require("helpers.logger")

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
	local last_border_color = nil

	local function set_active_border_color(color)
		if last_border_color == color then
			return
		end

		last_border_color = color
		Sbar.exec("borders active_color=" .. COLOR_TO_HEX(color))
	end

	local function finish_yabai_update(icon_string, icon_color, label_string, label_drawing, border_color)
		yabai:set({
			icon = {
				string = icon_string,
				color = icon_color,
			},
			label = {
				string = label_string or "",
				drawing = label_drawing == true,
			},
		})

		set_active_border_color(border_color)
		update_yabai_icon = false
	end

	local function do_yabai_update()
		if is_sleeping then
			update_yabai_icon = false
			return
		end

		Sbar.exec("yabai -m query --windows --window", function(window)
			if type(window) ~= "table" then
				logger.warn("front_app", "query_failed", { payload = tostring(window) })
				update_yabai_icon = false
				return
			end

			local stackIndex = tonumber(window["stack-index"])
			local isFloating = window["is-floating"]

			if stackIndex and stackIndex > 0 then
				Sbar.exec("yabai -m query --windows --window stack.last", function(lastWindow)
					if type(lastWindow) ~= "table" then
						logger.warn("front_app", "stack_query_failed", { payload = tostring(lastWindow) })
						update_yabai_icon = false
						return
					end
					local lastStackIndex = tonumber(lastWindow["stack-index"]) or stackIndex

					finish_yabai_update(
						icons.yabai.stack,
						colors.red,
						string.format("[%s/%s]", stackIndex, lastStackIndex),
						true,
						colors.red
					)
				end)
			else
				local icon_string = icons.yabai.grid
				local icon_color = colors.peach

				if isFloating == true then
					icon_string = icons.yabai.float
					icon_color = colors.maroon
				elseif window["has-fullscreen-zoom"] == true then
					icon_string = icons.yabai.fullscreen_zoom
					icon_color = colors.green
				elseif window["has-parent-zoom"] == true then
					icon_string = icons.yabai.parent_zoom
					icon_color = colors.blue
				end

				finish_yabai_update(icon_string, icon_color, "", false, colors.blue)
			end
		end)
	end

	local function schedule_yabai_update(delay_seconds)
		if is_sleeping or update_yabai_icon then
			return
		end

		update_yabai_icon = true
		DELAY(delay_seconds, do_yabai_update)
	end

	yabai:subscribe("window_focus", function()
		logger.debug("front_app", "window_focus", {})
		schedule_yabai_update(0.1)
	end)

	yabai:subscribe("system_will_sleep", function()
		logger.debug("front_app", "system_will_sleep", {})
		is_sleeping = true
	end)

	yabai:subscribe("system_woke", function()
		is_sleeping = false
		logger.debug("front_app", "system_woke", {})
		schedule_yabai_update(2.0)
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
	logger.debug("front_app", "front_app_switched", { window = tostring(window_name) })

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
