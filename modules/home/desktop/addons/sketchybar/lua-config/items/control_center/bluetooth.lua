local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Add bluetooth icon to bar
local bluetooth = sbar.add("item", "bluetooth", {
  position = "right",
  align = "right",
  update_freq = 60,
  icon = {
    drawing = true,
    string = icons.bluetooth,
    color = colors.peach,
  },
  background = {
    padding_right = 0,
  },
  popup = {
    height = 30,
  },
})

-- Mouse hover to show popup
bluetooth:subscribe("mouse.entered", function()
  bluetooth:set({ popup = { drawing = true } })
end)

-- Close popup on exit
bluetooth:subscribe({
    "mouse.exited.global",
    "mouse.exited"
  },
  function()
    bluetooth:set({ popup = { drawing = false } })
  end)

-- Toggle bluetooth with mouse click
bluetooth:subscribe("mouse.clicked", function()
  sbar.exec("blueutil -p", function(state)
    if tonumber(state) == 0 then
      sbar.exec("blueutil -p 1")
      bluetooth:set({ icon = icons.bluetooth })
    else
      sbar.exec("blueutil -p 0")
      bluetooth:set({ icon = icons.bluetooth_off })
    end

    SLEEP(1)
    sbar.trigger("bluetooth_update")
  end)
end)

-- Fetch bluetooth status and devices
bluetooth:subscribe({ "routine", "forced", "bluetooth_update" }, function()
  sbar.exec("blueutil -p", function(state)
    -- Clear existing devices in tooltip
    local existingEvents = bluetooth:query()
    if existingEvents.popup and next(existingEvents.popup.items) ~= nil then
      for _, item in pairs(existingEvents.popup.items) do
        sbar.remove(item)
      end
    end

    if tonumber(state) == 0 then
      bluetooth:set({ icon = icons.bluetooth_off })
    else
      bluetooth:set({ icon = icons.bluetooth })
    end

    -- Get paired and connected devices
    sbar.exec("blueutil --paired", function(paired)
      bluetooth.paired = {}

      bluetooth.paired.header = sbar.add("item", "bluetooth.paired.header", {
        icon = {
          drawing = false
        },
        label = {
          string = "Paired Devices",
          font = {
            family = settings.font,
            size = 14.0,
            style = "Bold"
          },
        },
        position = "popup." .. bluetooth.name,
        click_script = "sketchybar --set $NAME popup.drawing=off",
      })

      -- Iterate over the list of paired devices
      for device in paired:gmatch("[^\n]+") do
        local label = device:match('"(.*)"')
        bluetooth.paired.device = sbar.add("item", "bluetooth.paired.device." .. label, {
          icon = {
            drawing = false
          },
          label = {
            string = label,
            font = {
              family = settings.font,
              size = 13.0,
              style = "Regular"
            },
          },
          position = "popup." .. bluetooth.name,
          click_script = "sketchybar --set $NAME popup.drawing=off",
        })
      end

      -- Fetch connected devices
      sbar.exec("blueutil --connected", function(connected)
        bluetooth.connected = {}

        bluetooth.connected.header = sbar.add("item", "bluetooth.connected.header", {
          icon = {
            drawing = false
          },
          label = {
            string = "Connected Devices",
            font = {
              family = settings.font,
              size = 14.0,
              style = "Bold"
            },
          },
          position = "popup." .. bluetooth.name,
          click_script = "sketchybar --set $NAME popup.drawing=off",
        })

        for device in connected:gmatch("[^\n]+") do
          local label = device:match('"(.*)"')
          bluetooth.connected.device = sbar.add("item", "bluetooth.connected.device." .. label, {
            icon = {
              drawing = false
            },
            label = {
              string = label,
              font = {
                family = settings.font,
                size = 13.0,
                style = "Regular"
              },
            },
            position = "popup." .. bluetooth.name,
            click_script = "sketchybar --set $NAME popup.drawing=off",
          })
        end
      end)
    end)
  end)
end)

return bluetooth
