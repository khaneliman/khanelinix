#!/usr/bin/env lua

local colors = require("colors")
local app_icons = require("app_icons")
local settings = require("settings")

local spaces = {}

for i = 1, 10, 1 do
	local space = Sbar.add("space", {
		associated_space = i,
		icon = {
			string = i,
			padding_left = 7,
			padding_right = 7,
			color = colors.text,
			highlight_color = colors.getRandomCatColor(),
			font = { family = settings.font, size = 14 },
		},
		padding_left = 2,
		padding_right = 2,
		label = {
			padding_left = 6,
			padding_right = 12,
			color = colors.grey,
			highlight_color = colors.getRandomCatColor(),
			font = "sketchybar-app-font:Regular:16.0",
			y_offset = -1,
			background = {
				height = 26,
				drawing = true,
				color = colors.surface1,
				corner_radius = 8,
			},
		},
		background = {
			drawing = true,
			color = colors.surface0,
			border_color = colors.surface1,
			border_width = 2,
			corner_radius = 8,
		},
		popup = {
			background = {
				border_width = 5,
			},
		},
	})

	spaces[i] = space

	local space_popup = Sbar.add("item", {
		position = "popup." .. space.name,
		padding_left = 5,
		padding_right = 0,
		background = {
			drawing = true,
			image = {
				corner_radius = 9,
				scale = 0.2,
			},
		},
	})

	-- Event handlers
	space:subscribe("space_change", function(env)
		local color = env.SELECTED == "true" and colors.white or colors.surface1
		space:set({
			icon = { highlight = env.SELECTED },
			label = { highlight = env.SELECTED },
			background = { border_color = color },
		})
	end)

	space:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "other" then
			space_popup:set({
				background = {
					image = "space." .. env.SID,
				},
			})
			space:set({ popup = { drawing = "toggle" } })
		elseif env.BUTTON == "right" then
			Sbar.exec("yabai -m space --destroy " .. env.SID)
		else
			Sbar.exec("yabai -m space --focus " .. env.SID)
		end
	end)

	space:subscribe("mouse.exited", function(_)
		space:set({ popup = { drawing = false } })
	end)
end

local space_creator = Sbar.add("item", {
	padding_left = 10,
	padding_right = 8,
	icon = {
		string = "",
	},
	label = { drawing = false },
	associated_display = "active",
})

space_creator:subscribe("mouse.clicked", function(_)
	Sbar.exec("yabai -m space --create")
end)

space_creator:subscribe("space_windows_change", function(env)
	local icon_line = ""
	local no_app = true
	for app, _ in pairs(env.INFO.apps) do
		no_app = false
		local lookup = app_icons[app]
		if lookup == nil then
			print(app .. " not found in icon lookup")
		end
		local icon = ((lookup == nil) and app_icons["Default"] or lookup)
		icon_line = icon_line .. " " .. icon
	end
	if no_app then
		icon_line = ""
	end
	-- TODO: figure out animation after https://github.com/FelixKratz/SketchyBar/commit/1a192019c171e9cc7d87069dbd1822b5f25cdc89
	-- Sbar.animate("tanh", 10, function()
	spaces[env.INFO.space]:set({ label = icon_line })
	-- end)
end)
