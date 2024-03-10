#!/usr/bin/env lua

local settings = require('settings')

local island = sbar.add("item", "island", {
  drawing = on,
  position = "center",
  update_freq = 5,
  mach_helper = "git.crissnb.islandhelper",
})

island:subscribe({ "dynamic_island_queue, dynamic_island_request" }, function(INFO)
  -- test
  PRINT_TABLE(INFO)
end)

return island
