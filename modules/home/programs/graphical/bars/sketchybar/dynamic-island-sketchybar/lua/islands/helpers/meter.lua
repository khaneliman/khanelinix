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
			numeric = numeric * 100
		end
		return clamp(math.floor(numeric + 0.5), 0, 100)
	end

	local name = options.name
	local eventName = options.eventName
	local getIcon = options.getIcon

	local maxExpandWidth = ctx.asNumber(ctx.get("islands." .. name .. ".maxExpandWidth", "130"), 130)
	local maxExpandWidthPx = ctx.calculateIslandWidth(maxExpandWidth)
	local expandHeight = ctx.asNumber(ctx.get("islands." .. name .. ".expandHeight", "65"), 65)
	local cornerRadius = ctx.asNumber(ctx.get("islands." .. name .. ".cornerRadius", "12"), 12)
	local expandMargin = ctx.calculateMargin(maxExpandWidth)
	local maxExpandHeight = expandHeight + math.floor(ctx.squishAmount / 2)

	local iconItem = ctx.Sbar.add("item", "island." .. name .. "_icon", {
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

	local barItem = ctx.Sbar.add("item", "island." .. name .. "_bar", {
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

			ctx.delay(0.1, function()
				if stateToken ~= token then
					return
				end

				ctx.Sbar.animate("tanh", 5, function()
					barItem:set({
						width = 0,
					})
				end)

				ctx.delay(0.4, function()
					if stateToken ~= token then
						return
					end

					iconItem:set({ drawing = false })
					barItem:set({ drawing = false })

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

	local listener = ctx.Sbar.add("item", name .. "ChangeListener", {
		position = "center",
		width = 0,
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

		ctx.Sbar.animate("tanh", 10, function()
			ctx.Sbar.bar({
				margin = expandMargin,
				corner_radius = cornerRadius,
				height = maxExpandHeight,
			})
			ctx.Sbar.bar({
				height = expandHeight,
			})
		end)

		local barWidth = math.floor((percent / 100) * (maxExpandWidthPx - 20) + 0.5)
		ctx.Sbar.animate("tanh", 15, function()
			barItem:set({
				width = barWidth,
			})
		end)

		ctx.Sbar.animate("sin", 10, function()
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
