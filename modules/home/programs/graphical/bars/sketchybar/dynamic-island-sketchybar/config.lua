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
		defaultWidth = 80,
		cornerRadius = 10,
		contentYOffset = -20,
		monitorHorizontalResolution = "auto",
	},

	animation = {
		squishAmount = 6,
	},

	islands = {
		appswitch = {
			maxExpandWidth = 100,
			expandHeight = 76,
			cornerRadius = 22,
			iconSize = 0.4,
			repeatCooldownSeconds = 2,
		},
		volume = {
			maxExpandWidth = 115,
			expandHeight = 65,
			cornerRadius = 12,
		},
		brightness = {
			maxExpandWidth = 115,
			expandHeight = 65,
			cornerRadius = 12,
		},
		music = {
			source = "Music",
			info = {
				maxExpandWidth = 150,
				expandHeight = 100,
				cornerRadius = 19,
			},
			idleExpandWidth = 140,
			resume = {
				maxExpandWidth = 125,
				expandHeight = 76,
				cornerRadius = 22,
			},
		},
		wifi = {
			maxExpandWidth = 135,
			expandHeight = 76,
			cornerRadius = 22,
		},
		power = {
			maxExpandWidth = 125,
			expandHeight = 76,
			cornerRadius = 22,
			pollInterval = 300,
		},
		cpu_panic = {
			maxExpandWidth = 170,
			expandHeight = 85,
			cornerRadius = 15,
			pollInterval = 30,
			threshold = 90,
		},
		clipboard = {
			maxExpandWidth = 160,
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
			minExpandWidth = 120,
			maxExpandWidth = 165,
			expandHeight = 95,
			cornerRadius = 32,
		},
		notification = {
			maxExpandWidth = 160,
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
	},

	icons = {
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
		},
	},
}
