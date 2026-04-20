#!/usr/bin/env lua
local icons = require("helpers.icons")
local settings = require("helpers.settings")
local colors = require("helpers.colors")
local logger = require("helpers.logger")

local popup_off = "sketchybar --set github popup.drawing=off"
local github
local last_notification_signature = nil
local last_rendered_signature = nil
local refresh_in_flight = false
local refresh_pending = false

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

local function notification_thread_id(notification)
	local candidate_ids = {
		notification and notification.id or nil,
		notification and notification.thread_id or nil,
	}
	for _, candidate in ipairs(candidate_ids) do
		if IS_EMPTY(candidate) == false then
			return tostring(candidate)
		end
	end

	return nil
end

local function notification_signature(sorted_notifications)
	local parts = { tostring(#sorted_notifications) }
	for index, notification in ipairs(sorted_notifications) do
		if index > 16 then
			break
		end
		table.insert(parts, notification_thread_id(notification) or "")
		table.insert(parts, tostring(notification.updated_at or ""))
	end
	return table.concat(parts, "|")
end

local function notification_mark_read_command(notification)
	local thread_id = notification_thread_id(notification)
	if IS_EMPTY(thread_id) then
		logger.warn("github", "missing_thread_id", {
			subject_type = tostring((notification and notification.subject and notification.subject.type) or "unknown"),
		})
		return nil
	end

	return "gh api --method PATCH notifications/threads/" .. thread_id .. " >/dev/null 2>&1"
end

local function notification_click_script(notification, url)
	local open_script = "open " .. SHELL_QUOTE(url)
	local mark_script = notification_mark_read_command(notification)
	if mark_script == nil then
		return open_script
	end

	return mark_script .. "; " .. open_script .. "; sketchybar --trigger github_update"
end

local function notification_click_url(notification)
	local subject = notification and notification.subject or {}
	local repository = notification and notification.repository or {}
	local repo_url = repository.html_url
	if IS_EMPTY(repo_url) then
		local repo_name = notification_repo_name(notification)
		if repo_name ~= "Unknown" then
			repo_url = "https://github.com/" .. repo_name
		end
	end

	local subject_url = tostring(subject.url or ""):gsub("^'", ""):gsub("'$", "")
	if IS_EMPTY(subject_url) == false and IS_EMPTY(repo_url) == false then
		local issue_number = subject_url:match("/issues/(%d+)$")
		if issue_number ~= nil then
			return repo_url .. "/issues/" .. issue_number
		end

		local pull_number = subject_url:match("/pulls/(%d+)$")
		if pull_number ~= nil then
			return repo_url .. "/pull/" .. pull_number
		end

		local discussion_number = subject_url:match("/discussions/(%d+)$")
		if discussion_number ~= nil then
			return repo_url .. "/discussions/" .. discussion_number
		end

		local commit_sha = subject_url:match("/commits/([%w]+)$")
		if commit_sha ~= nil then
			return repo_url .. "/commit/" .. commit_sha
		end
	end

	if IS_EMPTY(repo_url) == false then
		return repo_url
	end

	return "https://github.com/notifications"
end

github = Sbar.add("item", "github", {
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

SETUP_STANDARD_CLICKS(github, "github_update")

local function refresh_github()
	if refresh_in_flight then
		refresh_pending = true
		return
	end

	logger.debug("github", "refresh_start", {})
	if IS_SYSTEM_SLEEPING then
		logger.debug("github", "refresh_skipped_sleeping", {})
		return
	end

	refresh_in_flight = true
	Sbar.exec("gh api notifications", function(notifications)
		refresh_in_flight = false
		local function finish_refresh()
			if refresh_pending then
				refresh_pending = false
				DELAY(0, refresh_github)
			end
		end

		if type(notifications) ~= "table" then
			logger.warn("github", "invalid_payload", { type = type(notifications) })
			notifications = {}
		end
		local sorted_notifications = collect_sorted_notifications(notifications)
		local count = #sorted_notifications
		local current_repo_group = nil
		local current_signature = notification_signature(sorted_notifications)

		if count > 0 and current_signature ~= last_notification_signature then
			local first = sorted_notifications[1]
			local repo = notification_repo_name(first)
			local title = first.subject and first.subject.title or "New Notification"
			logger.info("github", "notifications_changed", { count = count, repo = repo, title = title })
			Sbar.trigger("github_notification", { COUNT = count, TITLE = title, REPO = repo })
		end
		last_notification_signature = current_signature

		local icon_string = count > 0 and icons.bell or icons.bell_dot
		github:set({
			icon = {
				string = icon_string,
			},
			label = count,
		})

		if current_signature == last_rendered_signature then
			finish_refresh()
			return
		end
		last_rendered_signature = current_signature
		CLEAR_POPUP_ITEMS(github.name)

		local popup_index = 0
		local function next_popup_name(kind)
			popup_index = popup_index + 1
			return "github." .. kind .. "." .. tostring(popup_index)
		end

		for _, notification in ipairs(sorted_notifications) do
			local subject = notification.subject or {}
			local url = notification_click_url(notification)
			local repo_label = notification_repo_name(notification)
			local title = subject.title
			local type = subject.type

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
			elseif type == "Release" then
				color = colors.green
				icon = icons.git.discussion
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
				Sbar.add("item", next_popup_name("repo_header"), {
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
				local click_script = notification_click_script(notification, url)
				logger.debug(
					"github",
					"add_notification",
					{ repo = repo_label, type = type, has_url = (IS_EMPTY(url) == false) }
				)
				Sbar.add("item", next_popup_name("message"), {
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
					click_script = click_script,
					position = "popup." .. github.name,
				})
			end
		end

		finish_refresh()
	end)
end

SETUP_POPUP_HOVER(github, function()
	refresh_github()
end)

github:subscribe({
	"routine",
	"forced",
	"github_update",
}, function(_)
	refresh_github()
end)

return github
