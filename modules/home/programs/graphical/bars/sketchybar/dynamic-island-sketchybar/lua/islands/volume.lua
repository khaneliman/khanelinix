return function(ctx)
	local stateToken = 0

	local function clamp(value, minimum, maximum)
		if value < minimum then
			return minimum
		end
		if value > maximum then
			return maximum
		end
		return value
	end

	local function toPercent(infoValue)
		local numeric = tonumber(infoValue) or 0
		if numeric >= 0 and numeric <= 1 then
			numeric = numeric * 100
		end
		return clamp(math.floor(numeric + 0.5), 0, 100)
	end

	local volumeMaxExpandWidth = ctx.asNumber(ctx.get("islands.volume.maxExpandWidth", "130"), 130)
	local volumeExpandHeight = ctx.asNumber(ctx.get("islands.volume.expandHeight", "65"), 65)
	local volumeCornerRadius = ctx.asNumber(ctx.get("islands.volume.cornerRadius", "12"), 12)
	local volumeExpandMargin = math.floor(ctx.monitorResolution / 2 - volumeMaxExpandWidth)
	local volumeMaxExpandHeight = volumeExpandHeight + math.floor(ctx.squishAmount / 2)

	local volumeIconItem = ctx.Sbar.add("item", "island.volume_icon", {
		position = "left",
		icon = {
			color = ctx.colorTransparent,
			font = {
				family = ctx.fontFamily,
				style = "Bold",
				size = 14.0,
			},
			y_offset = 2,
		},
		padding_left = 10,
		padding_right = 0,
		width = 0,
		drawing = false,
	})

	local volumeBarItem = ctx.Sbar.add("item", "island.volume_bar", {
		position = "left",
		background = {
			height = 2,
			color = ctx.colorTransparent,
			border_color = ctx.colorTransparent,
			y_offset = 0,
			shadow = {
				drawing = false,
			},
		},
		drawing = false,
		y_offset = -19,
		padding_left = 10,
		width = 0,
	})

	local function resetMeter(token)
		ctx.delay(0.8, function()
			if stateToken ~= token then
				return
			end

			ctx.Sbar.animate("tanh", 15, function()
				volumeIconItem:set({
					icon = {
						color = ctx.colorTransparent,
					},
				})
				volumeBarItem:set({
					background = {
						color = ctx.colorTransparent,
						border_color = ctx.colorTransparent,
					},
				})
			end)

			ctx.delay(0.1, function()
				if stateToken ~= token then
					return
				end

				ctx.Sbar.animate("tanh", 5, function()
					volumeBarItem:set({
						width = 0,
					})
				end)

				ctx.delay(0.4, function()
					if stateToken ~= token then
						return
					end

					volumeIconItem:set({ drawing = false })
					volumeBarItem:set({ drawing = false })

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
	end

	local volumeChangeListener = ctx.Sbar.add("item", "volumeChangeListener", {
		position = "center",
		width = 0,
	})

	volumeChangeListener:subscribe("volume_change", function(env)
		if ctx.islandState.isSleeping then
			return
		end
		local volume = toPercent(env.INFO)
		local icon = ctx.get("icons.volume.muted", "􀊡")
		if volume >= 70 then
			icon = ctx.get("icons.volume.max", "􀊩")
		elseif volume >= 40 then
			icon = ctx.get("icons.volume.medium", "􀊧")
		elseif volume >= 1 then
			icon = ctx.get("icons.volume.low", "􀊥")
		end

		ctx.logDebug("[volume][lua] info=" .. tostring(env.INFO) .. " percent=" .. tostring(volume))
		stateToken = stateToken + 1
		local token = stateToken

		volumeIconItem:set({
			drawing = true,
			icon = {
				string = icon,
			},
		})
		volumeBarItem:set({
			drawing = true,
		})

		ctx.Sbar.animate("tanh", 10, function()
			ctx.Sbar.bar({
				margin = volumeExpandMargin,
				corner_radius = volumeCornerRadius,
				height = volumeMaxExpandHeight,
			})
			ctx.Sbar.bar({
				height = volumeExpandHeight,
			})
		end)

		local barWidth = math.floor((volume / 100) * (volumeMaxExpandWidth * 2 - 20) + 0.5)
		ctx.Sbar.animate("tanh", 15, function()
			volumeBarItem:set({
				width = barWidth,
			})
		end)

		ctx.Sbar.animate("sin", 10, function()
			volumeBarItem:set({
				background = {
					color = ctx.colorWhite,
					border_color = ctx.colorWhite,
				},
			})
			volumeIconItem:set({
				icon = {
					color = ctx.colorWhite,
				},
			})
		end)

		resetMeter(token)
	end)

	if ctx.registry ~= nil then
		ctx.registry.volumeIconItem = volumeIconItem
		ctx.registry.volumeBarItem = volumeBarItem
		ctx.registry.volumeChangeListener = volumeChangeListener
	end

	ctx.subscribeItem("volumeChangeListener", "volume_change")
	ctx.logDebug("[volume][lua] module loaded")
end
