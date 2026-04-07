#!/usr/bin/env lua
local colors = require("helpers.colors")
local app_icons = require("helpers.app_icons")
local settings = require("helpers.settings")
local spaces_utils = require("items.spaces.utils")

local spaces = {}

local function focus_workspace(workspace)
	Sbar.exec("aerospace workspace --fail-if-noop " .. workspace .. " >/dev/null 2>&1 || true")
end

for i = 1, 8, 1 do
	local config = spaces_utils.get_space_item_config(tostring(i), false)
	config.position = "left"

	local space = Sbar.add("item", config)

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
		local focused_num = tonumber(env.FOCUSED)
		local is_focused = focused_num == i
		local color = is_focused and colors.white or colors.surface1

		space:set({
			icon = { highlight = is_focused },
			label = { highlight = is_focused },
			background = { border_color = color },
		})
	end)

	space:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "other" then
			space_popup:set({
				background = {
					image = "space." .. i,
				},
			})
			space:set({ popup = { drawing = "toggle" } })
		elseif env.BUTTON == "left" then
			focus_workspace(i)
		elseif env.BUTTON == "right" then
			-- TODO: destroy / create?
			-- For right-click, just focus the workspace
			focus_workspace(i)
		end
	end)

	space:subscribe("mouse.exited", function(_)
		space:set({ popup = { drawing = false } })
	end)
end

local window_tracker = Sbar.add("item", {
	padding_left = 10,
	padding_right = 8,
	icon = {
		string = "",
	},
	label = { drawing = false },
	associated_display = "active",
})

local pending_update = false
local update_timer_active = false
local last_workspace_labels = {}

local function icon_line_for_workspace(apps)
	local app_names = {}
	for app, _ in pairs(apps) do
		table.insert(app_names, app)
	end

	table.sort(app_names)

	if #app_names == 0 then
		return ""
	end

	local icon_parts = {}
	for _, app in ipairs(app_names) do
		local lookup = app_icons[app]
		table.insert(icon_parts, (lookup == nil) and app_icons["Default"] or lookup)
	end

	return " " .. table.concat(icon_parts, " ")
end

local function do_update()
	Sbar.exec([[aerospace list-windows --all --format '%{workspace}|%{app-name}']], function(result)
		local workspace_apps = {}
		for i = 1, 8 do
			workspace_apps[tostring(i)] = {}
		end

		if result and result ~= "" then
			for line in result:gmatch("[^\n]+") do
				local workspace, app = line:match("^(.-)|(.*)$")
				if workspace and app and workspace_apps[workspace] and app ~= "" and app ~= "None" then
					workspace_apps[workspace][app] = true
				end
			end
		end

		for workspace_num = 1, 8 do
			local icon_line = icon_line_for_workspace(workspace_apps[tostring(workspace_num)])
			if last_workspace_labels[workspace_num] ~= icon_line and spaces[workspace_num] ~= nil then
				last_workspace_labels[workspace_num] = icon_line
				spaces[workspace_num]:set({ label = { string = icon_line } })
			end
		end

		if pending_update then
			pending_update = false
			Sbar.exec("sleep 0.2", do_update)
		else
			update_timer_active = false
		end
	end)
end

local function update_windows()
	if update_timer_active then
		pending_update = true
		return
	end
	update_timer_active = true
	pending_update = false
	do_update()
end

window_tracker:subscribe("aerospace_windows_change", function()
	if IS_SYSTEM_SLEEPING then
		return
	end
	update_windows()
end)

-- Initial window update
update_windows()

-- Initial focus update
Sbar.exec("aerospace list-workspaces --focused", function(focused_workspace)
	local focused_num = tonumber(focused_workspace)
	if focused_num then
		for i, space in pairs(spaces) do
			local is_focused = focused_num == i
			local color = is_focused and colors.white or colors.surface1
			space:set({
				icon = { highlight = is_focused },
				label = { highlight = is_focused },
				background = { border_color = color },
			})
		end
	end
end)
