return function(ctx)
	local token = 0
	local lastDisplayText = nil
	local lastHasArt = nil
	local artPath = "/tmp/sketchybar_cover.jpg"
	local noTrackMarker = "__DYNAMIC_ISLAND_NO_TRACK__"

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.music.info.maxExpandWidth", "190"), 190)
	local expandHeight = ctx.asNumber(ctx.get("islands.music.info.expandHeight", "100"), 100)
	local cornerRad = ctx.asNumber(ctx.get("islands.music.info.cornerRadius", "19"), 19)
	local expandMargin = math.floor(ctx.monitorResolution / 2 - maxExpandWidth)

	-- Art item on the left
	local artItem = ctx.Sbar.add("item", "island.music_art", {
		position = "left",
		drawing = false,
		icon = { drawing = false },
		background = {
			color = ctx.colorTransparent,
			image = {
				scale = 0.8,
			},
		},
		padding_left = 15,
		y_offset = -20, -- Pushing it below the notch
	})

	-- Text item on the right
	local textItem = ctx.Sbar.add("item", "island.music_text", {
		position = "right",
		drawing = false,
		label = {
			color = ctx.colorTransparent,
			max_chars = 30,
			y_offset = -20, -- Pushing it below the notch
			padding_right = 20,
		},
		width = 0,
	})

	local listener = ctx.Sbar.add("item", "musicListener", {
		position = "center",
		width = 0,
		updates = true,
	})

	-- Register Darwin distributed notifications
	ctx.Sbar.add("event", "apple_music_update", "com.apple.Music.playerInfo")
	ctx.Sbar.add("event", "spotify_update", "com.spotify.client.PlaybackStateChanged")

	local function updateMusic(env)
		local app = "Music"
		if env.SENDER == "spotify_update" then
			app = "Spotify"
		end

		-- Get metadata via osascript for reliability and extract artwork if Apple Music
		local script
		if app == "Music" then
			script = [[
				try
					tell application "Music"
						set trackArtist to artist of current track
						set trackName to name of current track
						try
							set theArt to raw data of artwork 1 of current track
							set fileName to "]] .. artPath .. [["
							set fileRef to open for access fileName with write permission
							set eof fileRef to 0
							write theArt to fileRef starting at 0
							close access fileRef
						on error
							do shell script "rm -f ]] .. artPath .. [["
						end try
						return trackArtist & " - " & trackName
					end tell
				on error
					do shell script "rm -f ]] .. artPath .. [["
					return "]] .. noTrackMarker .. [["
				end try
			]]
		else
			script = [[
				try
					do shell script "rm -f ]] .. artPath .. [["
					tell application "Spotify" to get artist of current track & " - " & name of current track
				on error
					do shell script "rm -f ]] .. artPath .. [["
					return "]] .. noTrackMarker .. [["
				end try
			]]
		end

		ctx.Sbar.exec("osascript -e '" .. script .. "'", function(result)
			if not result or result == "" then
				return
			end

			local display_text = ctx.trim(result)
			if display_text == noTrackMarker then
				lastDisplayText = nil
				lastHasArt = nil
				return
			end

			local has_art = ctx.fileExists(artPath)
			if display_text == lastDisplayText and has_art == lastHasArt then
				return
			end
			lastDisplayText = display_text
			lastHasArt = has_art

			token = token + 1
			local current = token

			ctx.logDebug("[music][lua] track updated: " .. display_text)

			if has_art then
				artItem:set({
					drawing = true,
					icon = { drawing = false },
					background = { image = { string = artPath } },
				})
			else
				artItem:set({
					drawing = true,
					background = { image = { string = "" } },
					icon = { drawing = true, string = "􀑪", color = ctx.colorWhite, font = { size = 20 } },
				})
			end

			textItem:set({
				drawing = true,
				label = {
					string = display_text,
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

			ctx.delay(3.5, function()
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
					artItem:set({ drawing = false, icon = { drawing = false } })

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
	end

	listener:subscribe({ "apple_music_update", "spotify_update" }, function(env)
		ctx.logDebug("[music][lua] notification received from " .. tostring(env.SENDER))
		updateMusic(env)
	end)

	ctx.registry.musicTextItem = textItem
	ctx.registry.musicArtItem = artItem
	ctx.registry.musicListener = listener
	ctx.subscribeItem("musicListener", { "apple_music_update", "spotify_update" })
	ctx.logDebug("[music][lua] module loaded with darwin notifications & artwork")
end
