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
		defaultWidth = 100,
		cornerRadius = 10,
		monitorHorizontalResolution = 1728,
	},

	animation = {
		squishAmount = 6,
	},

	islands = {
		appswitch = {
			maxExpandWidth = 110,
			expandHeight = 56,
			cornerRadius = 15,
			iconSize = 0.4,
			repeatCooldownSeconds = 2,
		},
		volume = {
			maxExpandWidth = 130,
			expandHeight = 65,
			cornerRadius = 12,
		},
		brightness = {
			maxExpandWidth = 130,
			expandHeight = 65,
			cornerRadius = 12,
		},
		music = {
			source = "Music",
			info = {
				maxExpandWidth = 170,
				expandHeight = 100,
				cornerRadius = 19,
			},
			idleExpandWidth = 160,
			resume = {
				maxExpandWidth = 155,
				expandHeight = 56,
				cornerRadius = 15,
			},
		},
		wifi = {
			maxExpandWidth = 190,
			expandHeight = 56,
			cornerRadius = 15,
		},
		power = {
			maxExpandWidth = 190,
			expandHeight = 56,
			cornerRadius = 15,
			pollInterval = 300,
		},
		cpu_panic = {
			maxExpandWidth = 200,
			expandHeight = 85,
			cornerRadius = 15,
			pollInterval = 30,
			threshold = 90,
		},
		clipboard = {
			maxExpandWidth = 180,
			expandHeight = 85,
			cornerRadius = 15,
			pollInterval = 20,
			maxPreviewLength = 120,
		},
		privacy = {
			pollInterval = 60,
		},
		github = {
			maxExpandWidth = 220,
			expandHeight = 95,
			cornerRadius = 42,
		},
		notification = {
			maxExpandWidth = 180,
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
