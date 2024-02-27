local icons = require("icons")
local settings = require("settings")
local colors = require("colors")

local popup_toggle = "sketchybar --set $NAME popup.drawing=toggle"
local popup_off = "sketchybar --set $NAME popup.drawing=off"

local brew = sbar.add("item", "brew", {
  position = "right",
  click_script = popup_toggle,
  icon = {
    string = icons.brew,
    font = {
      family = settings.nerd_font,
      style = "Regular",
      size = 19.0,
    }
  },
  label = "?",
  update_freq = 300,
  popup = {
    align = "right",
    height = 20
  }
})

local brew_details = sbar.add("item", "brew_details", {
  position = "popup." .. brew.name,
  click_script = popup_off,
  background = {
    corner_radius = 12,
    padding_left = 5,
    padding_right = 10
  },
})

brew:subscribe({
    "mouse.exited",
    "mouse.exited.global"
  },
  function(_)
    brew:set({ popup = { drawing = false } })
  end)

brew:subscribe({
    "mouse.entered",
  },
  function(_)
    brew:set({ popup = { drawing = true } })
  end)

brew:subscribe({
    "routine",
    "forced",
    "brew_update"
  },
  function(_)
    local thresholds = {
      { count = 30, color = colors.red },
      { count = 20, color = colors.peach },
      { count = 10, color = colors.yellow },
      { count = 1,  color = colors.green },
      { count = 0,  color = colors.text }
    }

    -- fetch new information
    sbar.exec("command brew update")
    sbar.exec("command brew outdated", function(outdated)
      local count = 0
      for _ in outdated:gmatch("\n") do
        count = count + 1
      end

      -- Clear existing packages
      local existingPackages = brew:query()
      if existingPackages.popup and next(existingPackages.popup.items) ~= nil then
        for _, item in pairs(existingPackages.popup.items) do
          sbar.remove(item)
        end
      end

      -- Add packages to popup
      for package in outdated:gmatch("[^\n]+") do
        local brew_package = sbar.add("item", "brew_" .. package, {
          label = {
            string = tostring(package),
            align = "right",
            padding_right = 20,
            padding_left = 20
          },
          icon = {
            string = tostring(package),
            drawing = false
          },
          click_script = popup_off,
          position = "popup." .. brew.name
        })
      end

      -- Change icon and color depending on packages
      for _, threshold in ipairs(thresholds) do
        if count >= threshold.count then
          brew:set({
            icon = {
              color = threshold.color
            },
            label = count
          })
          break
        end
      end
    end)
  end)

return brew
