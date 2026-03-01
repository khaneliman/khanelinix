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

	local brightnessMaxExpandWidth = ctx.asNumber(ctx.get("islands.brightness.maxExpandWidth", "130"), 130)
	local brightnessExpandHeight = ctx.asNumber(ctx.get("islands.brightness.expandHeight", "65"), 65)
	local brightnessCornerRadius = ctx.asNumber(ctx.get("islands.brightness.cornerRadius", "12"), 12)
	local brightnessExpandMargin = math.floor(ctx.monitorResolution / 2 - brightnessMaxExpandWidth)
	local brightnessMaxExpandHeight = brightnessExpandHeight + math.floor(ctx.squishAmount / 2)

	local brightnessIconItem = ctx.Sbar.add("item", "island.brightness_icon", {
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

	local brightnessBarItem = ctx.Sbar.add("item", "island.brightness_bar", {
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
		ctx.Sbar.exec("sleep 0.8", function()
			if stateToken ~= token then
				return
			end

			ctx.Sbar.animate("tanh", 15, function()
				brightnessIconItem:set({
					icon = {
						color = ctx.colorTransparent,
					},
				})
				brightnessBarItem:set({
					background = {
						color = ctx.colorTransparent,
						border_color = ctx.colorTransparent,
					},
				})
			end)

			ctx.Sbar.exec("sleep 0.1", function()
				if stateToken ~= token then
					return
				end

				ctx.Sbar.animate("tanh", 5, function()
					brightnessBarItem:set({
						width = 0,
					})
				end)

				ctx.Sbar.exec("sleep 0.4", function()
					if stateToken ~= token then
						return
					end

					brightnessIconItem:set({ drawing = false })
					brightnessBarItem:set({ drawing = false })

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

	local brightnessChangeListener = ctx.Sbar.add("item", "brightnessChangeListener", {
		position = "center",
		width = 0,
	})

	brightnessChangeListener:subscribe("brightness_change", function(env)
		local brightness = toPercent(env.INFO)
		local icon = ctx.get("icons.brightness.low", "􀆫")
		if brightness >= 40 then
			icon = ctx.get("icons.brightness.high", "􀆭")
		end

		ctx.appendLog(
			ctx.debugLogPath,
			"[brightness][lua] info=" .. tostring(env.INFO) .. " percent=" .. tostring(brightness)
		)
		stateToken = stateToken + 1
		local token = stateToken

		brightnessIconItem:set({
			drawing = true,
			icon = {
				string = icon,
			},
		})
		brightnessBarItem:set({
			drawing = true,
		})

		ctx.Sbar.animate("tanh", 10, function()
			ctx.Sbar.bar({
				margin = brightnessExpandMargin,
				corner_radius = brightnessCornerRadius,
				height = brightnessMaxExpandHeight,
			})
			ctx.Sbar.bar({
				height = brightnessExpandHeight,
			})
		end)

		local barWidth = math.floor((brightness / 100) * (brightnessMaxExpandWidth * 2 - 20) + 0.5)
		ctx.Sbar.animate("tanh", 15, function()
			brightnessBarItem:set({
				width = barWidth,
			})
		end)

		ctx.Sbar.animate("sin", 10, function()
			brightnessBarItem:set({
				background = {
					color = ctx.colorWhite,
					border_color = ctx.colorWhite,
				},
			})
			brightnessIconItem:set({
				icon = {
					color = ctx.colorWhite,
				},
			})
		end)

		resetMeter(token)
	end)

	if ctx.registry ~= nil then
		ctx.registry.brightnessIconItem = brightnessIconItem
		ctx.registry.brightnessBarItem = brightnessBarItem
		ctx.registry.brightnessChangeListener = brightnessChangeListener
	end

	ctx.subscribeItem("brightnessChangeListener", "brightness_change")
	ctx.appendLog(ctx.debugLogPath, "[brightness][lua] module loaded")
end
