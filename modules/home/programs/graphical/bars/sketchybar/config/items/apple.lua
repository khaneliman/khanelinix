#!/usr/bin/env lua

local icons = require("icons")
local colors = require("colors")

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

apple.prefs = Sbar.add("item", "apple.prefs", {
	position = "popup." .. apple.logo.name,
	icon = icons.preferences,
	label = "Preferences",
	background = {
		color = 0x00000000,
		height = 30,
		drawing = true,
	},
})

apple.prefs:subscribe("mouse.clicked", function(_)
	Sbar.exec("open -a 'System Preferences'")
	apple.logo:set({ popup = { drawing = false } })
end)

apple.activity = Sbar.add("item", "apple.activity", {
	position = "popup." .. apple.logo.name,
	icon = {
		string = icons.activity,
	},
	label = "Activity",
	background = {
		color = 0x00000000,
		height = 30,
		drawing = true,
	},
	click_script = "open -a 'Activity Monitor'; " .. popup_toggle,
})

apple.activity:subscribe("mouse.clicked", function(_)
	apple.logo:set({ popup = { drawing = false } })
end)

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

apple.lock = Sbar.add("item", "apple.lock", {
	position = "popup." .. apple.logo.name,
	icon = {
		string = icons.lock,
	},
	label = "Lock Screen",
	background = {
		color = 0x00000000,
		height = 30,
		drawing = true,
	},
	click_script = 'osascript -e \'tell application "System Events" to keystroke "q" using {command down,control down}\'; '
		.. popup_toggle,
})

apple.lock:subscribe("mouse.clicked", function(_)
	apple.logo:set({ popup = { drawing = false } })
end)

apple.logout = Sbar.add("item", "apple.logout", {
	position = "popup." .. apple.logo.name,
	icon = {
		string = icons.logout,
		padding_left = 7,
	},
	label = "Logout",
	background = {
		color = 0x00000000,
		height = 30,
		drawing = true,
	},
	click_script = 'osascript -e \'tell application "System Events" to keystroke "q" using {command down,shift down}\'; '
		.. popup_toggle,
})

apple.logout:subscribe("mouse.clicked", function(_)
	apple.logo:set({ popup = { drawing = false } })
end)

apple.sleep = Sbar.add("item", "apple.sleep", {
	position = "popup." .. apple.logo.name,
	icon = {
		string = icons.sleep,
		padding_left = 7,
	},
	label = "Sleep",
	background = {
		color = 0x00000000,
		height = 30,
		drawing = true,
	},
	click_script = "osascript -e 'tell app \"System Events\" to sleep'; " .. popup_toggle,
})

apple.sleep:subscribe("mouse.clicked", function(_)
	apple.logo:set({ popup = { drawing = false } })
end)

apple.reboot = Sbar.add("item", "apple.reboot", {
	position = "popup." .. apple.logo.name,
	icon = {
		string = icons.reboot,
		padding_left = 7,
	},
	label = "Reboot",
	background = {
		color = 0x00000000,
		height = 30,
		drawing = true,
	},
	click_script = "osascript -e 'tell app \"loginwindow\" to «event aevtrrst»'; " .. popup_toggle,
})

apple.reboot:subscribe("mouse.clicked", function(_)
	apple.logo:set({ popup = { drawing = false } })
end)

apple.shutdown = Sbar.add("item", "apple.shutdown", {
	position = "popup." .. apple.logo.name,
	icon = {
		string = icons.power,
		padding_left = 7,
	},
	label = "Shutdown",
	background = {
		color = 0x00000000,
		height = 30,
		drawing = true,
	},
	click_script = "osascript -e 'tell app \"loginwindow\" to «event aevtrsdn»'; " .. popup_toggle,
})

apple.shutdown:subscribe("mouse.clicked", function(_)
	apple.logo:set({ popup = { drawing = false } })
end)
