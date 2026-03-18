return function(ctx)
	local token = 0

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.wifi.maxExpandWidth", "190"), 190)
	local expandHeight = ctx.asNumber(ctx.get("islands.wifi.expandHeight", "56"), 56)
	local cornerRad = ctx.asNumber(ctx.get("islands.wifi.cornerRadius", "15"), 15)
	local expandMargin = math.floor(ctx.monitorResolution / 2 - maxExpandWidth)

	local textItem = ctx.Sbar.add("item", "island.wifi_text", {
		position = "right",
		drawing = false,
		label = {
			color = ctx.colorTransparent,
		},
		width = 0,
	})

	local listener = ctx.Sbar.add("item", "wifiChangeListener", {
		position = "center",
		width = 0,
	})

	listener:subscribe("wifi_change", function(env)
		if ctx.islandState.isSleeping then
			return
		end
		local info = ctx.trim(env.INFO or "")
		if info == "" then
			return
		end

		local icon = ctx.get("icons.wifi.connected", "􀙇")
		local text = info

		token = token + 1
		local current = token
		ctx.logDebug("[wifi][lua] info='" .. info .. "'")

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

		ctx.delay(0.8, function()
			if current ~= token then
				return
			end

			ctx.Sbar.animate("tanh", 10, function()
				textItem:set({ label = { color = ctx.colorTransparent } })
			end)

			ctx.delay(0.2, function()
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

	ctx.registry.wifiTextItem = textItem
	ctx.registry.wifiListener = listener
	ctx.subscribeItem("wifiChangeListener", "wifi_change")
	ctx.logDebug("[wifi][lua] module loaded")
end
