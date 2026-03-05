return function(ctx)
	local token = 0

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.appswitch.maxExpandWidth", "110"), 110)
	local expandHeight = ctx.asNumber(ctx.get("islands.appswitch.expandHeight", "56"), 56)
	local cornerRad = ctx.asNumber(ctx.get("islands.appswitch.cornerRadius", "15"), 15)
	local maxExpandHeight = expandHeight + math.floor(ctx.squishAmount / 2)

	local iconItem = ctx.Sbar.add("item", "island.appicon", {
		position = "left",
		drawing = false,
		icon = {
			drawing = false,
		},
		background = {
			color = ctx.colorTransparent,
			image = {
				scale = 0.5,
			},
		},
		padding_left = 10,
		padding_right = 5,
		y_offset = -10, -- Pushing it below the notch
	})

	local labelItem = ctx.Sbar.add("item", "island.appname", {
		position = "left",
		drawing = false,
		label = {
			color = ctx.colorTransparent,
			y_offset = -10, -- Pushing it below the notch
		},
	})

	local listener = ctx.Sbar.add("item", "frontAppSwitchListener", {
		position = "center",
		width = 0,
	})

	listener:subscribe("front_app_switched", function(env)
		local appName = ctx.trim(env.INFO or "")
		if appName == "" then
			return
		end

		token = token + 1
		local current = token
		local charLength = string.len(appName)
		local expandSize = maxExpandWidth + charLength * 7 + 40 -- added width for icon
		local expandMargin = math.floor(ctx.monitorResolution / 2 - expandSize)

		ctx.logDebug("[appswitch][lua] app='" .. appName .. "' expandSize=" .. tostring(expandSize))

		iconItem:set({
			drawing = true,
			background = {
				image = {
					string = "app." .. appName,
				},
			},
		})

		labelItem:set({
			drawing = true,
			label = {
				string = appName,
			},
		})

		ctx.Sbar.animate("tanh", 10, function()
			ctx.Sbar.bar({
				margin = expandMargin,
				corner_radius = cornerRad,
				height = maxExpandHeight,
			})
			ctx.Sbar.bar({
				height = expandHeight,
			})
			labelItem:set({
				label = { color = ctx.colorWhite },
			})
		end)

		ctx.Sbar.exec("sleep 0.8", function()
			if current ~= token then
				return
			end

			ctx.Sbar.animate("tanh", 10, function()
				labelItem:set({
					label = { color = ctx.colorTransparent },
				})
			end)

			ctx.Sbar.exec("sleep 0.2", function()
				if current ~= token then
					return
				end

				labelItem:set({ drawing = false })
				iconItem:set({ drawing = false })
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

	ctx.registry.appswitchIconItem = iconItem
	ctx.registry.appswitchLabelItem = labelItem
	ctx.registry.appswitchListener = listener
	ctx.subscribeItem("frontAppSwitchListener", "front_app_switched")
	ctx.logDebug("[appswitch][lua] module loaded")
end
