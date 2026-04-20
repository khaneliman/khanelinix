return function(ctx)
	local token = 0

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.wifi.maxExpandWidth", "190"), 190)
	local expandHeight = ctx.asNumber(ctx.get("islands.wifi.expandHeight", "56"), 56)
	local cornerRad = ctx.asNumber(ctx.get("islands.wifi.cornerRadius", "15"), 15)
	local expandMargin = ctx.calculateMargin(maxExpandWidth)

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

		ctx.logDebug("[wifi][lua] info='" .. info .. "'")

		textItem:set({
			drawing = true,
			label = {
				string = icon .. " " .. text,
			},
		})

		ctx.animateIsland({
			margin = expandMargin,
			cornerRadius = cornerRad,
			height = expandHeight,
			duration = 0.8,
			onExpand = function()
				textItem:set({ label = { color = ctx.colorWhite } })
			end,
			onHideContent = function()
				textItem:set({ label = { color = ctx.colorTransparent } })
			end,
			onCleanup = function()
				textItem:set({ drawing = false })
			end,
		})
	end)

	ctx.registry.wifiTextItem = textItem
	ctx.registry.wifiListener = listener
	ctx.subscribeItem("wifiChangeListener", "wifi_change")
	ctx.logDebug("[wifi][lua] module loaded")
end
