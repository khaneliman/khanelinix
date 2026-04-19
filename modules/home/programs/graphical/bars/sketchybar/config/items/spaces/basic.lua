#!/usr/bin/env lua

local colors = require("helpers.colors")
local icons = require("helpers.icons")
local settings = require("helpers.settings")
local spaces_utils = require("items.spaces.utils")
local logger = require("helpers.logger")

local function getIcon(i)
	local numSpaces = #icons.spaces -- Get the number of entries in the spaces table
	local icon = icons.spaces["_" .. i]
	return icon or (i <= numSpaces and icons.spaces["_" .. i] or icons.spaces.default) -- Default to "X" if out of range
end

local spaces = {}
for i = 1, 10, 1 do
	local config = spaces_utils.get_space_item_config(getIcon(i), true)
	config.associated_space = i

	local space = Sbar.add("space", "space." .. i, config)

	spaces[i] = space.name
	space:subscribe("space_change", function(env)
		local color = env.SELECTED == "true" and colors.text or colors.overlay0
		logger.debug("spaces", "space_change", { name = env.NAME, selected = tostring(env.SELECTED) })

		Sbar.set(env.NAME, {
			icon = { highlight = env.SELECTED },
			label = { highlight = env.SELECTED },
			background = { border_color = color },
		})
	end)
	space:subscribe("mouse.clicked", function(env)
		logger.debug("spaces", "space_clicked", { button = env.BUTTON, sid = env.SID })
		if env.BUTTON == "right" then
			Sbar.exec("yabai -m space --destroy " .. env.SID .. " && sketchybar --trigger space_change")
		else
			Sbar.exec("yabai -m space --focus " .. env.SID)
		end
	end)
end

Sbar.add("bracket", spaces, {
	background = {
		color = colors.surface0,
		border_color = colors.surface1,
		border_width = 2,
	},
})

spaces.creator = Sbar.add("item", "spaces.creator", {
	padding_left = 10,
	padding_right = 8,
	icon = {
		string = "",
		font = {
			family = settings.nerd_font,
			style = "Regular",
			size = 16.0,
		},
	},
	label = { drawing = false },
	associated_display = "active",
})

spaces.creator:subscribe("mouse.clicked", function(_)
	logger.debug("spaces", "space_creator_clicked", {})
	Sbar.exec("yabai -m space --create && sketchybar --trigger space_change")
end)
