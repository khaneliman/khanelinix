#!/usr/bin/env lua

-- Load window manager configuration
local logger = require("helpers.logger")
local wm_config = require("helpers.wm_config")

-- Conditionally load spaces configuration based on window manager
if wm_config.use_aerospace then
	logger.info("spaces", "load", { window_manager = "aerospace" })
	require("items.spaces.aerospace")
elseif wm_config.use_yabai then
	logger.info("spaces", "load", { window_manager = "yabai" })
	require("items.spaces.yabai")
else
	logger.info("spaces", "load", { window_manager = "basic" })
	require("items.spaces.basic")
end
