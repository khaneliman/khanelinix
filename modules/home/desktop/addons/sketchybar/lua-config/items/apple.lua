local icons = require("icons")
local colors = require("colors")

local popup_toggle = "sketchybar --set $NAME popup.drawing=toggle"

local apple_logo = sbar.add("item", "apple_logo", {
  padding_right = 15,
  click_script = popup_toggle,
  icon = {
    string = icons.apple,
    font = {
      style = "Black",
      size = 16.0,
    },
    color = colors.green,
  },
  label = {
    drawing = false,
  },
  popup = {
    height = 0
  }
})

local apple_prefs = sbar.add("item", "apple_prefs", {
  position = "popup." .. apple_logo.name,
  icon = icons.preferences,
  label = "Preferences",
  background = {
    color = 0x00000000,
    height = 30,
    drawing = true
  }
})

apple_prefs:subscribe("mouse.clicked", function(_)
  sbar.exec("open -a 'System Preferences'")
  apple_logo:set({ popup = { drawing = false } })
end)

local apple_activity = sbar.add("item", "apple_activity", {
  position = "popup." .. apple_logo.name,
  icon = {
    string = icons.activity
  },
  label = "Activity",
  background = {
    color = 0x00000000,
    height = 30,
    drawing = true,
  },
  click_script = "open -a 'Activity Monitor'; " .. popup_toggle,
})

apple_activity:subscribe("mouse.clicked", function(_)
  apple_logo:set({ popup = { drawing = false } })
end)

local apple_divider = sbar.add("item", "apple_divider", {
  position = "popup." .. apple_logo.name,
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

local apple_lock = sbar.add("item", "apple_lock", {
  position = "popup." .. apple_logo.name,
  icon = {
    string = icons.lock
  },
  label = "Lock Screen",
  background = {
    color = 0x00000000,
    height = 30,
    drawing = true,
  },
  click_script =
      "osascript -e 'tell application \"System Events\" to keystroke \"q\" using {command down,control down}'; " ..
      popup_toggle,
})

apple_lock:subscribe("mouse.clicked", function(_)
  apple_logo:set({ popup = { drawing = false } })
end)

local apple_logout = sbar.add("item", "apple_logout", {
  position = "popup." .. apple_logo.name,
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
  click_script = "osascript -e 'tell application \"System Events\" to keystroke \"q\" using {command down,shift down}'; " ..
      popup_toggle,
})

apple_logout:subscribe("mouse.clicked", function(_)
  apple_logo:set({ popup = { drawing = false } })
end)

local apple_sleep = sbar.add("item", "apple_sleep", {
  position = "popup." .. apple_logo.name,
  icon = {
    string = icons.sleep,
    padding_left = 5,
  },
  label = "Sleep",
  background = {
    color = 0x00000000,
    height = 30,
    drawing = true,
  },
  click_script = "osascript -e 'tell app \"System Events\" to sleep'; " .. popup_toggle,
})

apple_sleep:subscribe("mouse.clicked", function(_)
  apple_logo:set({ popup = { drawing = false } })
end)

local apple_reboot = sbar.add("item", "apple_reboot", {
  position = "popup." .. apple_logo.name,
  icon = {
    string = icons.reboot,
    padding_left = 5,
  },
  label = "Reboot",
  background = {
    color = 0x00000000,
    height = 30,
    drawing = true,
  },
  click_script = "osascript -e 'tell app \"loginwindow\" to «event aevtrrst»'; " .. popup_toggle,
})

apple_reboot:subscribe("mouse.clicked", function(_)
  apple_logo:set({ popup = { drawing = false } })
end)

local apple_shutdown = sbar.add("item", "apple_shutdown", {
  position = "popup." .. apple_logo.name,
  icon = {
    string = icons.power,
    padding_left = 5,
  },
  label = "Shutdown",
  background = {
    color = 0x00000000,
    height = 30,
    drawing = true,
  },
  click_script = "osascript -e 'tell app \"loginwindow\" to «event aevtrsdn»'; " .. popup_toggle,
})

apple_shutdown:subscribe("mouse.clicked", function(_)
  apple_logo:set({ popup = { drawing = false } })
end)
