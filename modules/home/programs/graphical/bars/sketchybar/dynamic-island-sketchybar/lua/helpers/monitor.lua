#!/usr/bin/env lua

local function clamp(value, minimum, maximum)
	if value == nil then
		return minimum
	end
	if value < minimum then
		return minimum
	end
	if value > maximum then
		return maximum
	end
	return value
end

local function asPositiveInteger(value)
	local parsed = tonumber(value)
	if parsed == nil or parsed < 1 then
		return nil
	end
	return math.floor(parsed)
end

local function lookupQueryWidth(queryResult)
	if type(queryResult) ~= "table" then
		return nil
	end

	local paths = {
		{ "frame", "w" },
		{ "frame", "width" },
		{ "display", "frame", "w" },
		{ "display", "frame", "width" },
		{ "display", "width" },
		{ "bar", "frame", "w" },
		{ "bar", "frame", "width" },
		{ "geometry", "w" },
		{ "geometry", "width" },
		{ "bounds", "w" },
		{ "bounds", "width" },
		{ "width" },
	}

	for _, path in ipairs(paths) do
		local current = queryResult
		for _, key in ipairs(path) do
			if type(current) ~= "table" then
				current = nil
				break
			end
			current = current[key]
		end

		local value = asPositiveInteger(current)
		if value ~= nil then
			return value
		end
	end

	return nil
end

local function detectMonitorWidthFromBar(query, barName)
	if type(query) ~= "function" then
		return nil
	end

	local queryTargets = { "bar", "default", barName }
	for _, target in ipairs(queryTargets) do
		local ok, queryResult = pcall(function()
			return query(target)
		end)
		if ok then
			local width = lookupQueryWidth(queryResult)
			if width ~= nil then
				return width
			end
		end
	end

	return nil
end

local function detectMonitorWidthFromSystemProfiler()
	local handle = io.popen("/usr/sbin/system_profiler SPDisplaysDataType 2>/dev/null")
	if handle == nil then
		return nil
	end

	local output = handle:read("*a")
	pcall(handle.close, handle)
	if output == nil or output == "" then
		return nil
	end

	local displayBlocks = {}
	local currentBlock = nil

	for line in output:gmatch("[^\r\n]+") do
		if line:match("^%s%s%s%s%s%s%s%s[%S].-:%s*$") then
			if currentBlock ~= nil and #currentBlock > 0 then
				table.insert(displayBlocks, table.concat(currentBlock, "\n"))
			end
			currentBlock = { line }
		elseif currentBlock ~= nil then
			table.insert(currentBlock, line)
		end
	end

	if currentBlock ~= nil and #currentBlock > 0 then
		table.insert(displayBlocks, table.concat(currentBlock, "\n"))
	end

	local function resolveWidthFromBlock(block)
		if type(block) ~= "string" or block == "" then
			return nil
		end

		local uiWidthText = block:match("UI Looks like:%s*(%d+)%s*[xX]%s*%d+")
		if uiWidthText ~= nil then
			return asPositiveInteger(uiWidthText)
		end

		local resolutionWidthText, resolutionDescriptor = block:match(
			"Resolution:%s*(%d+)%s*[xX]%s*%d+%s*([^\n]*)"
		)
		local resolutionWidth = asPositiveInteger(resolutionWidthText)
		if resolutionWidth == nil then
			return nil
		end

		local descriptor = ""
		if type(resolutionDescriptor) == "string" then
			descriptor = string.lower(resolutionDescriptor)
		end

		if descriptor:find("retina", 1, true) then
			return asPositiveInteger(resolutionWidth / 2)
		end

		return resolutionWidth
	end

	for _, block in ipairs(displayBlocks) do
		if block:find("Main Display:%s*Yes") ~= nil then
			return resolveWidthFromBlock(block)
		end
	end

	if #displayBlocks == 1 then
		return resolveWidthFromBlock(displayBlocks[1])
	end

	return nil
end

local function resolveMonitorResolution(config)
	local get = config.get
	local barName = config.barName
	local query = config.query
	local logInfo = config.logInfo or function(...) end
	local logWarn = config.logWarn or function(...) end

	local configuredValue = get("notch.monitorHorizontalResolution", "auto")
	local configured = asPositiveInteger(configuredValue)
	if type(configuredValue) == "string" then
		if configuredValue == "" or string.lower(configuredValue) == "auto" then
			configured = nil
		else
			configured = configured or nil
		end
	end

	if configured ~= nil then
		logInfo("[monitor] width configured explicitly: " .. tostring(configured))
		return configured
	end

	local detectedWidth = detectMonitorWidthFromBar(query, barName)
	if detectedWidth ~= nil then
		logInfo("[monitor] width resolved from Sbar query: " .. tostring(detectedWidth))
		return detectedWidth
	end

	detectedWidth = detectMonitorWidthFromSystemProfiler()
	if detectedWidth ~= nil then
		logInfo("[monitor] width resolved from system_profiler: " .. tostring(detectedWidth))
		return detectedWidth
	end

	logWarn("[monitor] width detection failed; using fallback 1728")
	return 1728
end

local function makeMarginCalculator(monitorResolution)
	local safeResolution = tonumber(monitorResolution) or 0
	if safeResolution < 0 then
		safeResolution = 0
	end

	return function(width)
		if type(width) ~= "number" or width < 1 then
			return 0
		end
		if safeResolution <= 0 then
			return 0
		end

		local maxHalf = math.floor(safeResolution / 2)
		local normalizedWidth = clamp(width, 1, maxHalf)
		return math.floor(safeResolution / 2 - normalizedWidth)
	end
end

return {
	calculateMargin = makeMarginCalculator,
	resolveMonitorResolution = resolveMonitorResolution,
}
