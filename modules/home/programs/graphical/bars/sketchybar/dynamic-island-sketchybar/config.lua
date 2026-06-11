local layout = {
	spacing = {
		none = 0,
		default = 3,
		tight = 4,
		compact = 5,
		regular = 6,
		large = 10,
		content = 20,
	},

	dimensions = {
		emptyWidth = 0,
		expandedMinWidth = 135,
		meterBarHeight = 2,
		meterBarInset = 20,
	},

	fontSizes = {
		defaultIcon = 14.0,
		defaultLabel = 13.0,
		meterIcon = 14.0,
		musicTitle = 16.0,
		musicSubtitle = 12.0,
		musicCompactIcon = 18.0,
		privacyIcon = 10.0,
	},

	text = {
		defaultCharWidth = 7,
		defaultHorizontalPadding = 44,
		appswitchHorizontalPadding = 84,
		wifiHorizontalPadding = 34,
		powerHorizontalPadding = 36,
		alertHorizontalPadding = 40,
		githubCharWidth = 3.8,
		githubHorizontalPadding = 66,
		githubMaxChars = 40,
		clipboardMaxChars = 25,
		musicTitleMaxChars = 34,
		musicSubtitleMaxChars = 38,
		musicMinTextWidth = 140,
	},

	animation = {
		defaultDuration = 2.0,
		expandDuration = 10,
		collapseDuration = 10,
		contentSettleDelay = 0.2,
		shortEventDuration = 0.8,
		clipboardDuration = 1.2,
		warningDuration = 3.0,
		longWarningDuration = 4.0,
		musicUpdateDebounceSeconds = 0.15,
		meterFadeDelay = 0.8,
		meterFadeDuration = 15,
		meterShrinkDelay = 0.1,
		meterShrinkDuration = 5,
		meterCleanupDelay = 0.4,
		meterFlashDuration = 10,
	},

	meter = {
		iconYOffset = 22,
		barYOffset = 20,
		barItemYOffset = 1,
		paddingLeft = 10,
		percentMax = 100,
		roundingBias = 0.5,
	},

	music = {
		artworkSlotWidth = 92,
		compactSlotWidth = 44,
		artworkScale = 0.15,
		artworkYOffset = 14,
		slotPaddingLeft = 18,
		slotPaddingRight = 8,
		slotYOffset = 10,
		titleYOffset = 4,
		subtitleYOffset = 20,
		artworkBackgroundCornerRadius = 14,
		artworkCornerRadius = 12,
		artworkPadding = 6,
		compactBadgeHeight = 32,
		compactBadgeCornerRadius = 16,
		maxArtworkRetryAttempts = 4,
		artworkRetryDelaySeconds = 0.6,
	},

	appswitch = {
		iconScale = 0.5,
	},
}

return {
	main = {
		display = "main",
		font = "SF Pro",
	},

	logging = {
		-- Supported levels: debug, info, warn, error
		level = "info",
		flushSeconds = 1.0,
		maxBufferSize = 80,
	},

	enabled = {
		music = true,
		appswitch = true,
		notification = true,
		volume = true,
		brightness = true,
		wifi = true,
		power = true,
		cpu_panic = true,
		clipboard = true,
		privacy = true,
		github = true,
	},

	notch = {
		defaultHeight = 44,
		-- This is half-width in margin logic; effective island width is 2x this.
		defaultWidth = 104,
		cornerRadius = 10,
		contentYOffset = -20,
		monitorHorizontalResolution = "auto",
	},

	animation = {
		squishAmount = 6,
	},

	layout = layout,

	islands = {
		appswitch = {
			maxExpandWidth = 155,
			expandHeight = 76,
			cornerRadius = 22,
			iconSize = 0.4,
			repeatCooldownSeconds = 2,
		},
		volume = {
			maxExpandWidth = 145,
			expandHeight = 65,
			cornerRadius = 12,
		},
		brightness = {
			maxExpandWidth = 145,
			expandHeight = 65,
			cornerRadius = 12,
		},
		music = {
			source = "Music",
			info = {
				maxExpandWidth = 205,
				expandHeight = 100,
				cornerRadius = 19,
			},
			idleExpandWidth = 150,
			resume = {
				maxExpandWidth = 155,
				expandHeight = 76,
				cornerRadius = 22,
			},
		},
		wifi = {
			maxExpandWidth = 170,
			expandHeight = 76,
			cornerRadius = 22,
		},
		power = {
			maxExpandWidth = 160,
			expandHeight = 76,
			cornerRadius = 22,
			pollInterval = 300,
		},
		cpu_panic = {
			maxExpandWidth = 190,
			expandHeight = 85,
			cornerRadius = 15,
			pollInterval = 30,
			threshold = 90,
		},
		clipboard = {
			maxExpandWidth = 185,
			expandHeight = 85,
			cornerRadius = 15,
			pollInterval = 20,
			maxPreviewLength = 120,
		},
		privacy = {
			pollInterval = 60,
			yOffset = 0,
		},
		github = {
			minExpandWidth = 150,
			maxExpandWidth = 190,
			expandHeight = 95,
			cornerRadius = 32,
		},
		notification = {
			maxExpandWidth = 190,
			expandHeight = 90,
			cornerRadius = 42,
			maxAllowedBody = 250,
		},
	},

	colors = {
		white = 0xffffffff,
		black = 0xff000000,
		transparent = 0x00000000,
		iconHidden = 0xff000000,
		alertRed = 0xffff3333,
		privacyCamera = 0xff33ff33,
		privacyMicrophone = 0xffff9933,
		musicSecondary = 0xffb8b8b8,
		musicBadge = 0x22ffffff,
	},

	icons = {
		appswitch = {
			fallback = "􀑪",
		},
		clipboard = {
			copied = "􀉂",
		},
		cpu = {
			panic = "􀇿",
		},
		github = {
			notification = "􀋚",
		},
		privacy = {
			camera = "􀌞",
			microphone = "􀊰",
		},
		volume = {
			max = "􀊩",
			medium = "􀊧",
			low = "􀊥",
			muted = "􀊡",
		},
		brightness = {
			low = "􀆫",
			high = "􀆭",
		},
		wifi = {
			connected = "􀙇",
			disconnected = "􀙈",
		},
		power = {
			connectedAC = "􀢋",
			onBattery = "􀺸",
			lowBattery = "􀛨",
		},
	},
}
