#!/usr/bin/env lua

local settings = require('settings')
local colors = require('colors')
local icons = require('icons')

local network = {}

network.down = sbar.add("item", "network.down", {
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

network.up = sbar.add("item", "network.up", {
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

network.down:subscribe({
    "routine",
    "forced",
    "system_woke"
  },
  function()
    -- Execute the ifstat command and read the output
    sbar.exec('ifstat -i "en0" -b 0.1 1 | tail -n1', function(ifstat_output)
      -- Extract DOWN and UP values from the ifstat output
      local down, up = ifstat_output:match("(%S+)%s+(%S+)")

      -- Convert DOWN and UP values to Lua numbers
      down = tonumber(down)
      up = tonumber(up)

      -- Format DOWN and UP values
      local down_formatted
      if down > 999 then
        down_formatted = string.format("%03.0f Mbps", down / 1000)
      else
        down_formatted = string.format("%03.0f kbps", down)
      end

      local up_formatted
      if up > 999 then
        up_formatted = string.format("%03.0f Mbps", up / 1000)
      else
        up_formatted = string.format("%03.0f kbps", up)
      end

      local up_highlighted
      if up > 0 then
        up_highlighted = true
      else
        up_highlighted = false
      end

      local down_highlighted
      if down > 0 then
        down_highlighted = true
      else
        down_highlighted = false
      end

      network.down:set({
        label = down_formatted,
        icon = {
          highlight = down_highlighted
        }
      })
      network.up:set({
        label = up_formatted,
        icon = {
          highlight = up_highlighted
        }
      })
    end)
  end)

return network
