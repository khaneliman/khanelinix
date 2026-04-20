return function(ctx)
	local token = 0
	local artworkRetryToken = 0
	local lastDisplayText = nil
	local lastHasArt = nil
	local lastPlaybackState = nil
	local lastSourceName = nil
	local artPath = "/tmp/sketchybar_cover.jpg"
	local noTrackMarker = "__DYNAMIC_ISLAND_NO_TRACK__"
	local resultSeparator = "|||"

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.music.info.maxExpandWidth", "190"), 190)
	local maxExpandWidthPx = ctx.calculateIslandWidth(maxExpandWidth)
	local expandHeight = ctx.asNumber(ctx.get("islands.music.info.expandHeight", "100"), 100)
	local cornerRad = ctx.asNumber(ctx.get("islands.music.info.cornerRadius", "19"), 19)
	local expandMargin = ctx.calculateMargin(maxExpandWidth)
	local imageScale = 0.15
	local imageYOffset = -6
	local artworkSlotWidth = 92
	local compactSlotWidth = 44
	local slotPaddingLeft = 18
	local slotPaddingRight = 8
	local slotYOffset = -10
	local contentPaddingRight = 20
	local titleYOffset = -16
	local subtitleYOffset = 0
	local titleColor = ctx.colorWhite
	local subtitleColor = ctx.get("colors.musicSecondary", "0xffb8b8b8")
	local compactBadgeColor = ctx.get("colors.musicBadge", "0x22ffffff")
	local maxArtworkRetryAttempts = 4
	local artworkRetryDelaySeconds = 0.6
	local musicUpdateDebounceSeconds = 0.15
	local musicUpdateRequestToken = 0
	local pendingMusicUpdateSender = nil

	local function resolveTextWidth(slotWidth)
		return math.max(140, maxExpandWidthPx - slotWidth - slotPaddingLeft - slotPaddingRight - contentPaddingRight)
	end

	local function splitDisplayText(displayText, sourceName)
		local trimmed = ctx.trim(displayText or "")
		if trimmed == "" then
			return "", sourceName or "Now Playing"
		end

		local artist, track = trimmed:match("^(.-)%s+%-%s+(.+)$")
		if artist ~= nil and track ~= nil then
			return ctx.trim(track), ctx.trim(artist)
		end

		return trimmed, sourceName or "Now Playing"
	end

	-- Art item on the left
	local artItem = ctx.Sbar.add("item", "island.music_art", {
		position = "left",
		drawing = false,
		icon = {
			drawing = false,
			align = "center",
		},
		background = {
			color = ctx.colorTransparent,
			corner_radius = 14,
			image = {
				drawing = true,
				scale = imageScale,
				y_offset = imageYOffset,
				corner_radius = 12,
				padding_left = 6,
				padding_right = 6,
			},
		},
		padding_left = slotPaddingLeft,
		padding_right = slotPaddingRight,
		width = artworkSlotWidth,
		y_offset = slotYOffset,
	})

	local titleItem = ctx.Sbar.add("item", "island.music_title", {
		position = "left",
		drawing = false,
		label = {
			align = "left",
			color = ctx.colorTransparent,
			width = resolveTextWidth(artworkSlotWidth),
			max_chars = 34,
			y_offset = titleYOffset,
			padding_left = 4,
			padding_right = contentPaddingRight,
			font = {
				family = ctx.fontFamily,
				style = "Bold",
				size = 16.0,
			},
		},
		width = 0,
	})

	local subtitleItem = ctx.Sbar.add("item", "island.music_subtitle", {
		position = "left",
		drawing = false,
		label = {
			align = "left",
			color = ctx.colorTransparent,
			width = resolveTextWidth(artworkSlotWidth),
			max_chars = 38,
			y_offset = subtitleYOffset,
			padding_left = 4,
			padding_right = contentPaddingRight,
			font = {
				family = ctx.fontFamily,
				style = "Medium",
				size = 12.0,
			},
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
		titleItem:set({
			drawing = false,
			label = { color = ctx.colorTransparent },
		})
		subtitleItem:set({
			drawing = false,
			label = { color = ctx.colorTransparent },
		})
		artItem:set({
			drawing = false,
			width = artworkSlotWidth,
			icon = { drawing = false, string = "" },
			background = {
				color = ctx.colorTransparent,
				height = 0,
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
		titleItem:set({
			drawing = false,
			label = { color = ctx.colorTransparent },
		})
		subtitleItem:set({
			drawing = false,
			label = { color = ctx.colorTransparent },
		})
		artItem:set({
			drawing = false,
			width = artworkSlotWidth,
			icon = { drawing = false, string = "" },
			background = {
				color = ctx.colorTransparent,
				height = 0,
				image = {
					drawing = false,
					string = "",
				},
			},
		})
	end

	local function expandMusic(displayText, hasArt, sourceName)
		local titleText, subtitleText = splitDisplayText(displayText, sourceName)
		local slotWidth = hasArt and artworkSlotWidth or compactSlotWidth
		local textWidth = resolveTextWidth(slotWidth)

		if hasArt then
			artItem:set({
				drawing = true,
				width = slotWidth,
				background = {
					color = ctx.colorTransparent,
					height = 0,
					image = {
						drawing = true,
						string = artPath,
						scale = imageScale,
						y_offset = imageYOffset,
						corner_radius = 12,
						padding_left = 6,
						padding_right = 6,
					},
				},
				icon = { drawing = false, string = "" },
			})
		else
			artItem:set({
				drawing = true,
				width = slotWidth,
				background = {
					color = compactBadgeColor,
					height = 32,
					corner_radius = 16,
					image = {
						drawing = false,
						string = "",
						scale = imageScale,
						y_offset = imageYOffset,
						corner_radius = 12,
						padding_left = 6,
						padding_right = 6,
					},
				},
				icon = {
					drawing = true,
					string = "􀑪",
					color = ctx.colorWhite,
					font = {
						family = ctx.fontFamily,
						style = "Bold",
						size = 18.0,
					},
				},
			})
		end

		titleItem:set({
			drawing = true,
			label = {
				string = titleText,
				color = titleColor,
				width = textWidth,
			},
		})
		subtitleItem:set({
			drawing = subtitleText ~= "",
			label = {
				string = subtitleText,
				color = subtitleColor,
				width = textWidth,
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

		expandMusic(lastDisplayText, lastHasArt == true, lastSourceName)
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
				lastSourceName = nil
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

			if displayText == lastDisplayText and hasArt == lastHasArt and playbackState == lastPlaybackState and app == lastSourceName then
				return
			end

			lastDisplayText = displayText
			lastHasArt = hasArt
			lastPlaybackState = playbackState
			lastSourceName = app

			syncPersistentMusic()
			ctx.logInfo(
				"[music][lua] track updated state="
					.. tostring(playbackState)
					.. " hasArt="
					.. tostring(hasArt)
					.. " source="
					.. tostring(app)
					.. " text="
					.. displayText
			)
			expandMusic(displayText, hasArt, app)
		end)
	end

	listener:subscribe({ "apple_music_update", "spotify_update" }, function(env)
		if ctx.islandState.isSleeping then
			return
		end
		ctx.logDebug("[music][lua] notification received from " .. tostring(env.SENDER))
		requestMusicUpdate(env.SENDER)
	end)

	ctx.registry.musicTitleItem = titleItem
	ctx.registry.musicSubtitleItem = subtitleItem
	ctx.registry.musicArtItem = artItem
	ctx.registry.musicListener = listener
	ctx.subscribeItem("musicListener", { "apple_music_update", "spotify_update" })
	ctx.logDebug("[music][lua] module loaded with darwin notifications & artwork")
end
