#!/usr/bin/env lua

local app_icons = require("icon_map")

-- Return the base icons extended with custom mappings and aliases
return setmetatable({
	-- Element from nixpkgs doesn't have name set properly on macos
	["Electron"] = ":element:",
	["Vesktop"] = ":discord:",
	["LaunchControl"] = "󱓞",
}, {
	__index = app_icons,
})
