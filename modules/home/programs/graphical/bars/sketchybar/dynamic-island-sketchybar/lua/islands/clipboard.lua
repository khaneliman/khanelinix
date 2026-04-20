return function(ctx)
	local token = 0
	local lastClipboard = nil
	local inFlight = false

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.clipboard.maxExpandWidth", "180"), 180)
	local expandHeight = ctx.asNumber(ctx.get("islands.clipboard.expandHeight", "85"), 85)
	local cornerRad = ctx.asNumber(ctx.get("islands.clipboard.cornerRadius", "15"), 15)
	local expandMargin = ctx.calculateMargin(maxExpandWidth)
	local pollInterval = ctx.asNumber(ctx.get("islands.clipboard.pollInterval", "20"), 20)
	local maxPreviewLength = ctx.asNumber(ctx.get("islands.clipboard.maxPreviewLength", "120"), 120)

	local function truncatePreview(value)
		if #value <= maxPreviewLength then
			return value
		end
		return value:sub(1, maxPreviewLength - 1) .. "…"
	end

	local textItem = ctx.Sbar.add("item", "island.clipboard_text", {
		position = "left",
		drawing = false,
		label = {
			color = ctx.colorTransparent,
			max_chars = 25,
			y_offset = -30, -- Pushing it deeper below the notch
		},
		width = 0,
	})

	local listener = ctx.Sbar.add("item", "clipboardListener", {
		position = "center",
		width = 0,
		update_freq = pollInterval,
	})

	local function showClipboard(content)
		textItem:set({
			drawing = true,
			label = {
				string = "􀉂 Copied: " .. content,
			},
		})

		ctx.animateIsland({
			margin = expandMargin,
			cornerRadius = cornerRad,
			height = expandHeight,
			duration = 1.2,
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
