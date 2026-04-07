#!/usr/bin/env lua

local icons = require("helpers.icons")
local colors = require("helpers.colors")

local popup_toggle = "sketchybar --set $NAME popup.drawing=toggle"

local apple = {}

apple.logo = Sbar.add("item", "apple.logo", {
	padding_left = -5,
	padding_right = 10,
	click_script = popup_toggle,
	icon = {
		string = icons.apple,
		font = {
			style = "Black",
			size = 20.0,
		},
		color = colors.green,
	},
	label = {
		drawing = false,
	},
	popup = {
		height = 0,
	},
})

local function add_apple_item(name, icon_string, label_string, click_cmd)
	local item = Sbar.add("item", "apple." .. name, {
		position = "popup." .. apple.logo.name,
		icon = {
			string = icon_string,
			padding_left = 7,
		},
		label = label_string,
		background = {
			color = 0x00000000,
			height = 30,
			drawing = true,
		},
	})

	item:subscribe("mouse.clicked", function(_)
		Sbar.exec(click_cmd)
		apple.logo:set({ popup = { drawing = false } })
	end)

	return item
end

apple.prefs = add_apple_item("prefs", icons.preferences, "Preferences", "open -a 'System Preferences'")
apple.activity = add_apple_item("activity", icons.activity, "Activity", "open -a 'Activity Monitor'")

apple.divider = Sbar.add("item", "apple.divider", {
	position = "popup." .. apple.logo.name,
	icon = {
		drawing = false,
	},
	label = {
		drawing = false,
	},
	background = {
		color = colors.blue,
		height = 1,
		drawing = true,
	},
	padding_left = 7,
	padding_right = 7,
	width = 110,
})

apple.lock = add_apple_item(
	"lock",
	icons.lock,
	"Lock Screen",
	'osascript -e \'tell application "System Events" to keystroke "q" using {command down,control down}\''
)
apple.logout = add_apple_item(
	"logout",
	icons.logout,
	"Logout",
	'osascript -e \'tell application "System Events" to keystroke "q" using {command down,shift down}\''
)
apple.sleep = add_apple_item("sleep", icons.sleep, "Sleep", "osascript -e 'tell app \"System Events\" to sleep'")
apple.reboot =
	add_apple_item("reboot", icons.reboot, "Reboot", "osascript -e 'tell app \"loginwindow\" to «event aevtrrst»'")
apple.shutdown =
	add_apple_item("shutdown", icons.power, "Shutdown", "osascript -e 'tell app \"loginwindow\" to «event aevtrsdn»'")
