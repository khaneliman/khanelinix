return function(ctx)
	local token = 0
	local artworkRetryToken = 0
	local lastDisplayText = nil
	local lastHasArt = nil
	local lastPlaybackState = nil
	local artPath = "/tmp/sketchybar_cover.jpg"
	local noTrackMarker = "__DYNAMIC_ISLAND_NO_TRACK__"
	local resultSeparator = "|||"

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.music.info.maxExpandWidth", "190"), 190)
	local expandHeight = ctx.asNumber(ctx.get("islands.music.info.expandHeight", "100"), 100)
	local cornerRad = ctx.asNumber(ctx.get("islands.music.info.cornerRadius", "19"), 19)
	local expandMargin = ctx.calculateMargin(maxExpandWidth)
	local imageScale = 0.15
	local imageYOffset = -10
	local artSlotWidth = 118
	local textWidth = math.max(120, maxExpandWidth * 2 - artSlotWidth - 28)
	local contentYOffset = -12
	local maxArtworkRetryAttempts = 4
	local artworkRetryDelaySeconds = 0.6
	local musicUpdateDebounceSeconds = 0.15
	local musicUpdateRequestToken = 0
	local pendingMusicUpdateSender = nil

	-- Art item on the left
	local artItem = ctx.Sbar.add("item", "island.music_art", {
		position = "left",
		drawing = false,
		icon = { drawing = false },
		background = {
			color = ctx.colorTransparent,
			corner_radius = 10,
			image = {
				drawing = true,
				scale = imageScale,
				y_offset = imageYOffset,
				corner_radius = 10,
				padding_left = 6,
				padding_right = 6,
			},
		},
		padding_left = 16,
		padding_right = 0,
		width = artSlotWidth,
		y_offset = contentYOffset,
	})

	-- Text item on the right
	local textItem = ctx.Sbar.add("item", "island.music_text", {
		position = "left",
		drawing = false,
		label = {
			align = "left",
			color = ctx.colorTransparent,
			width = textWidth,
			y_offset = contentYOffset,
			padding_left = 4,
			padding_right = 18,
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

	local function collapseMusic()
		textItem:set({
			drawing = false,
			label = { color = ctx.colorTransparent },
		})
		artItem:set({
			drawing = false,
			icon = { drawing = false, string = "" },
			background = {
				image = {
					drawing = false,
					string = "",
				},
			},
		})

		ctx.Sbar.animate("tanh", 10, function()
			ctx.Sbar.bar({
				height = ctx.defaultHeight,
				corner_radius = ctx.cornerRadius,
				margin = ctx.margin,
			})
		end)
	end

	local function suspendMusic()
		textItem:set({
			drawing = false,
			label = { color = ctx.colorTransparent },
		})
		artItem:set({
			drawing = false,
			icon = { drawing = false, string = "" },
			background = {
				image = {
					drawing = false,
					string = "",
				},
			},
		})
	end

	local function expandMusic(displayText, hasArt)
		if hasArt then
			artItem:set({
				drawing = true,
				background = {
					image = {
						drawing = true,
						string = artPath,
						scale = imageScale,
						y_offset = imageYOffset,
						corner_radius = 10,
						padding_left = 6,
						padding_right = 6,
					},
				},
				icon = { drawing = false, string = "" },
			})
		else
			artItem:set({
				drawing = true,
				background = {
					image = {
						drawing = false,
						string = "",
						scale = imageScale,
						y_offset = imageYOffset,
						corner_radius = 10,
						padding_left = 6,
						padding_right = 6,
					},
				},
				icon = { drawing = true, string = "􀑪", color = ctx.colorWhite, font = { size = 20 } },
			})
		end

		textItem:set({
			drawing = true,
			label = {
				string = displayText,
				color = ctx.colorWhite,
			},
		})

		ctx.Sbar.animate("tanh", 10, function()
			ctx.Sbar.bar({
				margin = expandMargin,
				corner_radius = cornerRad,
				height = expandHeight,
			})
		end)
	end

	local function restoreMusic()
		if lastPlaybackState ~= "playing" or lastDisplayText == nil then
			return
		end

		expandMusic(lastDisplayText, lastHasArt == true)
	end

	local function syncPersistentMusic()
		if lastPlaybackState == "playing" and lastDisplayText ~= nil then
			ctx.setPersistentIsland("music", {
				hide = suspendMusic,
				restore = restoreMusic,
			})
			return
		end

		ctx.clearPersistentIsland("music")
	end

	local function parseMusicResult(result)
		local trimmed = ctx.trim(result or "")
		if trimmed == "" then
			return nil, nil
		end

		local separatorStart, separatorEnd = string.find(trimmed, resultSeparator, 1, true)
		if separatorStart == nil then
			return nil, trimmed
		end

		local playbackState = ctx.trim(string.sub(trimmed, 1, separatorStart - 1))
		local displayText = ctx.trim(string.sub(trimmed, separatorEnd + 1))
		return string.lower(playbackState), displayText
	end

	local updateMusic

	local function cancelArtworkRetry()
		artworkRetryToken = artworkRetryToken + 1
	end

	local function requestMusicUpdate(sender)
		musicUpdateRequestToken = musicUpdateRequestToken + 1
		pendingMusicUpdateSender = sender or "apple_music_update"
		local current = musicUpdateRequestToken

		ctx.delay(musicUpdateDebounceSeconds, function()
			if current ~= musicUpdateRequestToken then
				return
			end

			local updateSender = pendingMusicUpdateSender
			pendingMusicUpdateSender = nil
			updateMusic({ SENDER = updateSender })
		end)
	end

	updateMusic = function(env, attempt, expectedDisplayText)
		attempt = attempt or 0
		local app = "Music"
		if env.SENDER == "spotify_update" then
			app = "Spotify"
		end

		local script
		if app == "Music" then
			script = [[
				try
					if application "Music" is not running then
						do shell script "rm -f ]] .. artPath .. [["
						return "stopped|||__DYNAMIC_ISLAND_NO_TRACK__"
					end if
					tell application "Music"
						set playbackState to player state as string
						if playbackState is "stopped" or playbackState is "paused" then
							do shell script "rm -f ]] .. artPath .. [["
							return playbackState & "]] .. resultSeparator .. [[" & "]] .. noTrackMarker .. [["
						end if
						set currentTrack to current track
						if currentTrack is missing value then
							do shell script "rm -f ]] .. artPath .. [["
							return playbackState & "]] .. resultSeparator .. [[" & "]] .. noTrackMarker .. [["
						end if
						set trackArtist to artist of currentTrack
						set trackName to name of currentTrack
						try
							set artFile to POSIX file "]] .. artPath .. [["
							try
								close access artFile
							end try
							if (count of artworks of currentTrack) is 0 then
								do shell script "rm -f ]] .. artPath .. [["
							else
								set theArt to raw data of artwork 1 of currentTrack
								set fileRef to open for access artFile with write permission
								set eof of fileRef to 0
								write theArt to fileRef starting at eof
								close access fileRef
							end if
						on error
							try
								close access (POSIX file "]] .. artPath .. [[")
							end try
							do shell script "rm -f ]] .. artPath .. [["
						end try
						return playbackState & "]] .. resultSeparator .. [[" & trackArtist & " - " & trackName
					end tell
				on error
					do shell script "rm -f ]] .. artPath .. [["
					return "stopped|||__DYNAMIC_ISLAND_NO_TRACK__"
				end try
			]]
		else
			script = [[
				try
					if application "Spotify" is not running then
						do shell script "rm -f ]] .. artPath .. [["
						return "stopped|||__DYNAMIC_ISLAND_NO_TRACK__"
					end if
					tell application "Spotify"
						set playbackState to player state as string
						if playbackState is "stopped" or playbackState is "paused" then
							do shell script "rm -f ]] .. artPath .. [["
							return playbackState & "]] .. resultSeparator .. [[" & "]] .. noTrackMarker .. [["
						end if
						set currentTrack to current track
						if currentTrack is missing value then
							do shell script "rm -f ]] .. artPath .. [["
							return playbackState & "]] .. resultSeparator .. [[" & "]] .. noTrackMarker .. [["
						end if
						do shell script "rm -f ]] .. artPath .. [["
						return playbackState & "]] .. resultSeparator .. [[" & artist of currentTrack & " - " & name of currentTrack
					end tell
				on error
					do shell script "rm -f ]] .. artPath .. [["
					return "stopped|||__DYNAMIC_ISLAND_NO_TRACK__"
				end try
			]]
		end

		token = token + 1
		local current = token

		ctx.Sbar.exec("osascript -e '" .. script .. "'", function(result)
			if current ~= token then
				return
			end

			if not result or result == "" then
				return
			end

			local playbackState, displayText = parseMusicResult(result)
			if displayText == nil then
				return
			end
			if expectedDisplayText ~= nil and displayText ~= expectedDisplayText then
				return
			end

			if displayText == noTrackMarker or playbackState ~= "playing" then
				cancelArtworkRetry()
				lastDisplayText = nil
				lastHasArt = nil
				lastPlaybackState = playbackState
				syncPersistentMusic()
				ctx.logDebug("[music][lua] collapsing state=" .. tostring(playbackState))
				collapseMusic()
				return
			end

			local hasArt = ctx.fileExists(artPath)
			if app == "Music" and not hasArt and attempt < maxArtworkRetryAttempts then
				local retryToken = artworkRetryToken + 1
				artworkRetryToken = retryToken
				ctx.logDebug(
					"[music][lua] artwork missing; retry "
						.. tostring(attempt + 1)
						.. "/"
						.. tostring(maxArtworkRetryAttempts)
						.. " for "
						.. displayText
				)
				ctx.delay(artworkRetryDelaySeconds, function()
					if retryToken ~= artworkRetryToken then
						return
					end
					if lastPlaybackState ~= "playing" then
						return
					end
					if lastDisplayText ~= nil and lastDisplayText ~= displayText then
						return
					end

					updateMusic({ SENDER = "apple_music_update" }, attempt + 1, displayText)
				end)
			else
				cancelArtworkRetry()
			end

			if displayText == lastDisplayText and hasArt == lastHasArt and playbackState == lastPlaybackState then
				return
			end

			lastDisplayText = displayText
			lastHasArt = hasArt
			lastPlaybackState = playbackState

			syncPersistentMusic()
			ctx.logInfo(
				"[music][lua] track updated state="
					.. tostring(playbackState)
					.. " hasArt="
					.. tostring(hasArt)
					.. " text="
					.. displayText
			)
			expandMusic(displayText, hasArt)
		end)
	end

	listener:subscribe({ "apple_music_update", "spotify_update" }, function(env)
		if ctx.islandState.isSleeping then
			return
		end
		ctx.logDebug("[music][lua] notification received from " .. tostring(env.SENDER))
		requestMusicUpdate(env.SENDER)
	end)

	ctx.registry.musicTextItem = textItem
	ctx.registry.musicArtItem = artItem
	ctx.registry.musicListener = listener
	ctx.subscribeItem("musicListener", { "apple_music_update", "spotify_update" })
	ctx.logDebug("[music][lua] module loaded with darwin notifications & artwork")
end
