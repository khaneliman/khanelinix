return function(ctx)
	local token = 0
	local lastClipboard = nil
	local inFlight = false

	local maxExpandWidth = ctx.expandedHalfWidth("islands.clipboard.maxExpandWidth", 185)
	local expandHeight = ctx.asNumber(ctx.get("islands.clipboard.expandHeight", "85"), 85)
	local cornerRad = ctx.asNumber(ctx.get("islands.clipboard.cornerRadius", "15"), 15)
	local pollInterval = ctx.asNumber(ctx.get("islands.clipboard.pollInterval", "20"), 20)
	local maxPreviewLength = ctx.asNumber(ctx.get("islands.clipboard.maxPreviewLength", "120"), 120)

	local function truncatePreview(value)
		if #value <= maxPreviewLength then
			return value
		end
		return value:sub(1, maxPreviewLength - 1) .. "…"
	end

	local textItem = ctx.Sbar.add("item", "island.clipboard_text", {
		position = "center",
		drawing = false,
		label = {
			align = "center",
			color = ctx.colorTransparent,
			max_chars = ctx.layout.text.clipboardMaxChars,
			y_offset = ctx.contentYOffset,
		},
		width = ctx.layout.dimensions.emptyWidth,
	})

	local listener = ctx.Sbar.add("item", "clipboardListener", {
		position = "center",
		width = ctx.layout.dimensions.emptyWidth,
		update_freq = pollInterval,
	})

	local function showClipboard(content)
		local displayText = ctx.get("icons.clipboard.copied", "􀉂") .. " Copied: " .. content
		local layout = ctx.layoutForText(displayText, {
			maxHalfWidth = maxExpandWidth,
			horizontalPadding = ctx.layout.text.alertHorizontalPadding,
		})

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
			duration = ctx.layout.animation.clipboardDuration,
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
	end

	listener:subscribe("routine", function()
		if ctx.islandState.isSleeping then
			return
		end
		if inFlight then
			return
		end
		inFlight = true

		ctx.Sbar.exec("pbpaste", function(content)
			inFlight = false
			if not content or content == "" then
				return
			end

			local firstLine = content:match("([^\r\n]+)") or ""
			local trimmed = truncatePreview(ctx.trim(firstLine))
			if trimmed == "" then
				return
			end

			if lastClipboard == nil then
				lastClipboard = trimmed
				return
			end

			if trimmed ~= lastClipboard then
				ctx.logDebug("[clipboard][lua] new content detected")
				showClipboard(trimmed)
				lastClipboard = trimmed
			end
		end)
	end)

	ctx.registry.clipboardTextItem = textItem
	ctx.registry.clipboardListener = listener
	ctx.subscribeItem("clipboardListener", "routine")
	ctx.logDebug("[clipboard][lua] module loaded")
end
