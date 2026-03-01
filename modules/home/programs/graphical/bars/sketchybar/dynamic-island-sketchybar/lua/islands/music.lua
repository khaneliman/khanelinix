return function(ctx)
	local token = 0
	local musicSource = ctx.trim(ctx.get("islands.music.source", "Music"))

	local eventName = nil
	if musicSource == "Music" then
		eventName = "com.apple.Music.playerInfo"
	elseif musicSource == "Spotify" then
		eventName = "com.spotify.client.PlaybackStateChanged"
	end

	if eventName == nil then
		ctx.appendLog(ctx.debugLogPath, "[music][lua] unsupported source='" .. musicSource .. "'")
		return
	end

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.music.info.maxExpandWidth", "170"), 170)
	local expandHeight = ctx.asNumber(ctx.get("islands.music.info.expandHeight", "100"), 100)
	local cornerRad = ctx.asNumber(ctx.get("islands.music.info.cornerRadius", "19"), 19)
	local expandMargin = math.floor(ctx.monitorResolution / 2 - maxExpandWidth)

	local textItem = ctx.Sbar.add("item", "island.music_text", {
		position = "right",
		drawing = false,
		label = {
			color = ctx.colorTransparent,
		},
		width = 0,
	})

	ctx.Sbar.add("event", "music_change", eventName)
	local listener = ctx.Sbar.add("item", "musicListener", {
		position = "center",
		width = 0,
	})

	listener:subscribe("music_change", function(env)
		local info = ctx.trim(env.INFO or "")
		if info == "" then
			return
		end

		token = token + 1
		local current = token
		ctx.appendLog(ctx.debugLogPath, "[music][lua] event received")

		textItem:set({
			drawing = true,
			label = {
				string = "􀑪  Music Update",
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

		ctx.Sbar.exec("sleep 0.8", function()
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
	end)

	ctx.registry.musicTextItem = textItem
	ctx.registry.musicListener = listener
	ctx.subscribeItem("musicListener", "music_change")
	ctx.appendLog(ctx.debugLogPath, "[music][lua] module loaded source='" .. musicSource .. "'")
end
