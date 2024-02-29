local colors = require('colors')

local separator_right = sbar.add("item", "separator_right", {
  background = {
    padding_left = 10,
    padding_right = 10,
  },
  label = {
    drawing = false
  },
  icon = {
    string = "",
    color = colors.text
  },
  position = "right",
})

separator_right:subscribe("mouse.clicked", function()
  sbar.trigger("toggle_stats")
end)

return separator_right
