return function(ctx)
	local token = 0

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.github.maxExpandWidth", "220"), 220)
	local expandHeight = ctx.asNumber(ctx.get("islands.github.expandHeight", "95"), 95)
	local cornerRad = ctx.asNumber(ctx.get("islands.github.cornerRadius", "42"), 42)
	local expandMargin = ctx.calculateMargin(maxExpandWidth)

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

		local title = env.TITLE or "New GitHub Notifications"
		local repo = env.REPO or "GitHub"

		ctx.logDebug("[github][lua] notification received: " .. repo)

		textItem:set({
			drawing = true,
			label = {
				string = "􀋚 " .. repo .. ": " .. title,
			},
		})

		ctx.animateIsland({
			margin = expandMargin,
			cornerRadius = cornerRad,
			height = expandHeight,
			duration = 4.0,
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

	ctx.registry.githubTextItem = textItem
	ctx.registry.githubIslandListener = listener
	ctx.subscribeItem("githubIslandListener", "github_notification")
	ctx.logDebug("[github][lua] module loaded")
end
