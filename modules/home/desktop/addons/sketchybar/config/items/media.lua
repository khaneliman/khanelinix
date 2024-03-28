#!/usr/bin/env lua

local whitelist = {
	["Spotify"] = true,
	["Music"] = true,
}

local media = Sbar.add("item", "media", {
	icon = { drawing = false },
	position = "center",
	updates = true,
})

media:subscribe("media_change", function(env)
	if whitelist[env.INFO.app] then
		media:set({
			drawing = (env.INFO.state == "playing") and true or false,
			label = env.INFO.artist .. ": " .. env.INFO.title,
		})
	end
end)
