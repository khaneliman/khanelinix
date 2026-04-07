return function(ctx)
	local meter = dofile(os.getenv("HOME") .. "/.config/dynamic-island-sketchybar/lua/islands/helpers/meter.lua")

	meter(ctx, {
		name = "volume",
		eventName = "volume_change",
		getIcon = function(percent)
			if percent >= 70 then
				return ctx.get("icons.volume.max", "􀊩")
			elseif percent >= 40 then
				return ctx.get("icons.volume.medium", "􀊧")
			elseif percent >= 1 then
				return ctx.get("icons.volume.low", "􀊥")
			end
			return ctx.get("icons.volume.muted", "􀊡")
		end,
	})
end
