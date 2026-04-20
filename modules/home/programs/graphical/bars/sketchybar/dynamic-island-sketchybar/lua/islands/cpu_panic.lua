return function(ctx)
	local token = 0
	local lastPanicApp = nil
	local inFlight = false

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.cpu_panic.maxExpandWidth", "200"), 200)
	local expandHeight = ctx.asNumber(ctx.get("islands.cpu_panic.expandHeight", "85"), 85)
	local cornerRad = ctx.asNumber(ctx.get("islands.cpu_panic.cornerRadius", "15"), 15)
	local expandMargin = ctx.calculateMargin(maxExpandWidth)
	local pollInterval = ctx.asNumber(ctx.get("islands.cpu_panic.pollInterval", "30"), 30)
	local panicThreshold = ctx.asNumber(ctx.get("islands.cpu_panic.threshold", "90"), 90)

	local textItem = ctx.Sbar.add("item", "island.cpu_panic_text", {
		position = "right",
		drawing = false,
		label = {
			color = ctx.colorTransparent,
			y_offset = -15, -- Pushing it below the notch
		},
		width = 0,
	})

	local listener = ctx.Sbar.add("item", "cpuPanicListener", {
		position = "center",
		width = 0,
		update_freq = pollInterval,
	})

	local function showPanic(appName, cpuUsage)
		textItem:set({
			drawing = true,
			label = {
				string = "􀇿 CPU Panic: " .. appName .. " (" .. cpuUsage .. "%)",
			},
		})

		ctx.animateIsland({
			margin = expandMargin,
			cornerRadius = cornerRad,
			height = expandHeight,
			duration = 4.0,
			onExpand = function()
				textItem:set({ label = { color = 0xffff3333 } }) -- Red color
			end,
			onHideContent = function()
				textItem:set({ label = { color = ctx.colorTransparent } })
			end,
			onCleanup = function()
				textItem:set({ drawing = false })
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
