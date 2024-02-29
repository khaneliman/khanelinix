local separator = require("items.stats.separator_right")
local cpu = require("items.stats.cpu")
local memory = require("items.stats.memory")
local disk = require("items.stats.disk")
local network = require("items.stats.network")

local stats = {}

stats.close = function()
  sbar.animate("tanh", 30, function()
    cpu:set({ background = { padding_right = -10 } })
    memory:set({ background = { padding_right = -50 } })
    disk:set({ background = { padding_right = -40 } })
    network.network_up:set({ background = { padding_right = -70 } })
    network.network_down:set({ background = { padding_right = -50 } })
  end)

  separator:set({ icon = "" })

  SLEEP(.1)

  cpu:set({ drawing = false })
  memory:set({ drawing = false })
  disk:set({ drawing = false })
  network.network_up:set({ drawing = false })
  network.network_down:set({ drawing = false })
end

stats.open = function()
  separator:set({ icon = "" })

  sbar.animate("tanh", 30, function()
    cpu:set({ drawing = true })
    memory:set({ drawing = true })
    disk:set({ drawing = true })
    network.network_up:set({ drawing = true })
    network.network_down:set({ drawing = true })

    cpu:set({ background = { padding_right = 0 } })
    memory:set({ background = { padding_right = 0 } })
    disk:set({ background = { padding_right = 0 } })
    network.network_up:set({ background = { padding_right = -70 } })
    network.network_down:set({ background = { padding_right = 0 } })
  end)
end

separator:subscribe("hide_stats", function()
  stats.close()
end)

separator:subscribe("show_stats", function()
  stats.open()
end)

separator:subscribe("toggle_stats", function()
  local state = separator:query().icon.value

  if state == "" then
    sbar.trigger("show_stats")
  elseif state == "" then
    sbar.trigger("hide_stats")
  end
end)
