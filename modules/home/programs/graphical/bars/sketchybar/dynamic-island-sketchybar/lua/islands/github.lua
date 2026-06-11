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
			charWidth = ctx.layout.text.githubCharWidth,
			horizontalPadding = ctx.layout.text.githubHorizontalPadding,
		})
	end

	local textItem = ctx.Sbar.add("item", "island.github_text", {
		position = "center",
		drawing = false,
		label = {
			color = ctx.colorTransparent,
			max_chars = ctx.layout.text.githubMaxChars,
			align = "center",
			y_offset = ctx.contentYOffset,
		},
		width = ctx.layout.dimensions.emptyWidth,
	})

	local listener = ctx.Sbar.add("item", "githubIslandListener", {
		position = "center",
		width = ctx.layout.dimensions.emptyWidth,
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

		local displayText = ctx.get("icons.github.notification", "􀋚") .. " " .. repo .. ": " .. title
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
			duration = ctx.layout.animation.longWarningDuration,
			onExpand = function()
				textItem:set({ label = { color = ctx.colorWhite } })
			end,
			onHideContent = function()
				textItem:set({ label = { color = ctx.colorTransparent } })
			end,
			onCleanup = function()
				textItem:set({
					drawing = false,
					width = ctx.layout.dimensions.emptyWidth,
				})
			end,
		})
	end)

	ctx.registry.githubTextItem = textItem
	ctx.registry.githubIslandListener = listener
	ctx.subscribeItem("githubIslandListener", "github_notification")
	ctx.logDebug("[github][lua] module loaded")
end
