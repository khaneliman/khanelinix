local settings = require('settings')
local colors = require('colors')
local icons = require('icons')

local memory = sbar.add("item", "memory", {
  background = {
    padding_left = 0,
  },
  label = {
    font = {
      family = settings.font,
      size = 12.0,
      style = "Heavy"
    },
    color = colors.text
  },
  icon = {
    string = icons.stats.memory,
    color = colors.green,
    font = {
      family = settings.font,
      size = 16.0,
      style = "Bold"
    },
  },
  update_freq = 15,
  position = "right"
})

memory:subscribe({
    "routine",
    "forced",
    "system_woke"
  },
  function()
    local memoryUsage = io.popen(
          "memory_pressure | grep 'System-wide memory free percentage:' | awk '{ printf(\"%02.0f\\n\", 100-$5\"%\") }'")
        :read(
          "*a")
    memory:set({ label = memoryUsage .. "%" })
  end)


return memory
