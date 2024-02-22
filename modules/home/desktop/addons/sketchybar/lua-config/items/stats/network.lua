local settings = require('settings')
local colors = require('colors')
local icons = require('icons')

local network = {}

network.network_down = sbar.add("item", "network_down", {
  background = {
    padding_left = 0,
  },
  label = {
    font = {
      family = settings.font,
      size = 10.0,
      style = "Heavy"
    },
    color = colors.text
  },
  icon = {
    font = {
      family = settings.nerd_font,
      size = 16.0,
      style = "Bold"
    },
    string = icons.stats.network_down,
    color = colors.green,
    highlight_color = colors.blue
  },
  update_freq = 1,
  position = "right",
  y_offset = -7
})

network.network_up = sbar.add("item", "network_up", {
  background = {
    padding_right = -70,
  },
  label = {
    font = {
      family = settings.font,
      size = 10.0,
      style = "Heavy"
    },
    color = colors.text
  },
  icon = {
    font = {
      family = settings.nerd_font,
      size = 16.0,
      style = "Bold"
    },
    string = icons.stats.network_up,
    color = colors.green,
    highlight_color = colors.blue
  },
  update_freq = 1,
  position = "right",
  y_offset = 7
})

network.network_down:subscribe({
    "routine",
    "forced",
    "system_woke"
  },
  function()
    -- Execute the ifstat command and read the output
    local ifstat_output = io.popen('ifstat -i "en0" -b 0.1 1 | tail -n1'):read("*a")

    -- Extract DOWN and UP values from the ifstat output
    local DOWN, UP = ifstat_output:match("(%S+)%s+(%S+)")

    -- Convert DOWN and UP values to Lua numbers
    DOWN = tonumber(DOWN)
    UP = tonumber(UP)

    -- Format DOWN and UP values
    local DOWN_FORMAT
    if DOWN > 999 then
      DOWN_FORMAT = string.format("%03.0f Mbps", DOWN / 1000)
    else
      DOWN_FORMAT = string.format("%03.0f kbps", DOWN)
    end

    local UP_FORMAT
    if UP > 999 then
      UP_FORMAT = string.format("%03.0f Mbps", UP / 1000)
    else
      UP_FORMAT = string.format("%03.0f kbps", UP)
    end

    network.network_down:set({ label = DOWN_FORMAT })
    network.network_up:set({ label = UP_FORMAT })
  end)

return network
