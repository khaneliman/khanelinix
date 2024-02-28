local icons = require("icons")
local settings = require("settings")

local wifi = sbar.add("item", "wifi", {
  position = "right",
  align = "right",
  click_script = "sketchybar --set $NAME popup.drawing=toggle",
  icon = {
    string = icons.wifi,
    font = {
      family = settings.nerd_font,
      style = "Regular",
      size = 19.0,
    }
  },
  background = {
    padding_left = 5
  },
  label = { drawing = false },
  update_freq = 60,
})

wifi.details = sbar.add("item", "wifi.details", {
  position = "popup." .. wifi.name,
  click_script = "sketchybar --set $NAME popup.drawing=off",
  background = {
    corner_radius = 12,
    padding_left = 5,
    padding_right = 10
  },
  icon = {
    background = {
      height = 2,
      y_offset = 12,
    }
  },
  label = {
    align = "center",
  },
})

wifi:subscribe({
    "routine",
    "power_source_change",
    "system_woke"
  },
  function()
    -- Get current WiFi info
    sbar.exec(
      "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I",
      function(currentWifi)
        -- Extract SSID
        local ssid = string.match(currentWifi, "SSID: (.-)\n")

        -- Extract current transmission rate
        local currTx = string.match(currentWifi, "lastTxRate: (.-)\n")

        if IS_EMPTY(ssid) then
          wifi:set({ icon = { string = icons.wifi_off } })
          wifi.details:set({ label = "No WiFi" })
          return
        end

        wifi:set({
          icon = {
            string = icons.wifi,
          },
        })
        wifi.details:set({
          label = ssid .. " (" .. currTx .. "Mbps)"
        })
      end)
  end)

wifi:subscribe({
    "mouse.exited",
    "mouse.exited.global"
  },
  function(_)
    wifi:set({ popup = { drawing = false } })
  end)

wifi:subscribe({
    "mouse.entered",
  },
  function(_)
    wifi:set({ popup = { drawing = true } })
  end)

return wifi
