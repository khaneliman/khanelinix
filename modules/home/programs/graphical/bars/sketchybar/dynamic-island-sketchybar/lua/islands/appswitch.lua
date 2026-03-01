return function(ctx)
	local token = 0

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.appswitch.maxExpandWidth", "110"), 110)
	local expandHeight = ctx.asNumber(ctx.get("islands.appswitch.expandHeight", "56"), 56)
	local cornerRad = ctx.asNumber(ctx.get("islands.appswitch.cornerRadius", "15"), 15)
	local maxExpandHeight = expandHeight + math.floor(ctx.squishAmount / 2)

	local labelItem = ctx.Sbar.add("item", "island.appname", {
		position = "right",
		drawing = false,
		label = {
			color = ctx.colorTransparent,
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
		local expandSize = maxExpandWidth + charLength * 7
		local expandMargin = math.floor(ctx.monitorResolution / 2 - expandSize)

		ctx.appendLog(ctx.debugLogPath, "[appswitch][lua] app='" .. appName .. "' expandSize=" .. tostring(expandSize))

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

	ctx.registry.appswitchLabelItem = labelItem
	ctx.registry.appswitchListener = listener
	ctx.subscribeItem("frontAppSwitchListener", "front_app_switched")
	ctx.appendLog(ctx.debugLogPath, "[appswitch][lua] module loaded")
end
