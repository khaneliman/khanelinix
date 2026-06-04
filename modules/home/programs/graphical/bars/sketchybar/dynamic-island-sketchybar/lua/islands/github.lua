return function(ctx)
	local token = 0

	local minExpandWidth = ctx.asNumber(ctx.get("islands.github.minExpandWidth", "150"), 150)
	local maxExpandWidth = ctx.asNumber(ctx.get("islands.github.maxExpandWidth", "190"), 190)
	local expandHeight = ctx.asNumber(ctx.get("islands.github.expandHeight", "95"), 95)
	local cornerRad = ctx.asNumber(ctx.get("islands.github.cornerRadius", "32"), 32)

	local function layoutForText(text)
		return ctx.layoutForText(text, {
			minHalfWidth = minExpandWidth,
			maxHalfWidth = maxExpandWidth,
			charWidth = 3.8,
			horizontalPadding = 66,
		})
	end

	local textItem = ctx.Sbar.add("item", "island.github_text", {
		position = "center",
		drawing = false,
		label = {
			color = ctx.colorTransparent,
			max_chars = 40,
			align = "center",
			y_offset = ctx.contentYOffset,
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

		local displayText = "􀋚 " .. repo .. ": " .. title
		local layout = layoutForText(displayText)

		textItem:set({
			drawing = true,
			width = layout.width,
			label = {
				string = displayText,
			},
		})

		ctx.animateIsland({
			margin = layout.margin,
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
				textItem:set({
					drawing = false,
					width = 0,
				})
			end,
		})
	end)

	ctx.registry.githubTextItem = textItem
	ctx.registry.githubIslandListener = listener
	ctx.subscribeItem("githubIslandListener", "github_notification")
	ctx.logDebug("[github][lua] module loaded")
end
