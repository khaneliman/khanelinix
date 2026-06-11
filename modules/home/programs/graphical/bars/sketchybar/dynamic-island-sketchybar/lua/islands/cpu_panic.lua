return function(ctx)
	local lastPanicApp = nil
	local inFlight = false

	local maxExpandWidth = ctx.expandedHalfWidth("islands.cpu_panic.maxExpandWidth", 190)
	local expandHeight = ctx.asNumber(ctx.get("islands.cpu_panic.expandHeight", "85"), 85)
	local cornerRad = ctx.asNumber(ctx.get("islands.cpu_panic.cornerRadius", "15"), 15)
	local pollInterval = ctx.asNumber(ctx.get("islands.cpu_panic.pollInterval", "30"), 30)
	local panicThreshold = ctx.asNumber(ctx.get("islands.cpu_panic.threshold", "90"), 90)

	local textItem = ctx.Sbar.add("item", "island.cpu_panic_text", {
		position = "center",
		drawing = false,
		label = {
			align = "center",
			color = ctx.colorTransparent,
			y_offset = ctx.contentYOffset,
		},
		width = ctx.layout.dimensions.emptyWidth,
	})

	local listener = ctx.Sbar.add("item", "cpuPanicListener", {
		position = "center",
		width = ctx.layout.dimensions.emptyWidth,
		update_freq = pollInterval,
	})

	local function showPanic(appName, cpuUsage)
		local displayText = ctx.get("icons.cpu.panic", "􀇿") .. " CPU Panic: " .. appName .. " (" .. cpuUsage .. "%)"
		local layout = ctx.layoutForText(displayText, {
			maxHalfWidth = maxExpandWidth,
			horizontalPadding = ctx.layout.text.alertHorizontalPadding,
		})

		textItem:set({
			drawing = true,
			width = layout.width,
			label = {
				string = displayText,
			},
		})

		ctx.animateIsland({
			owner = "cpu_panic",
			margin = layout.margin,
			cornerRadius = cornerRad,
			height = expandHeight,
			duration = ctx.layout.animation.longWarningDuration,
			onExpand = function()
				textItem:set({ label = { color = ctx.get("colors.alertRed", 0xffff3333) } })
			end,
			onHideContent = function()
				textItem:set({ label = { color = ctx.colorTransparent } })
			end,
			onCleanup = function()
				textItem:set({
					drawing = false,
					width = ctx.layout.dimensions.emptyWidth,
				})
			end,
		})
	end

	listener:subscribe("routine", function()
		if ctx.islandState.isSleeping then
			return
		end
		if inFlight then
			return
		end
		inFlight = true

		ctx.Sbar.exec(
			"ps -Ao %cpu,comm -r | awk 'BEGIN{IGNORECASE=1} $2 !~ /sketchybar/ && printed==0 {print; printed=1}'",
			function(result)
				inFlight = false
				if not result or result == "" then
					return
				end

				local cpu, comm = result:match("^%s*(%d+%.?%d*)%s+(.*)$")
				if cpu and comm then
					local cpuVal = tonumber(cpu)
					local appName = comm:match("([^/]+)$") or comm

					if cpuVal > panicThreshold then
						if lastPanicApp ~= appName then
							ctx.logWarn("[cpu_panic][lua] high cpu detected: " .. appName .. " (" .. cpu .. "%)")
							showPanic(appName, cpu)
							lastPanicApp = appName
						end
					else
						lastPanicApp = nil
					end
				end
			end
		)
	end)

	ctx.registry.cpuPanicTextItem = textItem
	ctx.registry.cpuPanicListener = listener
	ctx.subscribeItem("cpuPanicListener", "routine")
	ctx.logDebug("[cpu_panic][lua] module loaded")
end
