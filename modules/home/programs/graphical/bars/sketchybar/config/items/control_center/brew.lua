#!/usr/bin/env lua

local icons = require("icons")
local settings = require("settings")
local colors = require("colors")

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
	update_freq = 300,
	popup = {
		align = "right",
		height = 20,
	},
})

brew.details = Sbar.add("item", "brew.details", {
	position = "popup." .. brew.name,
	click_script = "sketchybar --set brew popup.drawing=off",
	background = {
		corner_radius = 12,
		padding_left = 5,
		padding_right = 10,
	},
})

brew.clearPopup = function()
	-- Clear existing packages
	local existingPackages = brew:query()
	if existingPackages.popup and next(existingPackages.popup.items) ~= nil then
		for _, item in pairs(existingPackages.popup.items) do
			Sbar.remove(item)
		end
	end
end

brew.skipCleanup = false

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
	"brew_cleanup",
}, function(_)
	if brew.skipCleanup == false then
		brew:set({ label = 0 })
		brew.clearPopup()
	end
end)

brew:subscribe({
	"routine",
	"forced",
	"brew_update",
}, function(_)
	brew.skipCleanup = false

	-- fetch new information
	Sbar.exec("command brew update")
	Sbar.exec("command brew outdated", function(outdated)
		-- NOTE: sbar.exec will not run callback if command doesn't return anything.
		-- We use a variable to determine if we should skip cleaning up the count
		-- and popup
		brew.skipCleanup = true

		local thresholds = {
			{ count = 30, color = colors.red },
			{ count = 20, color = colors.peach },
			{ count = 10, color = colors.yellow },
			{ count = 1, color = colors.green },
			{ count = 0, color = colors.text },
		}

		local count = 0
		for _ in outdated:gmatch("\n") do
			count = count + 1
		end

		-- Clear existing packages
		brew.clearPopup()

		-- Add packages to popup
		for package in outdated:gmatch("[^\n]+") do
			Sbar.add("item", "brew.package." .. package, {
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
				click_script = POPUP_OFF("brew"),
				position = "popup." .. brew.name,
			})
		end

		-- Change icon and color depending on packages
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
	Sbar.trigger("brew_cleanup")
end)

return brew
