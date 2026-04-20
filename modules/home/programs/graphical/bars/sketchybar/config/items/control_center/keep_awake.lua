#!/usr/bin/env lua
local colors = require("helpers.colors")
local icons = require("helpers.icons")
local power_config = require("helpers.power_config")
local settings = require("helpers.settings")
local logger = require("helpers.logger")

local power_modes = Sbar.add("item", "power_modes", {
	position = "right",
	update_freq = 300,
	icon = {
		string = icons.sleep,
		font = {
			family = settings.nerd_font,
			style = "Regular",
			size = 19.0,
		},
	},
	background = {
		drawing = false,
	},
	label = {
		drawing = false,
	},
	popup = {
		align = "right",
		height = 20,
	},
})

local popup_position = "popup." .. power_modes.name

power_modes.summary = Sbar.add("item", "power_modes.summary", {
	position = popup_position,
	background = {
		corner_radius = 12,
		padding_left = 8,
		padding_right = 12,
	},
	icon = {
		string = icons.power,
		padding_right = 8,
	},
	label = {
		padding_right = 0,
		align = "left",
	},
	click_script = "sketchybar --set power_modes popup.drawing=off",
})

power_modes.awake = Sbar.add("item", "power_modes.awake", {
	position = popup_position,
	background = {
		corner_radius = 12,
		padding_left = 8,
		padding_right = 12,
	},
	icon = {
		string = icons.sleep,
		padding_right = 8,
	},
	label = {
		padding_right = 0,
		align = "left",
	},
})

power_modes.clamshell = Sbar.add("item", "power_modes.clamshell", {
	position = popup_position,
	background = {
		corner_radius = 12,
		padding_left = 8,
		padding_right = 12,
	},
	icon = {
		string = icons.power,
		padding_right = 8,
	},
	label = {
		padding_right = 0,
		align = "left",
	},
})

local function parse_snapshot(output)
	local states = {
		awake = false,
		clamshell = false,
	}

	for line in string.gmatch(output or "", "[^\n]+") do
		local key, value = string.match(line, "^(%w+)=([%w_-]+)$")
		if key ~= nil and value ~= nil then
			states[key] = value == "on"
		end
	end

	return states
end

local function popup_label(title, subtitle, enabled)
	local state_text = enabled and "On" or "Off"
	return string.format("%s: %s  |  %s", title, state_text, subtitle)
end

local function update_item()
	Sbar.exec(power_config.clamshell .. " snapshot", function(output)
		if IS_EMPTY(output) then
			logger.warn("keep_awake", "snapshot_empty", {})
			return
		end

		local states = parse_snapshot(output)
		local active_count = 0
		if states.awake then
			active_count = active_count + 1
		end
		if states.clamshell then
			active_count = active_count + 1
		end

		local icon_string = active_count > 0 and icons.power or icons.sleep
		local icon_color = colors.overlay1
		local summary_text = "No power overrides active"
		local summary_color = colors.text

		if states.awake and states.clamshell then
			icon_color = colors.peach
			summary_text = "Keep Awake and Clamshell active"
			summary_color = colors.peach
		elseif states.clamshell then
			icon_color = colors.green
			summary_text = "Clamshell active"
			summary_color = colors.green
		elseif states.awake then
			icon_color = colors.blue
			summary_text = "Keep Awake active"
			summary_color = colors.blue
		end

		logger.debug("keep_awake", "state_updated", { awake = states.awake, clamshell = states.clamshell })
		power_modes:set({
			icon = {
				string = icon_string,
				color = icon_color,
			},
		})

		power_modes.summary:set({
			icon = {
				color = icon_color,
			},
			label = {
				string = summary_text,
				color = summary_color,
			},
		})

		power_modes.awake:set({
			icon = {
				color = states.awake and colors.blue or colors.overlay1,
			},
			label = {
				string = popup_label("Keep Awake", "Prevent idle sleep while open", states.awake),
				color = states.awake and colors.blue or colors.text,
			},
		})

		power_modes.clamshell:set({
			icon = {
				color = states.clamshell and colors.green or colors.overlay1,
			},
			label = {
				string = popup_label("Clamshell", "Allow closed-lid operation", states.clamshell),
				color = states.clamshell and colors.green or colors.text,
			},
		})
	end)
end

local function toggle_mode(mode)
	logger.debug("keep_awake", "toggle_requested", { mode = mode })
	Sbar.exec(power_config.clamshell .. " " .. mode .. " toggle", function(_)
		update_item()
		DELAY(0.5, update_item)
	end)
end

power_modes:subscribe({
	"routine",
	"forced",
	"system_woke",
}, function(_)
	update_item()
end)

power_modes:subscribe("mouse.clicked", function(info)
	if info.BUTTON == "right" then
		update_item()
		return
	end

	POPUP_TOGGLE(power_modes.name)
end)

power_modes.awake:subscribe("mouse.clicked", function()
	toggle_mode("awake")
end)

power_modes.clamshell:subscribe("mouse.clicked", function()
	toggle_mode("clamshell")
end)

update_item()

return power_modes
