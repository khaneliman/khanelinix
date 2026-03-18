return function(ctx)
	local token = 0

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.github.maxExpandWidth", "220"), 220)
	local expandHeight = ctx.asNumber(ctx.get("islands.github.expandHeight", "95"), 95)
	local cornerRad = ctx.asNumber(ctx.get("islands.github.cornerRadius", "42"), 42)
	local expandMargin = math.floor(ctx.monitorResolution / 2 - maxExpandWidth)

	local textItem = ctx.Sbar.add("item", "island.github_text", {
		position = "right",
		drawing = false,
		label = {
			color = ctx.colorTransparent,
			max_chars = 40,
			y_offset = -20, -- Pushing it below the notch
		},
		width = 0,
	})

	local listener = ctx.Sbar.add("item", "githubIslandListener", {
		position = "center",
		width = 0,
	})

	listener:subscribe("github_notification", function(env)
		if ctx.islandState.isSleeping then
			return
		end
		local count = tonumber(env.COUNT) or 0
		if count <= 0 then
			return
		end

		token = token + 1
		local current = token
		local title = env.TITLE or "New GitHub Notifications"
		local repo = env.REPO or "GitHub"

		ctx.logDebug("[github][lua] notification received: " .. repo)

		textItem:set({
			drawing = true,
			label = {
				string = "􀋚 " .. repo .. ": " .. title,
			},
		})

		ctx.Sbar.animate("tanh", 10, function()
			ctx.Sbar.bar({
				margin = expandMargin,
				corner_radius = cornerRad,
				height = expandHeight,
			})
			textItem:set({ label = { color = ctx.colorWhite } })
		end)

		ctx.delay(4.0, function()
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

	ctx.registry.githubTextItem = textItem
	ctx.registry.githubIslandListener = listener
	ctx.subscribeItem("githubIslandListener", "github_notification")
	ctx.logDebug("[github][lua] module loaded")
end
