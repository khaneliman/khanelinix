return function(ctx, options)
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
			numeric = numeric * ctx.layout.meter.percentMax
		end
		return clamp(math.floor(numeric + ctx.layout.meter.roundingBias), 0, ctx.layout.meter.percentMax)
	end

	local name = options.name
	local eventName = options.eventName
	local getIcon = options.getIcon

	local maxExpandWidth = ctx.expandedHalfWidth("islands." .. name .. ".maxExpandWidth", 145)
	local maxExpandWidthPx = ctx.calculateIslandWidth(maxExpandWidth)
	local expandHeight = ctx.asNumber(ctx.get("islands." .. name .. ".expandHeight", "65"), 65)
	local cornerRadius = ctx.asNumber(ctx.get("islands." .. name .. ".cornerRadius", "12"), 12)
	local expandMargin = ctx.calculateMargin(maxExpandWidth)
	local maxExpandHeight = expandHeight + math.floor(ctx.squishAmount / 2)
	local contentYOffset = ctx.contentYOffset or -20

	local iconItem = ctx.Sbar.add("item", "island." .. name .. "_icon", {
		position = "left",
		icon = {
			color = ctx.colorTransparent,
			font = {
				family = ctx.fontFamily,
				style = "Bold",
				size = ctx.layout.fontSizes.meterIcon,
			},
			y_offset = contentYOffset + ctx.layout.meter.iconYOffset,
		},
		padding_left = ctx.layout.meter.paddingLeft,
		padding_right = ctx.layout.spacing.none,
		width = ctx.layout.dimensions.emptyWidth,
		drawing = false,
	})

	local barItem = ctx.Sbar.add("item", "island." .. name .. "_bar", {
		position = "left",
		background = {
			height = ctx.layout.dimensions.meterBarHeight,
			color = ctx.colorTransparent,
			border_color = ctx.colorTransparent,
			y_offset = contentYOffset + ctx.layout.meter.barYOffset,
			shadow = {
				drawing = false,
			},
		},
		drawing = false,
		y_offset = contentYOffset + ctx.layout.meter.barItemYOffset,
		padding_left = ctx.layout.meter.paddingLeft,
		width = ctx.layout.dimensions.emptyWidth,
	})

	local function resetMeter(token)
		ctx.delay(ctx.layout.animation.meterFadeDelay, function()
			if stateToken ~= token then
				return
			end

			ctx.Sbar.animate("tanh", ctx.layout.animation.meterFadeDuration, function()
				iconItem:set({
					icon = {
						color = ctx.colorTransparent,
					},
				})
				barItem:set({
					background = {
						color = ctx.colorTransparent,
						border_color = ctx.colorTransparent,
					},
				})
			end)

			ctx.delay(ctx.layout.animation.meterShrinkDelay, function()
				if stateToken ~= token then
					return
				end

				ctx.Sbar.animate("tanh", ctx.layout.animation.meterShrinkDuration, function()
					barItem:set({
						width = ctx.layout.dimensions.emptyWidth,
					})
				end)

				ctx.delay(ctx.layout.animation.meterCleanupDelay, function()
					if stateToken ~= token then
						return
					end

					iconItem:set({ drawing = false })
					barItem:set({ drawing = false })

					ctx.Sbar.animate("tanh", ctx.layout.animation.collapseDuration, function()
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

	local listener = ctx.Sbar.add("item", name .. "ChangeListener", {
		position = "center",
		width = ctx.layout.dimensions.emptyWidth,
	})

	listener:subscribe(eventName, function(env)
		if ctx.islandState.isSleeping then
			return
		end
		local percent = toPercent(env.INFO)
		local icon = getIcon(percent)

		ctx.logDebug("[" .. name .. "][lua] info=" .. tostring(env.INFO) .. " percent=" .. tostring(percent))
		stateToken = stateToken + 1
		local token = stateToken

		iconItem:set({
			drawing = true,
			icon = {
				string = icon,
			},
		})
		barItem:set({
			drawing = true,
		})

		ctx.Sbar.animate("tanh", ctx.layout.animation.expandDuration, function()
			ctx.Sbar.bar({
				margin = expandMargin,
				corner_radius = cornerRadius,
				height = maxExpandHeight,
			})
			ctx.Sbar.bar({
				height = expandHeight,
			})
		end)

		local barWidth = math.floor(
			(percent / ctx.layout.meter.percentMax) * (maxExpandWidthPx - ctx.layout.dimensions.meterBarInset)
				+ ctx.layout.meter.roundingBias
		)
		ctx.Sbar.animate("tanh", ctx.layout.animation.meterFadeDuration, function()
			barItem:set({
				width = barWidth,
			})
		end)

		ctx.Sbar.animate("sin", ctx.layout.animation.meterFlashDuration, function()
			barItem:set({
				background = {
					color = ctx.colorWhite,
					border_color = ctx.colorWhite,
				},
			})
			iconItem:set({
				icon = {
					color = ctx.colorWhite,
				},
			})
		end)

		resetMeter(token)
	end)

	if ctx.registry ~= nil then
		ctx.registry[name .. "IconItem"] = iconItem
		ctx.registry[name .. "BarItem"] = barItem
		ctx.registry[name .. "ChangeListener"] = listener
	end

	ctx.subscribeItem(name .. "ChangeListener", eventName)
	ctx.logDebug("[" .. name .. "][lua] module loaded")
end
