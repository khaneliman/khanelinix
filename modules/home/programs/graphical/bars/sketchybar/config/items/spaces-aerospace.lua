#!/usr/bin/env lua

local colors = require("colors")
local app_icons = require("app_icons")
local settings = require("settings")

local spaces = {}

-- Create numbered workspace items (1-8) like yabai version
for i = 1, 8, 1 do
	local space = Sbar.add("item", {
		position = "left",
		icon = {
			string = tostring(i),
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

	-- Subscribe to aerospace workspace change for focus updates
	space:subscribe("aerospace_workspace_change", function(env)
		print("[DEBUG] Space " .. i .. " received aerospace_workspace_change event")
		print("[DEBUG] env.FOCUSED value: '" .. tostring(env.FOCUSED) .. "'")
		print("[DEBUG] env.FOCUSED type: " .. type(env.FOCUSED))

		local focused_num = tonumber(env.FOCUSED)
		print("[DEBUG] Converted focused_num: " .. tostring(focused_num))
		print("[DEBUG] Current space i: " .. tostring(i))

		local is_focused = focused_num == i
		print("[DEBUG] Space " .. i .. " is_focused: " .. tostring(is_focused))

		local color = is_focused and colors.white or colors.surface1
		print("[DEBUG] Space " .. i .. " border color: " .. tostring(color))

		space:set({
			icon = { highlight = is_focused },
			label = { highlight = is_focused },
			background = { border_color = color },
		})

		print("[DEBUG] Space " .. i .. " updated successfully")
	end)

	-- Mouse interaction handlers
	space:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "other" then
			space_popup:set({
				background = {
					image = "space." .. i,
				},
			})
			space:set({ popup = { drawing = "toggle" } })
		elseif env.BUTTON == "left" then
			-- Focus workspace with aerospace
			Sbar.exec("aerospace workspace " .. i)
		elseif env.BUTTON == "right" then
			-- For right-click, just focus the workspace
			Sbar.exec("aerospace workspace " .. i)
		end
	end)

	space:subscribe("mouse.exited", function(_)
		space:set({ popup = { drawing = false } })
	end)
end

-- Window tracker item that updates app icons when aerospace workspace changes
local window_tracker = Sbar.add("item", {
	padding_left = 10,
	padding_right = 8,
	icon = {
		string = "􀆊",
		font = {
			family = settings.nerd_font,
			style = "Regular",
			size = 16.0,
		},
	},
	label = { drawing = false },
	associated_display = "active",
})

window_tracker:subscribe("mouse.clicked", function(_)
	-- Aerospace doesn't have dynamic workspace creation like yabai
	-- Just reload aerospace config
	Sbar.exec("aerospace reload-config")
end)

-- Subscribe to aerospace workspace change to update app icons for all workspaces
window_tracker:subscribe("aerospace_workspace_change", function(env)
	print("[DEBUG] Window tracker: Aerospace workspace change detected")
	print("[DEBUG] Window tracker: env.FOCUSED = '" .. tostring(env.FOCUSED) .. "'")

	-- Update app icons for all workspaces when any workspace changes
	for workspace_num = 1, 8 do
		print("[DEBUG] Window tracker: Checking workspace " .. workspace_num)

		Sbar.exec("aerospace list-windows --workspace " .. workspace_num .. ' --format "%{app-name}"', function(result)
			print(
				"[DEBUG] Window tracker: Raw result for workspace " .. workspace_num .. ": '" .. tostring(result) .. "'"
			)

			local icon_line = ""
			local no_app = true

			if result and result ~= "" then
				print("[DEBUG] Window tracker: Processing apps for workspace " .. workspace_num)
				local apps = {}
				-- Process each app line
				for app in result:gmatch("[^\n]+") do
					print("[DEBUG] Window tracker: Found app line: '" .. tostring(app) .. "'")
					if app and app ~= "" and app ~= "None" then
						apps[app] = true -- Use as set to avoid duplicates
						print("[DEBUG] Window tracker: Added app to set: '" .. app .. "'")
					end
				end

				-- Convert to icon line
				for app, _ in pairs(apps) do
					no_app = false
					local lookup = app_icons[app]
					if lookup == nil then
						print("[DEBUG] Window tracker: No icon found for app '" .. app .. "', using default")
					else
						print("[DEBUG] Window tracker: Found icon for app '" .. app .. "': " .. lookup)
					end
					local icon = ((lookup == nil) and app_icons["Default"] or lookup)
					icon_line = icon_line .. " " .. icon
				end
			else
				print("[DEBUG] Window tracker: No result or empty result for workspace " .. workspace_num)
			end

			if no_app then
				icon_line = ""
				print("[DEBUG] Window tracker: No apps found for workspace " .. workspace_num)
			else
				print(
					"[DEBUG] Window tracker: Final icon line for workspace "
						.. workspace_num
						.. ": '"
						.. icon_line
						.. "'"
				)
			end

			-- Update the workspace label with app icons
			if spaces[workspace_num] then
				spaces[workspace_num]:set({ label = { string = icon_line } })
				print("[DEBUG] Window tracker: Updated workspace " .. workspace_num .. " label")
			else
				print("[DEBUG] Window tracker: ERROR - spaces[" .. workspace_num .. "] is nil!")
			end
		end)
	end
end)
