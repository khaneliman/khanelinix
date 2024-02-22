local settings = require('settings')
local colors = require('colors')
local icons = require('icons')

local cpu = sbar.add("item", "cpu", {
  background = {
    padding_left = 0,
    padding_right = 0
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
    string = icons.stats.cpu,
    color = colors.blue
  },
  update_freq = 2,
  position = "right"
})

return cpu
