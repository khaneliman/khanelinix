return function(ctx)
	local token = 0
	local lastClipboard = nil

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.clipboard.maxExpandWidth", "180"), 180)
	local expandHeight = ctx.asNumber(ctx.get("islands.clipboard.expandHeight", "85"), 85)
	local cornerRad = ctx.asNumber(ctx.get("islands.clipboard.cornerRadius", "15"), 15)
	local expandMargin = math.floor(ctx.monitorResolution / 2 - maxExpandWidth)

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
		update_freq = 2, -- Check every 2 seconds
	})

	local function showClipboard(content)
		token = token + 1
		local current = token

		textItem:set({
			drawing = true,
			label = {
				string = "􀉂 Copied: " .. content,
			},
		})

		ctx.Sbar.animate("tanh", 10, function()
			ctx.Sbar.bar({
				margin = expandMargin,
				corner_radius = cornerRad,
				height = expandHeight,
			})
			textItem:set({
				label = { color = ctx.colorWhite },
			})
		end)

		ctx.Sbar.exec("sleep 1.2", function()
			if current ~= token then
				return
			end

			ctx.Sbar.animate("tanh", 10, function()
				textItem:set({ label = { color = ctx.colorTransparent } })
			end)

			ctx.Sbar.exec("sleep 0.2", function()
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
	end

	listener:subscribe("routine", function()
		ctx.Sbar.exec("pbpaste | head -n 1", function(content)
			if not content or content == "" then
				return
			end

			local trimmed = ctx.trim(content)
			if trimmed == "" then
				return
			end

			if lastClipboard == nil then
				lastClipboard = trimmed
				return
			end

			if trimmed ~= lastClipboard then
				ctx.appendLog(ctx.debugLogPath, "[clipboard][lua] new content detected")
				showClipboard(trimmed)
				lastClipboard = trimmed
			end
		end)
	end)

	ctx.registry.clipboardTextItem = textItem
	ctx.registry.clipboardListener = listener
	ctx.subscribeItem("clipboardListener", "routine")
	ctx.appendLog(ctx.debugLogPath, "[clipboard][lua] module loaded")
end
