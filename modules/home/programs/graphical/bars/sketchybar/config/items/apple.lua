#!/usr/bin/env lua

local icons = require("helpers.icons")
local colors = require("helpers.colors")
local settings = require("helpers.settings")
local logger = require("helpers.logger")

local popup_toggle = "sketchybar --set $NAME popup.drawing=toggle"

local apple = {}

apple.logo = Sbar.add("item", "apple.logo", {
	padding_left = settings.offsets.apple_logo_left,
	padding_right = settings.spacing.large,
	click_script = popup_toggle,
	icon = {
		string = icons.apple,
		font = {
			style = "Black",
			size = settings.font_sizes.default_icon,
		},
		color = colors.green,
	},
	label = {
		drawing = false,
	},
	popup = {
		height = settings.spacing.none,
	},
})

local function add_apple_item(name, icon_string, label_string, click_cmd)
	local item = Sbar.add("item", "apple." .. name, {
		position = "popup." .. apple.logo.name,
		icon = {
			string = icon_string,
			padding_left = settings.spacing.regular,
		},
		label = label_string,
		background = {
			color = 0x00000000,
			height = settings.dimensions.item_height,
			drawing = true,
		},
	})

	item:subscribe("mouse.clicked", function(_)
		logger.debug("apple", "menu_item_clicked", { item = "apple." .. name })
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
		height = settings.dimensions.separator_height,
		drawing = true,
	},
	padding_left = settings.spacing.regular,
	padding_right = settings.spacing.regular,
	width = settings.widths.apple_divider,
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
