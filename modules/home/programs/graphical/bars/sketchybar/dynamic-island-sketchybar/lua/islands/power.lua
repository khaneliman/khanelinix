return function(ctx)
	local token = 0

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.power.maxExpandWidth", "190"), 190)
	local expandHeight = ctx.asNumber(ctx.get("islands.power.expandHeight", "56"), 56)
	local cornerRad = ctx.asNumber(ctx.get("islands.power.cornerRadius", "15"), 15)
	local expandMargin = math.floor(ctx.monitorResolution / 2 - maxExpandWidth)

	local textItem = ctx.Sbar.add("item", "island.power_text", {
		position = "right",
		drawing = false,
		label = {
			color = ctx.colorTransparent,
		},
		width = 0,
	})

	local listener = ctx.Sbar.add("item", "powerChangeListener", {
		position = "center",
		width = 0,
	})

	listener:subscribe("power_source_change", function(env)
		local source = ctx.trim(env.INFO or "")
		local icon = ctx.get("icons.power.onBattery", "􀺸")
		local text = "On Battery"

		if source == "AC" then
			icon = ctx.get("icons.power.connectedAC", "􀢋")
			text = "Charging"
		elseif source == "BATTERY" then
			text = "On Battery"
		else
			text = source ~= "" and source or text
		end

		token = token + 1
		local current = token
		ctx.appendLog(ctx.debugLogPath, "[power][lua] source='" .. source .. "'")

		textItem:set({
			drawing = true,
			label = {
				string = icon .. " " .. text,
			},
		})

		ctx.Sbar.animate("tanh", 10, function()
			ctx.Sbar.bar({
				margin = expandMargin,
				corner_radius = cornerRad,
				height = expandHeight,
			})
			textItem:set({
				label = { color = ctx.colorWhite },
			})
		end)

		ctx.Sbar.exec("sleep 0.8", function()
			if current ~= token then
				return
			end

			ctx.Sbar.animate("tanh", 10, function()
				textItem:set({ label = { color = ctx.colorTransparent } })
			end)

			ctx.Sbar.exec("sleep 0.2", function()
				if current ~= token then
					return
				end

				textItem:set({ drawing = false })
				ctx.Sbar.animate("tanh", 10, function()
					ctx.Sbar.bar({
						height = ctx.defaultHeight,
						corner_radius = ctx.cornerRadius,
						margin = ctx.margin,
					})
				end)
			end)
		end)
	end)

	ctx.registry.powerTextItem = textItem
	ctx.registry.powerListener = listener
	ctx.subscribeItem("powerChangeListener", "power_source_change")
	ctx.appendLog(ctx.debugLogPath, "[power][lua] module loaded")
end
