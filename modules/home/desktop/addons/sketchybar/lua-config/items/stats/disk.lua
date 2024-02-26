local settings = require('settings')
local colors = require('colors')
local icons = require('icons')

local disk = sbar.add("item", "disk", {
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
    string = icons.stats.disk,
    color = colors.blue
  },
  update_freq = 60,
  position = "right"
})

disk:subscribe({
    "routine",
    "forced",
    "system_woke"
  },
  function()
    local diskUsage = io.popen("df -H | grep -E '^(/dev/disk3s1s1 ).' | awk '{ printf (\"%s\\n\", $5) }'"):read("*a")
    disk:set({ label = diskUsage })
  end)

return disk
