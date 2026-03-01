#!/usr/bin/env lua

local function trim(value)
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function appendLog(_path, message)
	local line = os.date("%Y-%m-%d %H:%M:%S") .. " " .. message
	io.stdout:write(line, "\n")
	io.stdout:flush()
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
local debugLogPath = home .. "/Library/Logs/sketchybar/dynamic-island.out.log"

appendLog(debugLogPath, "[init] startup bar=" .. barName)

if Sbar ~= nil and Sbar.set_bar_name ~= nil then
	Sbar.set_bar_name(barName)
	appendLog(debugLogPath, "[init] set_bar_name applied")
else
	appendLog(debugLogPath, "[init] set_bar_name unavailable")
end

local okConfig, cfgOrErr = pcall(dofile, configPath)
if not okConfig then
	appendLog(debugLogPath, "[init] failed loading config.lua: " .. tostring(cfgOrErr))
	cfgOrErr = {}
end
if type(cfgOrErr) ~= "table" then
	appendLog(debugLogPath, "[init] config.lua did not return a table; using empty config")
	cfgOrErr = {}
end
local cfg = cfgOrErr

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

local function subscribeItem(itemName, events)
	local eventList = events
	if type(eventList) == "string" then
		eventList = { eventList }
	end

	for _, eventName in ipairs(eventList) do
		Sbar.exec(barName .. " --subscribe " .. itemName .. " " .. eventName)
		appendLog(debugLogPath, "[init] subscribe " .. itemName .. " -> " .. eventName)
	end
end

local padding = 3
local defaultHeight = asNumber(get("notch.defaultHeight", 44), 44)
local defaultWidth = asNumber(get("notch.defaultWidth", 100), 100)
local cornerRadius = asNumber(get("notch.cornerRadius", 10), 10)
local monitorResolution = asNumber(get("notch.monitorHorizontalResolution", 1728), 1728)
local barColor = get("colors.black", "0xff000000")
local display = get("main.display", "main")
local fontFamily = get("main.font", "SF Pro")
local colorWhite = get("colors.white", "0xffffffff")
local colorTransparent = get("colors.transparent", "0x00000000")
local squishAmount = asNumber(get("animation.squishAmount", 6), 6)

local margin = math.floor(monitorResolution / 2 - defaultWidth)

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
appendLog(debugLogPath, "[init] island item created")

local islandRegistry = {}

local function loadIslandModule(moduleName)
	local path = dynamicIslandDir .. "/lua/islands/" .. moduleName .. ".lua"
	local ok, islandModule = pcall(dofile, path)
	if not ok then
		appendLog(debugLogPath, "[init] failed loading module " .. path .. ": " .. tostring(islandModule))
		return nil
	end

	if type(islandModule) ~= "function" then
		appendLog(debugLogPath, "[init] invalid module (expected function): " .. path)
		return nil
	end

	appendLog(debugLogPath, "[init] loaded module " .. path)
	return islandModule
end

local baseCtx = {
	Sbar = Sbar,
	registry = islandRegistry,
	appendLog = appendLog,
	debugLogPath = debugLogPath,
	get = get,
	asNumber = asNumber,
	asBool = asBool,
	trim = trim,
	subscribeItem = subscribeItem,
	barName = barName,
	fontFamily = fontFamily,
	colorWhite = colorWhite,
	colorTransparent = colorTransparent,
	monitorResolution = monitorResolution,
	squishAmount = squishAmount,
	defaultHeight = defaultHeight,
	defaultWidth = defaultWidth,
	cornerRadius = cornerRadius,
	margin = margin,
}

if asBool(get("enabled.volume", true)) then
	local mod = loadIslandModule("volume")
	if mod ~= nil then
		mod(baseCtx)
	end
end

if asBool(get("enabled.brightness", true)) then
	local mod = loadIslandModule("brightness")
	if mod ~= nil then
		mod(baseCtx)
	end
end

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

if asBool(get("enabled.notification", true)) then
	appendLog(debugLogPath, "[notification][lua] not migrated yet; currently disabled in lua-only runtime")
end
