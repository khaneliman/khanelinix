return function(ctx)
	local episodes = {}
	local nextNoticeAt = 0
	local lastSampleAt = nil
	local generation = 0
	local inFlight = false

	local maxExpandWidth = ctx.expandedHalfWidth("islands.cpu_panic.maxExpandWidth", 190)
	local expandHeight = ctx.asNumber(ctx.get("islands.cpu_panic.expandHeight", "85"), 85)
	local cornerRad = ctx.asNumber(ctx.get("islands.cpu_panic.cornerRadius", "15"), 15)
	local pollInterval = math.max(1, ctx.asNumber(ctx.get("islands.cpu_panic.pollInterval", "30"), 30))
	local threshold = ctx.asNumber(ctx.get("islands.cpu_panic.threshold", "90"), 90)
	local sustainedSeconds =
		math.max(pollInterval, ctx.asNumber(ctx.get("islands.cpu_panic.sustainedSeconds", 120), 120))
	local cooldownSeconds = math.max(pollInterval, ctx.asNumber(ctx.get("islands.cpu_panic.cooldownSeconds", 900), 900))

	local function addText(name, offset, size)
		return ctx.Sbar.add("item", name, {
			position = "left",
			drawing = false,
			padding_left = 0,
			padding_right = 0,
			icon = { drawing = false },
			label = {
				align = "center",
				color = ctx.colorTransparent,
				y_offset = ctx.contentYOffset + offset,
				padding_left = 0,
				padding_right = 0,
				font = { family = ctx.fontFamily, size = size },
			},
			width = ctx.layout.dimensions.emptyWidth,
		})
	end
	local textItem = addText("island.cpu_panic_text", 10, ctx.layout.fontSizes.defaultLabel)
	local detailItem = addText("island.cpu_panic_detail", -10, ctx.layout.fontSizes.musicSubtitle)
	local textItems = { textItem, detailItem }

	local listener = ctx.Sbar.add("item", "cpuPanicListener", {
		position = "center",
		width = ctx.layout.dimensions.emptyWidth,
		update_freq = pollInterval,
	})

	local function showNotice(process, elapsed)
		local appName = process.comm:match("([^/]+)$") or process.comm
		local displayText = ctx.get("icons.cpu.panic", "􀇿") .. " CPU busy: " .. process.cpu .. "% | " .. appName
		local duration = math.floor(elapsed / 60) .. "m+"
		if elapsed < 60 then
			duration = math.floor(elapsed) .. "s+"
		end
		local detail = "PID " .. process.pid .. " | high " .. duration .. " | Click: Activity Monitor"
		local layout = ctx.layoutForText(#displayText > #detail and displayText or detail, {
			maxHalfWidth = maxExpandWidth,
			horizontalPadding = ctx.layout.text.alertHorizontalPadding,
		})

		ctx.hidePersistentIsland("cpu_panic")
		textItem:set({
			drawing = true,
			label = {
				string = displayText,
				width = layout.width,
				max_chars = math.max(
					1,
					math.floor(
						(layout.width - ctx.layout.text.alertHorizontalPadding) / ctx.layout.text.defaultCharWidth
					)
				),
			},
		})
		detailItem:set({ drawing = true, label = { string = detail, width = layout.width } })
		ctx.logInfo(
			"[cpu_panic][lua] CPU busy: "
				.. process.comm
				.. " (PID "
				.. process.pid
				.. ", started "
				.. process.started
				.. ", "
				.. process.cpu
				.. "%, high readings for "
				.. elapsed
				.. "s). 100% is about one logical core; inspect Activity Monitor > CPU if unexpected."
		)

		ctx.animateIsland({
			owner = "cpu_panic",
			margin = layout.margin,
			cornerRadius = cornerRad,
			height = expandHeight,
			duration = ctx.layout.animation.longWarningDuration,
			onExpand = function()
				for _, item in ipairs(textItems) do
					item:set({ label = { color = ctx.colorWhite } })
				end
			end,
			onHideContent = function()
				for _, item in ipairs(textItems) do
					item:set({ label = { color = ctx.colorTransparent } })
				end
			end,
			onCleanup = function()
				for _, item in ipairs(textItems) do
					item:set({ drawing = false })
				end
			end,
		})
	end

	for _, item in ipairs(textItems) do
		item:subscribe("mouse.clicked", function()
			ctx.Sbar.exec("/usr/bin/open -b com.apple.ActivityMonitor")
		end)
	end

	listener:subscribe("system_will_sleep", function()
		generation = generation + 1
		episodes = {}
		lastSampleAt = nil
	end)

	listener:subscribe("routine", function()
		if ctx.islandState.isSleeping or inFlight then
			return
		end
		inFlight = true
		local requestedAt = os.time()
		local requestedGeneration = generation

		-- Keep all high-CPU processes, not only the leader, so changing rank does not reset evidence.
		ctx.Sbar.exec("LC_ALL=C ps -ww -Ao pid=,%cpu=,lstart=,comm=", function(result, exitCode)
			inFlight = false
			local now = os.time()
			if requestedGeneration ~= generation or ctx.islandState.isSleeping then
				return
			end
			if exitCode ~= 0 or not result or result == "" or now - requestedAt > pollInterval * 2 then
				episodes = {}
				lastSampleAt = nil
				return
			end
			-- Sleep, delayed polling, and clock changes must not count as observed high usage.
			if lastSampleAt and (now < lastSampleAt or now - lastSampleAt > pollInterval * 2) then
				episodes = {}
			end
			lastSampleAt = now

			local current = {}
			local candidate = nil
			for line in result:gmatch("[^\r\n]+") do
				local pid, cpu, started, comm =
					line:match("^%s*(%d+)%s+(%d+%.?%d*)%s+(%a+%s+%a+%s+%d+%s+%d%d:%d%d:%d%d%s+%d%d%d%d)%s+(.+)$")
				local cpuValue = tonumber(cpu)
				if cpuValue and cpuValue > threshold and not comm:lower():find("sketchybar", 1, true) then
					-- lstart includes year and seconds; PID alone can belong to a restarted process.
					local identity = pid .. ":" .. started .. ":" .. comm
					local episode = episodes[identity] or { since = now, alerted = false }
					current[identity] = episode
					if
						not episode.alerted
						and now - episode.since >= sustainedSeconds
						and (not candidate or cpuValue > candidate.cpuValue)
					then
						candidate = {
							pid = pid,
							cpu = cpu,
							cpuValue = cpuValue,
							started = started,
							comm = comm,
							episode = episode,
						}
					end
				end
			end
			-- Below-threshold readings and missing processes end their episodes and prune state.
			episodes = current
			if candidate and now >= nextNoticeAt then
				candidate.episode.alerted = true
				nextNoticeAt = now + cooldownSeconds
				showNotice(candidate, now - candidate.episode.since)
			end
		end)
	end)

	ctx.registry.cpuPanicTextItem = textItem
	ctx.registry.cpuPanicListener = listener
	ctx.subscribeItem("cpuPanicListener", "routine")
	ctx.subscribeItem("cpuPanicListener", "system_will_sleep")
	ctx.logDebug("[cpu_panic][lua] module loaded")
end
