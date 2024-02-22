local settings = require("settings")
local colors = require("colors")
local icons = require("icons")
local debug = require("debug")

local popup_toggle = "sketchybar --set $NAME popup.drawing=toggle"

local ical = sbar.add("item", "ical", {
  icon = {
    align = "left",
    padding_right = 0,
    string = icons.ical,
    font = {
      family = settings.nerd_font,
      style = "Black",
      size = 14.0,
    },
  },
  background = {
    padding_left = 10
  },
  popup = {
    align = "right",
    height = 20
  },
  position = "right",
  y_offset = -8,
  click_script = popup_toggle,
  update_freq = 180
})

local ical_details = sbar.add("item", "ical_details", {
  icon = {
    drawing = false,
    background = {
      corner_radius = 12
    },
    padding_left = 7,
    padding_right = 7,
    font = {
      family = settings.font,
      style = "Bold",
      size = 14.0,
    },
  },
  position = "popup." .. ical.name,
  click_script = "sketchybar --set $NAME popup.drawing=off",
})

local function split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    table.insert(t, str)
  end
  return t
end

-- Update function
ical:subscribe({ "routine", "forced" }, function()
  -- Constants
  local SEP = "%" -- Separator for icalBuddy output

  -- Reset popup state
  ical:set({ popup = { drawing = false } })

  -- Fetch events from calendar
  local EVENTS = io.popen("icalBuddy -nc -nrd -eed -iep datetime,title -b '' -ps '|" .. SEP .. "|' eventsToday")
      :read("*a")

  -- Clear existing events
  local existingEvents = ical:query()
  if existingEvents.popup and next(existingEvents.popup.items) ~= nil then
    for _, item in pairs(existingEvents.popup.items) do
      sbar.remove(item)
    end
  end

  -- Parse and organize events
  for _, line in ipairs(split(EVENTS, "\n")) do
    local title, time = line:match("^(.-)%s*%%(.*)$")

    if title and time then
      local ical_event = sbar.add("item", "ical_event_" .. title, {
        icon = {
          string = time,
          color = colors.yellow
        },
        label = {
          string = title
        },
        position = "popup." .. ical.name,
        click_script = "sketchybar --set $NAME popup.drawing=off",
      })
    else
      local ical_event = sbar.add("item", "ical_event_" .. line, {
        icon = {
          color = colors.yellow
        },
        label = {
          string = line
        },
        position = "popup." .. ical.name,
        click_script = "sketchybar --set $NAME popup.drawing=off",
      })
    end
  end
end)

ical:subscribe("mouse.entered", function()
  ical:set({ popup = { drawing = true } })
end)

ical:subscribe({
    "mouse.exited.global",
    "mouse.exited"
  },
  function()
    ical:set({ popup = { drawing = false } })
  end)
