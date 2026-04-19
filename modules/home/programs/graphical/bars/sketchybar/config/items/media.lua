#!/usr/bin/env lua

local whitelist = {
	["Spotify"] = true,
	["Music"] = true,
}
local logger = require("helpers.logger")

local media = Sbar.add("item", "media", {
	icon = { drawing = false },
	position = "center",
	updates = true,
})

media:subscribe("media_change", function(env)
	if env.INFO == nil or type(env.INFO) ~= "table" then
		logger.warn("media", "invalid_payload", { payload = tostring(env.INFO) })
		return
	end

	local app = env.INFO.app
	if whitelist[app] then
		media:set({
			drawing = (env.INFO.state == "playing") and true or false,
			label = (env.INFO.artist or "Unknown") .. ": " .. (env.INFO.title or "Unknown"),
		})
	else
		logger.debug("media", "ignored_app", { app = tostring(app) })
	end
end)
