#!/usr/bin/env lua

-- Load window manager configuration
local wm_config = require("helpers.wm_config")

-- Conditionally load spaces configuration based on window manager
if wm_config.use_aerospace then
	print("🚀 Loading aerospace spaces configuration")
	require("items.spaces.aerospace")
elseif wm_config.use_yabai then
	print("🪟 Loading yabai spaces configuration")
	require("items.spaces.yabai")
else
	print("📊 Loading basic spaces configuration (no WM)")
	require("items.spaces.basic")
end
