#!/usr/bin/env lua

print("🔍 Loading items/init.lua")

-- Load window manager configuration
local wm_config = require("helpers.wm_config")

print("🛠️  Window manager config:")
print("  use_aerospace: " .. tostring(wm_config.use_aerospace))
print("  use_yabai: " .. tostring(wm_config.use_yabai))

require("items.apple")
require("items.spaces")
require("items.skhd")
require("items.front_app")
require("items.today")
require("items.media")
require("items.control_center")
require("items.stats")
require("items.nix")
