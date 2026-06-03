return function(ctx)
	local token = 0

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.wifi.maxExpandWidth", "190"), 190)
	local expandHeight = ctx.asNumber(ctx.get("islands.wifi.expandHeight", "76"), 76)
	local cornerRad = ctx.asNumber(ctx.get("islands.wifi.cornerRadius", "22"), 22)
	local expandMargin = ctx.calculateMargin(maxExpandWidth)
	local expandWidth = maxExpandWidth * 2

	local textItem = ctx.Sbar.add("item", "island.wifi_text", {
		position = "center",
		drawing = false,
		label = {
			align = "center",
			color = ctx.colorTransparent,
			y_offset = ctx.contentYOffset,
		},
		width = 0,
	})

	local listener = ctx.Sbar.add("item", "wifiChangeListener", {
		position = "center",
		width = 0,
	})

	local function showIsland(info)
		local icon = ctx.get("icons.wifi.connected", "􀙇")
		local text = info

		ctx.logDebug("[wifi][lua] info='" .. info .. "'")

		textItem:set({
			drawing = true,
			width = expandWidth,
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
				textItem:set({
					drawing = false,
					width = 0,
				})
			end,
		})
	end

	listener:subscribe("wifi_change", function(env)
		if ctx.islandState.isSleeping then
			return
		end
		local info = ctx.trim(env.INFO or "")
		if info ~= "" then
			showIsland(info)
			return
		end

		ctx.Sbar.exec(
			[[ssid=$(ipconfig getsummary en0 2>/dev/null | awk -F ' SSID : ' '/ SSID : / {print $2; exit}'); ]]
				.. [[ip_address=$(ipconfig getifaddr en0 2>/dev/null || true); ]]
				.. [[if [ -n "$ssid" ]; then printf '%s' "$ssid"; elif [ -n "$ip_address" ]; then printf 'Network: %s' "$ip_address"; else printf 'Disconnected'; fi]],
			function(result)
				local fallbackInfo = ctx.trim(result or "")
				if fallbackInfo == "" then
					fallbackInfo = "Disconnected"
				end
				showIsland(fallbackInfo)
			end
		)
	end)

	ctx.registry.wifiTextItem = textItem
	ctx.registry.wifiListener = listener
	ctx.subscribeItem("wifiChangeListener", "wifi_change")
	ctx.logDebug("[wifi][lua] module loaded")
end
