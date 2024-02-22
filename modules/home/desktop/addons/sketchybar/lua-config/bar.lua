local colors = require("colors")

-- Equivalent to the --bar domain
sbar.bar({
  blur_radius = 30,
  border_color = colors.surface1,
  border_width = 2,
  color = colors.base,
  corner_radius = 9,
  height = 40,
  margin = 10,
  notch_width = 0,
  padding_left = 18,
  padding_right = 10,
  position = "top",
  shadow = true,
  sticky = true,
  topmost = false,
  y_offset = 10,
})
