#!/usr/bin/env lua

local icons = require("icons")
local settings = require("settings")
local colors = require("colors")
local popup_off = "sketchybar --set brew popup.drawing=off"
local brew_done_marker = "__SKETCHYBAR_DONE__"

local function shell_quote(value)
	local text = tostring(value or "")
	return "'" .. text:gsub("'", [['"'"']]) .. "'"
end

local brew_outdated_cmd = table.concat({
	"env -i",
	"HOME=" .. shell_quote(os.getenv("HOME") or ""),
	"USER=" .. shell_quote(os.getenv("USER") or ""),
	"LOGNAME=" .. shell_quote(os.getenv("LOGNAME") or ""),
	"TMPDIR=" .. shell_quote(os.getenv("TMPDIR") or "/tmp"),
	"PATH=" .. shell_quote("/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:/usr/sbin:/sbin"),
	"HOMEBREW_NO_AUTO_UPDATE=1",
	"HOMEBREW_NO_ANALYTICS=1",
	"/opt/homebrew/bin/brew outdated --quiet 2>/dev/null || true;",
	"printf %s " .. shell_quote(brew_done_marker .. "\n"),
}, " ")

local brew = Sbar.add("item", "brew", {
	position = "right",
	icon = {
		string = icons.brew,
		font = {
			family = settings.nerd_font,
			style = "Regular",
			size = 19.0,
		},
	},
	label = "?",
	update_freq = 14400,
	popup = {
		align = "right",
		height = 20,
	},
})

local function clear_popup()
	-- Clear existing packages
	local existing_packages = brew:query()
	if existing_packages.popup and next(existing_packages.popup.items) ~= nil then
		for _, item in pairs(existing_packages.popup.items) do
			Sbar.remove(item)
		end
	end
end

brew:subscribe({
	"mouse.clicked",
}, function(info)
	if info.BUTTON == "left" then
		POPUP_TOGGLE(info.NAME)
	end

	if info.BUTTON == "right" then
		Sbar.trigger("brew_update")
	end
end)

brew:subscribe({
	"mouse.exited",
	"mouse.exited.global",
}, function(_)
	brew:set({ popup = { drawing = false } })
end)

brew:subscribe({
	"mouse.entered",
}, function(_)
	brew:set({ popup = { drawing = true } })
end)

brew:subscribe({
	"routine",
	"forced",
	"brew_update",
}, function(_)
	Sbar.exec(brew_outdated_cmd, function(outdated)
		local thresholds = {
			{ count = 30, color = colors.red },
			{ count = 20, color = colors.peach },
			{ count = 10, color = colors.yellow },
			{ count = 1, color = colors.green },
			{ count = 0, color = colors.text },
		}

		local packages = {}
		for package in outdated:gmatch("[^\n]+") do
			if package ~= brew_done_marker and package ~= "" then
				table.insert(packages, package)
			end
		end

		local count = 0
		for _ in ipairs(packages) do
			count = count + 1
		end

		clear_popup()

		for index, package in ipairs(packages) do
			Sbar.add("item", "brew.package." .. tostring(index), {
				label = {
					string = tostring(package),
					align = "right",
					padding_right = 20,
					padding_left = 20,
				},
				icon = {
					string = tostring(package),
					drawing = false,
				},
				click_script = popup_off,
				position = "popup." .. brew.name,
			})
		end

		for _, threshold in ipairs(thresholds) do
			if count >= threshold.count then
				brew:set({
					icon = {
						color = threshold.color,
					},
					label = count,
				})
				break
			end
		end
	end)
end)

return brew
