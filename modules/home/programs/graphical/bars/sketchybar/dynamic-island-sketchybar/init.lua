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
local envMaxBufferSize = normalizePositiveInteger(os.getenv("DYNAMIC_ISLAND_LOG_MAX_BUFFER_SIZE"), configuredMaxBufferSize)

logger.set_runtime(
	configuredLogLevel or "info",
	configuredFlushSeconds,
	configuredMaxBufferSize
)
logger.set_runtime(
	envLogLevel or configuredLogLevel or "info",
	envFlushSeconds,
	envMaxBufferSize
)
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

local padding = 3
local defaultHeight = asNumber(get("notch.defaultHeight", 44), 44)
local defaultWidth = asNumber(get("notch.defaultWidth", 100), 100)
local cornerRadius = asNumber(get("notch.cornerRadius", 10), 10)
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
local squishAmount = asNumber(get("animation.squishAmount", 6), 6)

logInfo("[init] monitor width final value: " .. tostring(monitorResolution))

local margin = calculateMargin(defaultWidth) or 0

Sbar.bar({
	height = defaultHeight,
	color = barColor,
	shadow = false,
	position = "top",
	sticky = false,
	topmost = true,
	padding_left = 0,
	padding_right = 0,
	corner_radius = cornerRadius,
	y_offset = -cornerRadius,
	margin = margin,
	notch_width = 0,
	display = display,
})

Sbar.default({
	updates = "when_shown",
	icon = {
		font = {
			family = fontFamily,
			style = "Bold",
			size = 14.0,
		},
		color = colorWhite,
		padding_left = padding,
		padding_right = padding,
	},
	label = {
		font = {
			family = fontFamily,
			style = "Semibold",
			size = 13.0,
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
	width = 0,
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

local function animateIsland(options)
	islandAnimationToken = islandAnimationToken + 1
	local current = islandAnimationToken

	Sbar.animate("tanh", 10, function()
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

	delay(options.duration or 2.0, function()
		if current ~= islandAnimationToken then
			return
		end

		Sbar.animate("tanh", 10, function()
			if type(options.onHideContent) == "function" then
				options.onHideContent()
			end
		end)

		delay(0.2, function()
			if current ~= islandAnimationToken then
				return
			end

			if type(options.onCleanup) == "function" then
				options.onCleanup()
			end

			if not options.preventCollapse then
				Sbar.animate("tanh", 10, function()
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
	barName = barName,
	fontFamily = fontFamily,
	colorWhite = colorWhite,
	colorTransparent = colorTransparent,
	monitorResolution = monitorResolution,
	calculateMargin = calculateMargin,
	calculateVisibleMargin = calculateVisibleMargin,
	calculateIslandWidth = calculateIslandWidth,
	squishAmount = squishAmount,
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
