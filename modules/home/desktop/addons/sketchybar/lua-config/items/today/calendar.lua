local settings = require("settings")

local cal = sbar.add("item", "date", {
  icon = {
    align = "right",
    padding_right = 0,
    font = {
      family = settings.font,
      style = "Black",
      size = 14.0,
    },
  },
  position = "right",
  update_freq = 15,
  width = 30,
  y_offset = 6
})

local clock = sbar.add("item", "clock", {
  icon = {
    align = "right",
    padding_right = 0,
    font = {
      family = settings.font,
      style = "Bold",
      size = 12.0,
    },
  },
  label = {
    padding_left = -50
  },
  background = {
    padding_left = 0,
    padding_right = -20
  },
  position = "right",
  update_freq = 15,
  y_offset = -8
})

local function update()
  local date = os.date("%a. %d %b.")
  local time = os.date("%I:%M %p")
  cal:set({ icon = date })
  clock:set({ icon = time })
end

cal:subscribe("forced", update)
cal:subscribe("routine", update)
clock:subscribe("forced", update)
clock:subscribe("routine", update)
