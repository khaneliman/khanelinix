#!/usr/bin/env lua

local icons = require("icons")
local settings = require("settings")
local colors = require("colors")

local popup_off = "sketchybar --set github popup.drawing=off"

local function sanitize_item_key(value)
	if value == nil then
		return "unknown"
	end

	local sanitized = tostring(value):gsub("[^%w%._-]", "_")
	if sanitized == "" then
		return "unknown"
	end

	return sanitized
end

local function truncate_label(value, max_length)
	if value == nil then
		return ""
	end

	local text = tostring(value)
	if max_length == nil or max_length <= 0 then
		return text
	end

	if #text <= max_length then
		return text
	end

	return text:sub(1, max_length - 1) .. "…"
end

local function notification_repo_name(notification)
	local repository = notification and notification.repository or nil
	if repository == nil then
		return "Unknown"
	end

	if IS_EMPTY(repository.full_name) == false then
		return tostring(repository.full_name)
	end

	local owner = repository.owner and repository.owner.login or nil
	local name = repository.name
	if IS_EMPTY(owner) == false and IS_EMPTY(name) == false then
		return tostring(owner) .. "/" .. tostring(name)
	end

	if IS_EMPTY(name) == false then
		return tostring(name)
	end

	return "Unknown"
end

local function collect_sorted_notifications(raw_notifications)
	local sorted_notifications = {}
	if type(raw_notifications) ~= "table" then
		return sorted_notifications
	end
	for _, notification in pairs(raw_notifications or {}) do
		if type(notification) == "table" then
			table.insert(sorted_notifications, notification)
		end
	end

	table.sort(sorted_notifications, function(left, right)
		local left_repo = string.lower(notification_repo_name(left))
		local right_repo = string.lower(notification_repo_name(right))
		if left_repo ~= right_repo then
			return left_repo < right_repo
		end

		local left_updated_at = tostring(left.updated_at or "")
		local right_updated_at = tostring(right.updated_at or "")
		if left_updated_at ~= right_updated_at then
			return left_updated_at > right_updated_at
		end

		local left_title = tostring((left.subject and left.subject.title) or "")
		local right_title = tostring((right.subject and right.subject.title) or "")
		return left_title < right_title
	end)

	return sorted_notifications
end

local github = Sbar.add("item", "github", {
	position = "right",
	icon = {
		string = icons.bell,
		color = colors.blue,
		font = {
			family = settings.font,
			style = "Bold",
			size = 15.0,
		},
	},
	background = {
		padding_left = 0,
	},
	label = {
		string = icons.loading,
		highlight_color = colors.blue,
	},
	update_freq = 180,
	popup = {
		align = "right",
	},
})

github.details = Sbar.add("item", "github.details", {
	position = "popup." .. github.name,
	click_script = popup_off,
	background = {
		corner_radius = 12,
		padding_left = 7,
		padding_right = 7,
	},
	icon = {
		background = {
			height = 2,
			y_offset = -12,
		},
	},
})

github:subscribe({
	"mouse.clicked",
}, function(info)
	if info.BUTTON == "left" then
		POPUP_TOGGLE(info.NAME)
	end

	if info.BUTTON == "right" then
		Sbar.trigger("github_update")
	end
end)

github:subscribe({
	"mouse.exited",
	"mouse.exited.global",
}, function(_)
	github:set({ popup = { drawing = false } })
end)

github:subscribe({
	"mouse.entered",
}, function(_)
	github:set({ popup = { drawing = true } })
end)

github:subscribe({
	"routine",
	"forced",
	"github_update",
}, function(_)
	-- fetch new information
	Sbar.exec("gh api notifications", function(notifications)
		-- Clear existing packages
		local existingNotifications = github:query()
		if existingNotifications.popup and next(existingNotifications.popup.items) ~= nil then
			for _, item in pairs(existingNotifications.popup.items) do
				Sbar.remove(item)
			end
		end

		-- PRINT_TABLE(notifications)

		local sorted_notifications = collect_sorted_notifications(notifications)
		local count = #sorted_notifications
		local current_repo_group = nil

		for index, notification in ipairs(sorted_notifications) do
			-- PRINT_TABLE(notification)
			local subject = notification.subject or {}
			local id = notification.id or index
			local url = subject.latest_comment_url or subject.url
			local repo_label = notification_repo_name(notification)
			local title = subject.title
			local type = subject.type

			-- set click_script for each notification
			if url == nil then
				url = "https://www.github.com/notifications"
			else
				local tempUrl = url:gsub("^'", ""):gsub("'$", "")
				Sbar.exec('gh api "' .. tempUrl .. '" | jq .html_url', function(html_url)
					local cmd = "sketchybar -m --set github.notification"
					if IS_EMPTY(title) == false then
						cmd = cmd .. ".message."
						cmd = cmd .. tostring(id) .. ' click_script="open ' .. html_url .. '"'
						Sbar.exec(cmd, function()
							Sbar.exec(popup_off)
						end)
					end
				end)
			end

			-- get icon and color for each notification
			-- depending on the type
			local color, icon
			if type == "Issue" then
				color = colors.green
				icon = icons.git.issue
			elseif type == "Discussion" then
				color = colors.text
				icon = icons.git.discussion
			elseif type == "PullRequest" then
				color = colors.maroon
				icon = icons.git.pull_request
			elseif type == "Commit" then
				color = colors.text
				icon = icons.git.commit
			else
				color = colors.text
				icon = icons.git.issue
			end

			-- add notification to popup
			if IS_EMPTY(repo_label) then
				repo_label = "Unknown"
			end

			local repo_group = string.lower(repo_label)
			if current_repo_group ~= repo_group then
				current_repo_group = repo_group
				local repo_key = sanitize_item_key(repo_label)
				Sbar.add("item", "github.notification.repo_header." .. repo_key .. "." .. tostring(index), {
					label = {
						string = repo_label,
						color = colors.blue,
						padding_right = settings.paddings,
						padding_left = settings.paddings,
						font = {
							family = settings.font,
							size = 14.0,
							style = "Bold",
						},
					},
					icon = {
						string = icons.git.indicator,
						color = colors.blue,
						font = {
							family = settings.nerd_font,
							size = 14.0,
							style = "Bold",
						},
					},
					drawing = true,
					click_script = popup_off,
					position = "popup." .. github.name,
				})
			end

			if IS_EMPTY(title) == false then
				github.notification = {}
				github.notification.message = Sbar.add("item", "github.notification.message." .. tostring(id), {
					label = {
						string = truncate_label(title, 60),
						padding_right = 10,
					},
					icon = {
						string = icon,
						color = color,
						font = {
							family = settings.nerd_font,
							size = 12.0,
							style = "Bold",
						},
						padding_left = settings.paddings + 12,
					},
					drawing = true,
					-- TODO: trigger update after clicking since notification is cleared on github
					click_script = "open " .. url .. "; " .. popup_off,
					position = "popup." .. github.name,
				})
			end
		end

		local icon_string = count > 0 and icons.bell or icons.bell_dot
		github:set({
			icon = {
				string = icon_string,
			},
			label = count,
		})
	end)
end)

return github
