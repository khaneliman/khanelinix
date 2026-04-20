return function(ctx)
	local token = 0
	local lastAppName = nil
	local lastAppDeadline = 0

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.appswitch.maxExpandWidth", "110"), 110)
	local expandHeight = ctx.asNumber(ctx.get("islands.appswitch.expandHeight", "56"), 56)
	local cornerRad = ctx.asNumber(ctx.get("islands.appswitch.cornerRadius", "15"), 15)
	local maxExpandHeight = expandHeight + math.floor(ctx.squishAmount / 2)
	local repeatCooldownSeconds = ctx.asNumber(ctx.get("islands.appswitch.repeatCooldownSeconds", "2"), 2)

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
		if ctx.islandState.isSleeping then
			return
		end
		local appName = ctx.trim(env.INFO or "")
		if appName == "" then
			return
		end

		local now = os.time()
		if appName == lastAppName and now < lastAppDeadline then
			ctx.logDebug("[appswitch][lua] suppress duplicate app switch for '" .. appName .. "'")
			return
		end

		lastAppName = appName
		lastAppDeadline = now + repeatCooldownSeconds
		ctx.hidePersistentIsland("appswitch")

		local charLength = string.len(appName)
		local expandSize = maxExpandWidth + charLength * 7 + 40 -- added width for icon
		local expandMargin = ctx.calculateMargin(expandSize)

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

		ctx.animateIsland({
			margin = expandMargin,
			cornerRadius = cornerRad,
			height = expandHeight,
			maxExpandHeight = maxExpandHeight,
			duration = 0.8,
			preventCollapse = true,
			onExpand = function()
				labelItem:set({ label = { color = ctx.colorWhite } })
			end,
			onHideContent = function()
				labelItem:set({ label = { color = ctx.colorTransparent } })
			end,
			onCleanup = function(interrupted)
				labelItem:set({ drawing = false })
				iconItem:set({ drawing = false })
				if interrupted then
					return
				end
				if not ctx.restorePersistentIsland("appswitch") then
					ctx.Sbar.animate("tanh", 10, function()
						ctx.Sbar.bar({
							height = ctx.defaultHeight,
							corner_radius = ctx.cornerRadius,
							margin = ctx.margin,
						})
					end)
				end
			end,
		})
	end)

	ctx.registry.appswitchIconItem = iconItem
	ctx.registry.appswitchLabelItem = labelItem
	ctx.registry.appswitchListener = listener
	ctx.subscribeItem("frontAppSwitchListener", "front_app_switched")
	ctx.logDebug("[appswitch][lua] module loaded")
end
