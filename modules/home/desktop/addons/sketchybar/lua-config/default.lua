local settings = require("settings")
local colors = require("colors")

-- Equivalent to the --default domain
sbar.default({
  updates = "when_shown",
  icon = {
    color = colors.text,
    font = {
      family = settings.nerd_font,
      style = "Bold",
      size = 16.0
    },
    padding_left = settings.paddings,
    padding_right = settings.paddings,
  },
  label = {
    color = colors.text,
    font = {
      family = settings.font,
      style = "Semibold",
      size = 13.0
    },
    padding_left = settings.paddings,
    padding_right = settings.paddings,
  },
  background = {
    corner_radius = 9,
    height = 30,
    padding_left = settings.paddings,
    padding_right = settings.paddings,
  },
  popup = {
    height = 30,
    horizontal = false,
    background = {
      border_color = colors.blue,
      border_width = 2,
      color = colors.mantle,
      corner_radius = 11,
      shadow = {
        drawing = true
      }
    }
  }
})
