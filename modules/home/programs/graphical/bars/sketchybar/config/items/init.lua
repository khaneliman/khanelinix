#!/usr/bin/env lua

print("🔍 Loading items/init.lua")

-- Load window manager configuration
local wm_config = require("wm_config")

print("🛠️  Window manager config:")
print("  use_aerospace: " .. tostring(wm_config.use_aerospace))
print("  use_yabai: " .. tostring(wm_config.use_yabai))

require("items.apple")

-- Conditionally load spaces configuration based on window manager
if wm_config.use_aerospace then
	print("🚀 Loading aerospace spaces configuration")
	require("items.spaces-aerospace")
elseif wm_config.use_yabai then
	print("🪟 Loading yabai spaces configuration")
	require("items.spaces-yabai")
else
	print("📊 Loading basic spaces configuration (no WM)")
	require("items.spaces")
end

require("items.skhd")
require("items.voice_dictate")
require("items.front_app")
require("items.today")
require("items.media")
require("items.control_center")
require("items.stats")
