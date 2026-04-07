return function(ctx)
	local meter = dofile(os.getenv("HOME") .. "/.config/dynamic-island-sketchybar/lua/islands/helpers/meter.lua")

	meter(ctx, {
		name = "brightness",
		eventName = "brightness_change",
		getIcon = function(percent)
			if percent >= 40 then
				return ctx.get("icons.brightness.high", "􀆭")
			end
			return ctx.get("icons.brightness.low", "􀆫")
		end,
	})
end
