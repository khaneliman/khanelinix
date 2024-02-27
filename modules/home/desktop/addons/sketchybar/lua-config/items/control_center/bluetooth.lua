local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Define the "bluetooth" item using Lua tables
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

bluetooth:subscribe("mouse.entered", function()
  bluetooth:set({ popup = { drawing = true } })
end)

bluetooth:subscribe({
    "mouse.exited.global",
    "mouse.exited"
  },
  function()
    bluetooth:set({ popup = { drawing = false } })
  end)

bluetooth:subscribe("mouse.clicked", function()
  sbar.exec("blueutil -p", function(state)
    if tonumber(state) == 0 then
      sbar.exec("blueutil -p 1")
      bluetooth:set({ icon = icons.bluetooth })
    else
      sbar.exec("blueutil -p 0")
      bluetooth:set({ icon = icons.bluetooth_off })
    end
  end)
end)

bluetooth:subscribe({ "routine", "forced" }, function()
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
      local bluetooth_paired_header = sbar.add("item", "bluetooth_paired_header", {
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
        local bluetooth_paired_device = sbar.add("item", "bluetooth_paired_device_" .. label, {
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
      sbar.exec("blueutil --connected", function(connected)
        local bluetooth_connected_header = sbar.add("item", "bluetooth_connected_header", {
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
          local bluetooth_connected_device = sbar.add("item", "bluetooth_connected_device_" .. label, {
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
