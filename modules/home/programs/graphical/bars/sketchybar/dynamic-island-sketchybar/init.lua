#!/usr/bin/env lua

local function trim(value)
	if type(value) ~= "string" then
		return value
	end
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function asNumber(value, fallback)
	local parsed = tonumber(value)
	if parsed == nil then
		return fallback
	end
	return parsed
end

local function asBool(value)
	if type(value) == "boolean" then
		return value
	end
	return asNumber(value, 0) == 1
end

local home = os.getenv("HOME") or ""
local barName = os.getenv("BAR_NAME") or "dynamic-island-sketchybar"
local dynamicIslandDir = home .. "/.config/dynamic-island-sketchybar"
local configPath = dynamicIslandDir .. "/config.lua"
local logPath = home .. "/Library/Logs/sketchybar/dynamic-island.out.log"
local errorLogPath = home .. "/Library/Logs/sketchybar/dynamic-island.err.log"

local function normalizeLogLevel(level)
	local value = trim(tostring(level or ""))
	if value == "" then
		return nil
	end
	value = string.lower(value)
	if value == "trace" then
		return "debug"
	end
	if value == "debug" or value == "info" or value == "warn" or value == "error" then
		return value
	end
	return nil
end

local function normalizePositiveNumber(value, fallback)
	local numeric = tonumber(value)
	if numeric == nil or numeric <= 0 then
		return fallback
	end
	return numeric
end

local function normalizePositiveInteger(value, fallback)
	local numeric = tonumber(value)
	if numeric == nil or numeric < 1 then
		return fallback
	end
	return math.floor(numeric)
end

local createLogger = dofile(dynamicIslandDir .. "/lua/helpers/logger.lua").create
local monitorHelpers = dofile(dynamicIslandDir .. "/lua/helpers/monitor.lua")
local logger = createLogger({
	level = normalizeLogLevel(os.getenv("DYNAMIC_ISLAND_LOG_LEVEL")) or "info",
	flush_seconds = normalizePositiveNumber(os.getenv("DYNAMIC_ISLAND_LOG_FLUSH_SECONDS"), 1.0),
	max_buffer_size = normalizePositiveInteger(os.getenv("DYNAMIC_ISLAND_LOG_MAX_BUFFER_SIZE"), 80),
})

local function appendLog(_path, message, level)
	logger.raw(level, message)
end

local function logDebug(message)
	appendLog(logPath, message, "debug")
end

local function logInfo(message)
	appendLog(logPath, message, "info")
end

local function logWarn(message)
	appendLog(logPath, message, "warn")
end

local function logError(message)
	appendLog(logPath, message, "error")
end

local function emitStructuredLog(level, moduleName, event, fields)
	local write = logger[level]
	if type(write) ~= "function" then
		return
	end
	write(moduleName, event, fields)
end

logInfo("[init] startup bar=" .. barName)

if Sbar ~= nil and Sbar.set_bar_name ~= nil then
	Sbar.set_bar_name(barName)
	logInfo("[init] set_bar_name applied")
else
	logWarn("[init] set_bar_name unavailable")
end

local okConfig, cfgOrErr = pcall(dofile, configPath)
if not okConfig then
	logError("[init] failed loading config.lua: " .. tostring(cfgOrErr))
	cfgOrErr = {}
end
if type(cfgOrErr) ~= "table" then
	logWarn("[init] config.lua did not return a table; using empty config")
	cfgOrErr = {}
end
local cfg = cfgOrErr

local configuredLogLevel = normalizeLogLevel((cfg.logging or {}).level)
local configuredFlushSeconds = normalizePositiveNumber((cfg.logging or {}).flushSeconds, 1.0)
local configuredMaxBufferSize = normalizePositiveInteger((cfg.logging or {}).maxBufferSize, 80)
local envLogLevel = normalizeLogLevel(os.getenv("DYNAMIC_ISLAND_LOG_LEVEL"))
local envFlushSeconds = normalizePositiveNumber(os.getenv("DYNAMIC_ISLAND_LOG_FLUSH_SECONDS"), configuredFlushSeconds)
local envMaxBufferSize =
	normalizePositiveInteger(os.getenv("DYNAMIC_ISLAND_LOG_MAX_BUFFER_SIZE"), configuredMaxBufferSize)

logger.set_runtime(configuredLogLevel or "info", configuredFlushSeconds, configuredMaxBufferSize)
logger.set_runtime(envLogLevel or configuredLogLevel or "info", envFlushSeconds, envMaxBufferSize)
local activeLogLevel = envLogLevel or configuredLogLevel or "info"
logInfo("[init] log level=" .. activeLogLevel)
logDebug("[init] stdout log path=" .. logPath .. " stderr log path=" .. errorLogPath)

local function getByPath(tbl, path)
	local current = tbl
	for part in string.gmatch(path, "[^.]+") do
		if type(current) ~= "table" then
			return nil
		end
		current = current[part]
	end
	return current
end

local function get(key, fallback)
	local value = getByPath(cfg, key)
	if value == nil or value == "" then
		return fallback
	end
	return value
end

local function configNumber(key, fallback)
	return asNumber(get(key, fallback), fallback)
end

local layout = {
	spacing = {
		none = configNumber("layout.spacing.none", 0),
		default = configNumber("layout.spacing.default", 3),
		tight = configNumber("layout.spacing.tight", 4),
		compact = configNumber("layout.spacing.compact", 5),
		regular = configNumber("layout.spacing.regular", 6),
		large = configNumber("layout.spacing.large", 10),
		content = configNumber("layout.spacing.content", 20),
	},
	dimensions = {
		emptyWidth = configNumber("layout.dimensions.emptyWidth", 0),
		meterBarHeight = configNumber("layout.dimensions.meterBarHeight", 2),
		meterBarInset = configNumber("layout.dimensions.meterBarInset", 20),
	},
	fontSizes = {
		defaultIcon = configNumber("layout.fontSizes.defaultIcon", 14.0),
		defaultLabel = configNumber("layout.fontSizes.defaultLabel", 13.0),
		meterIcon = configNumber("layout.fontSizes.meterIcon", 14.0),
		musicTitle = configNumber("layout.fontSizes.musicTitle", 16.0),
		musicSubtitle = configNumber("layout.fontSizes.musicSubtitle", 12.0),
		musicCompactIcon = configNumber("layout.fontSizes.musicCompactIcon", 18.0),
		privacyIcon = configNumber("layout.fontSizes.privacyIcon", 10.0),
	},
	text = {
		defaultCharWidth = configNumber("layout.text.defaultCharWidth", 7),
		defaultHorizontalPadding = configNumber("layout.text.defaultHorizontalPadding", 44),
		appswitchHorizontalPadding = configNumber("layout.text.appswitchHorizontalPadding", 84),
		wifiHorizontalPadding = configNumber("layout.text.wifiHorizontalPadding", 34),
		powerHorizontalPadding = configNumber("layout.text.powerHorizontalPadding", 36),
		alertHorizontalPadding = configNumber("layout.text.alertHorizontalPadding", 40),
		githubCharWidth = configNumber("layout.text.githubCharWidth", 3.8),
		githubHorizontalPadding = configNumber("layout.text.githubHorizontalPadding", 66),
		githubMaxChars = configNumber("layout.text.githubMaxChars", 40),
		clipboardMaxChars = configNumber("layout.text.clipboardMaxChars", 25),
		musicTitleMaxChars = configNumber("layout.text.musicTitleMaxChars", 34),
		musicSubtitleMaxChars = configNumber("layout.text.musicSubtitleMaxChars", 38),
		musicMinTextWidth = configNumber("layout.text.musicMinTextWidth", 140),
	},
	animation = {
		defaultDuration = configNumber("layout.animation.defaultDuration", 2.0),
		expandDuration = configNumber("layout.animation.expandDuration", 10),
		collapseDuration = configNumber("layout.animation.collapseDuration", 10),
		contentSettleDelay = configNumber("layout.animation.contentSettleDelay", 0.2),
		shortEventDuration = configNumber("layout.animation.shortEventDuration", 0.8),
		clipboardDuration = configNumber("layout.animation.clipboardDuration", 1.2),
		warningDuration = configNumber("layout.animation.warningDuration", 3.0),
		longWarningDuration = configNumber("layout.animation.longWarningDuration", 4.0),
		musicUpdateDebounceSeconds = configNumber("layout.animation.musicUpdateDebounceSeconds", 0.15),
		meterFadeDelay = configNumber("layout.animation.meterFadeDelay", 0.8),
		meterFadeDuration = configNumber("layout.animation.meterFadeDuration", 15),
		meterShrinkDelay = configNumber("layout.animation.meterShrinkDelay", 0.1),
		meterShrinkDuration = configNumber("layout.animation.meterShrinkDuration", 5),
		meterCleanupDelay = configNumber("layout.animation.meterCleanupDelay", 0.4),
		meterFlashDuration = configNumber("layout.animation.meterFlashDuration", 10),
	},
	meter = {
		iconYOffset = configNumber("layout.meter.iconYOffset", 22),
		barYOffset = configNumber("layout.meter.barYOffset", 20),
		barItemYOffset = configNumber("layout.meter.barItemYOffset", 1),
		paddingLeft = configNumber("layout.meter.paddingLeft", 10),
		percentMax = configNumber("layout.meter.percentMax", 100),
		roundingBias = configNumber("layout.meter.roundingBias", 0.5),
	},
	music = {
		artworkSlotWidth = configNumber("layout.music.artworkSlotWidth", 92),
		compactSlotWidth = configNumber("layout.music.compactSlotWidth", 44),
		artworkScale = configNumber("layout.music.artworkScale", 0.15),
		artworkYOffset = configNumber("layout.music.artworkYOffset", 14),
		slotPaddingLeft = configNumber("layout.music.slotPaddingLeft", 18),
		slotPaddingRight = configNumber("layout.music.slotPaddingRight", 8),
		slotYOffset = configNumber("layout.music.slotYOffset", 10),
		titleYOffset = configNumber("layout.music.titleYOffset", 4),
		subtitleYOffset = configNumber("layout.music.subtitleYOffset", 20),
		artworkBackgroundCornerRadius = configNumber("layout.music.artworkBackgroundCornerRadius", 14),
		artworkCornerRadius = configNumber("layout.music.artworkCornerRadius", 12),
		artworkPadding = configNumber("layout.music.artworkPadding", 6),
		compactBadgeHeight = configNumber("layout.music.compactBadgeHeight", 32),
		compactBadgeCornerRadius = configNumber("layout.music.compactBadgeCornerRadius", 16),
		maxArtworkRetryAttempts = configNumber("layout.music.maxArtworkRetryAttempts", 4),
		artworkRetryDelaySeconds = configNumber("layout.music.artworkRetryDelaySeconds", 0.6),
	},
	appswitch = {
		iconScale = configNumber("layout.appswitch.iconScale", 0.5),
	},
}

local function delay(seconds, callback)
	if type(callback) ~= "function" then
		return
	end

	local duration = tonumber(seconds) or 0
	if duration <= 0 then
		callback()
		return
	end

	Sbar.delay(duration, callback)
end

local function fileExists(path)
	local handle = io.open(path, "r")
	if handle == nil then
		return false
	end

	handle:close()
	return true
end

local function subscribeItem(itemName, events)
	local eventList = events
	if type(eventList) == "string" then
		eventList = { eventList }
	end

	for _, eventName in ipairs(eventList) do
		Sbar.exec(barName .. " --subscribe " .. itemName .. " " .. eventName)
		logDebug("[init] subscribe " .. itemName .. " -> " .. eventName)
	end
end

local padding = layout.spacing.default
local defaultHeight = configNumber("notch.defaultHeight", 44)
local defaultWidth = configNumber("notch.defaultWidth", 100)
local cornerRadius = configNumber("notch.cornerRadius", 10)
local monitorResolution = monitorHelpers.resolveMonitorResolution({
	get = get,
	barName = barName,
	query = Sbar.query,
	logInfo = logInfo,
	logWarn = logWarn,
})
local calculateMargin = monitorHelpers.calculateMargin(monitorResolution)
local calculateIslandWidth = monitorHelpers.calculateIslandWidth(monitorResolution)
local calculateVisibleMargin = monitorHelpers.calculateVisibleMargin(monitorResolution)
local barColor = get("colors.black", "0xff000000")
local display = get("main.display", "main")
local fontFamily = get("main.font", "SF Pro")
local colorWhite = get("colors.white", "0xffffffff")
local colorTransparent = get("colors.transparent", "0x00000000")
local squishAmount = configNumber("animation.squishAmount", 6)
local contentYOffset = configNumber("notch.contentYOffset", -20)

logInfo("[init] monitor width final value: " .. tostring(monitorResolution))

local margin = calculateMargin(defaultWidth) or 0

local function clamp(value, minimum, maximum)
	if value < minimum then
		return minimum
	end
	if value > maximum then
		return maximum
	end
	return value
end

local function layoutForText(text, options)
	options = options or {}
	local charWidth = asNumber(options.charWidth, layout.text.defaultCharWidth)
	local horizontalPadding = asNumber(options.horizontalPadding, layout.text.defaultHorizontalPadding)
	local minHalfWidth = asNumber(options.minHalfWidth, defaultWidth)
	local maxHalfWidth = asNumber(options.maxHalfWidth, minHalfWidth)
	local textLength = string.len(text or "")
	local contentWidth = math.ceil(textLength * charWidth + horizontalPadding)
	local halfWidth = clamp(math.ceil(contentWidth / 2), minHalfWidth, maxHalfWidth)

	return {
		halfWidth = halfWidth,
		width = halfWidth * 2,
		margin = calculateMargin(halfWidth),
	}
end

Sbar.bar({
	height = defaultHeight,
	color = barColor,
	shadow = false,
	position = "top",
	sticky = false,
	topmost = true,
	padding_left = layout.spacing.none,
	padding_right = layout.spacing.none,
	corner_radius = cornerRadius,
	y_offset = -cornerRadius,
	margin = margin,
	notch_width = layout.dimensions.emptyWidth,
	display = display,
})

Sbar.default({
	updates = "when_shown",
	icon = {
		font = {
			family = fontFamily,
			style = "Bold",
			size = layout.fontSizes.defaultIcon,
		},
		color = colorWhite,
		padding_left = padding,
		padding_right = padding,
	},
	label = {
		font = {
			family = fontFamily,
			style = "Semibold",
			size = layout.fontSizes.defaultLabel,
		},
		color = colorWhite,
		padding_left = padding,
		padding_right = padding,
	},
	background = {
		padding_right = padding,
		padding_left = padding,
	},
})

Sbar.add("item", "island", {
	position = "center",
	drawing = true,
	width = layout.dimensions.emptyWidth,
})
logDebug("[init] island item created")

local islandRegistry = {}
local islandState = {
	persistentOwner = nil,
	persistentRestore = nil,
	persistentHide = nil,
	isSleeping = false,
}

local systemWatcher = Sbar.add("item", "island_system_watcher", {
	drawing = false,
})
systemWatcher:subscribe("system_will_sleep", function()
	logDebug("[init] system_will_sleep received")
	islandState.isSleeping = true
end)
systemWatcher:subscribe("system_woke", function()
	logDebug("[init] system_woke received")
	islandState.isSleeping = false
end)

local islandAnimationToken = 0
local activeIslandLifecycle = nil

local function interruptActiveIsland()
	local lifecycle = activeIslandLifecycle
	if lifecycle == nil then
		return false
	end

	activeIslandLifecycle = nil

	if lifecycle.hidden ~= true and type(lifecycle.onHideContent) == "function" then
		lifecycle.onHideContent(true)
	end
	if type(lifecycle.onCleanup) == "function" then
		lifecycle.onCleanup(true)
	end

	return true
end

local function animateIsland(options)
	interruptActiveIsland()
	islandAnimationToken = islandAnimationToken + 1
	local current = islandAnimationToken
	local privacySuppressed = false
	if islandRegistry.setPrivacySuppressed ~= nil and type(islandRegistry.setPrivacySuppressed) == "function" then
		islandRegistry.setPrivacySuppressed(true)
		privacySuppressed = true
	end

	local function restorePrivacy()
		if not privacySuppressed then
			return
		end
		privacySuppressed = false
		islandRegistry.setPrivacySuppressed(false)
	end

	activeIslandLifecycle = {
		token = current,
		hidden = false,
		onHideContent = options.onHideContent,
		onCleanup = function(interrupted)
			if type(options.onCleanup) == "function" then
				options.onCleanup(interrupted)
			end
			restorePrivacy()
		end,
	}

	Sbar.animate("tanh", layout.animation.expandDuration, function()
		if options.margin and options.cornerRadius and options.height then
			if options.maxExpandHeight then
				Sbar.bar({
					margin = options.margin,
					corner_radius = options.cornerRadius,
					height = options.maxExpandHeight,
				})
				Sbar.bar({
					height = options.height,
				})
			else
				Sbar.bar({
					margin = options.margin,
					corner_radius = options.cornerRadius,
					height = options.height,
				})
			end
		end

		if type(options.onExpand) == "function" then
			options.onExpand()
		end
	end)

	delay(options.duration or layout.animation.defaultDuration, function()
		if current ~= islandAnimationToken then
			return
		end

		Sbar.animate("tanh", layout.animation.collapseDuration, function()
			if activeIslandLifecycle ~= nil and activeIslandLifecycle.token == current then
				activeIslandLifecycle.hidden = true
			end
			if type(options.onHideContent) == "function" then
				options.onHideContent()
			end
		end)

		delay(layout.animation.contentSettleDelay, function()
			if current ~= islandAnimationToken then
				return
			end

			if activeIslandLifecycle ~= nil and activeIslandLifecycle.token == current then
				activeIslandLifecycle = nil
			end

			if type(options.onCleanup) == "function" then
				options.onCleanup()
			end
			restorePrivacy()

			if not options.preventCollapse then
				Sbar.animate("tanh", layout.animation.collapseDuration, function()
					Sbar.bar({
						height = defaultHeight,
						corner_radius = cornerRadius,
						margin = margin,
					})
				end)
			end
		end)
	end)

	return current
end

local function setPersistentIsland(owner, handlers)
	if type(owner) ~= "string" or owner == "" then
		return
	end
	if type(handlers) ~= "table" then
		return
	end
	if type(handlers.restore) ~= "function" or type(handlers.hide) ~= "function" then
		return
	end

	islandState.persistentOwner = owner
	islandState.persistentRestore = handlers.restore
	islandState.persistentHide = handlers.hide
	logDebug("[init] persistent island owner=" .. owner)
end

local function clearPersistentIsland(owner)
	if owner ~= nil and islandState.persistentOwner ~= owner then
		return
	end

	islandState.persistentOwner = nil
	islandState.persistentRestore = nil
	islandState.persistentHide = nil
	logDebug("[init] persistent island cleared")
end

local function hidePersistentIsland(excludedOwner)
	if islandState.persistentOwner == nil or islandState.persistentOwner == excludedOwner then
		return false
	end
	if type(islandState.persistentHide) ~= "function" then
		return false
	end

	islandState.persistentHide()
	return true
end

local function restorePersistentIsland(excludedOwner)
	if islandState.persistentOwner == nil or islandState.persistentOwner == excludedOwner then
		return false
	end
	if type(islandState.persistentRestore) ~= "function" then
		return false
	end

	islandState.persistentRestore()
	return true
end

local function loadIslandModule(moduleName)
	local path = dynamicIslandDir .. "/lua/islands/" .. moduleName .. ".lua"
	local ok, islandModule = pcall(dofile, path)
	if not ok then
		logError("[init] failed loading module " .. path .. ": " .. tostring(islandModule))
		return nil
	end

	if type(islandModule) ~= "function" then
		logError("[init] invalid module (expected function): " .. path)
		return nil
	end

	logDebug("[init] loaded module " .. path)
	return islandModule
end

local baseCtx = {
	Sbar = Sbar,
	registry = islandRegistry,
	appendLog = appendLog,
	logger = logger,
	logDebug = logDebug,
	logInfo = logInfo,
	logWarn = logWarn,
	logError = logError,
	logPath = logPath,
	errorLogPath = errorLogPath,
	get = get,
	asNumber = asNumber,
	asBool = asBool,
	trim = trim,
	delay = delay,
	fileExists = fileExists,
	subscribeItem = subscribeItem,
	setPersistentIsland = setPersistentIsland,
	clearPersistentIsland = clearPersistentIsland,
	hidePersistentIsland = hidePersistentIsland,
	restorePersistentIsland = restorePersistentIsland,
	interruptActiveIsland = interruptActiveIsland,
	barName = barName,
	fontFamily = fontFamily,
	colorWhite = colorWhite,
	colorTransparent = colorTransparent,
	monitorResolution = monitorResolution,
	calculateMargin = calculateMargin,
	calculateVisibleMargin = calculateVisibleMargin,
	calculateIslandWidth = calculateIslandWidth,
	layoutForText = layoutForText,
	layout = layout,
	squishAmount = squishAmount,
	contentYOffset = contentYOffset,
	defaultHeight = defaultHeight,
	defaultWidth = defaultWidth,
	cornerRadius = cornerRadius,
	margin = margin,
	islandState = islandState,
	animateIsland = animateIsland,
}
-- TODO: figure out disable macos OSD
-- if asBool(get("enabled.volume", true)) then
-- 	local mod = loadIslandModule("volume")
-- 	if mod ~= nil then
-- 		mod(baseCtx)
-- 	end
-- end
--
-- TODO: figure out disable macos OSD
-- if asBool(get("enabled.brightness", true)) then
-- 	local mod = loadIslandModule("brightness")
-- 	if mod ~= nil then
-- 		mod(baseCtx)
-- 	end
-- end

if asBool(get("enabled.appswitch", true)) then
	local mod = loadIslandModule("appswitch")
	if mod ~= nil then
		mod(baseCtx)
	end
end

if asBool(get("enabled.wifi", true)) then
	local mod = loadIslandModule("wifi")
	if mod ~= nil then
		mod(baseCtx)
	end
end

if asBool(get("enabled.power", true)) then
	local mod = loadIslandModule("power")
	if mod ~= nil then
		mod(baseCtx)
	end
end

if asBool(get("enabled.music", true)) then
	local mod = loadIslandModule("music")
	if mod ~= nil then
		mod(baseCtx)
	end
end

if asBool(get("enabled.cpu_panic", true)) then
	local mod = loadIslandModule("cpu_panic")
	if mod ~= nil then
		mod(baseCtx)
	end
end

if asBool(get("enabled.clipboard", true)) then
	local mod = loadIslandModule("clipboard")
	if mod ~= nil then
		mod(baseCtx)
	end
end

if asBool(get("enabled.privacy", true)) then
	local mod = loadIslandModule("privacy")
	if mod ~= nil then
		mod(baseCtx)
	end
end

if asBool(get("enabled.github", true)) then
	local mod = loadIslandModule("github")
	if mod ~= nil then
		mod(baseCtx)
	end
end

if asBool(get("enabled.notification", true)) then
	logInfo("[notification][lua] not migrated yet; currently disabled in lua-only runtime")
end
