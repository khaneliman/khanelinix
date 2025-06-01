#!/usr/bin/env lua

local app_icons = require("icon_map")

-- Extend with custom mappings and aliases
local extensions = {
	-- Element from nixpkgs doesn't have name set properly on macos
	["Electron"] = ":element:",
	["Vesktop"] = ":discord:",
}

-- Apply extensions
for app, icon in pairs(extensions) do
	app_icons[app] = icon
end

return app_icons
