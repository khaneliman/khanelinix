local separator = require("items.stats.separator_right")
local cpu = require("items.stats.cpu")
local memory = require("items.stats.memory")
local disk = require("items.stats.disk")
local network = require("items.stats.network")

sbar.add("event", "hide_stats")
sbar.add("event", "show_stats")
sbar.add("event", "toggle_stats")

separator:subscribe("hide_stats", function()
  cpu:set({ drawing = false })
  memory:set({ drawing = false })
  disk:set({ drawing = false })
  network.network_up:set({ drawing = false })
  network.network_down:set({ drawing = false })

  separator:set({ icon = "" })
end)

separator:subscribe("show_stats", function()
  cpu:set({ drawing = true })
  memory:set({ drawing = true })
  disk:set({ drawing = true })
  network.network_up:set({ drawing = true })
  network.network_down:set({ drawing = true })

  separator:set({ icon = "" })
end)

separator:subscribe("toggle_stats", function()
  local state = separator:query().icon.value

  if state == "" then
    sbar.trigger("show_stats")
  elseif state == "" then
    sbar.trigger("hide_stats")
  end
end)
