local icons = require("icons")
local settings = require("settings")
local colors = require("colors")
local percent = 0

local popup_toggle = "sketchybar --set $NAME popup.drawing=toggle"

local wifi = sbar.add("item", "wifi", {
  position = "right",
  align = "right",
  click_script = popup_toggle,
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
  update_freq = 1,
})

local wifi_details = sbar.add("item", "wifi_details", {
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

local function isempty(s)
  return s == nil or s == ''
end

local function wifi_update()
  -- Get current WiFi info
  sbar.exec(
    "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I",
    function(currentWifi)
      -- Extract SSID
      local ssid = string.match(currentWifi, "SSID: (.-)\n")

      -- Extract current transmission rate
      local currTx = string.match(currentWifi, "lastTxRate: (.-)\n")

      if isempty(ssid) then
        wifi:set({ icon = { string = icons.wifi_off } })
        wifi_details:set({ label = "No WiFi" })
        return
      end

      wifi:set({
        icon = {
          string = icons.wifi,
        },
      })
      wifi_details:set({
        label = ssid .. " (" .. currTx .. "Mbps)"
      })
    end)
end

wifi:subscribe({
    "routine",
    "power_source_change",
    "system_woke"
  },
  wifi_update)

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
