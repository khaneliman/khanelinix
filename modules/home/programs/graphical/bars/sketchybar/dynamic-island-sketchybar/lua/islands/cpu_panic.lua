return function(ctx)
	local token = 0
	local lastPanicApp = nil
	local inFlight = false

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.cpu_panic.maxExpandWidth", "200"), 200)
	local expandHeight = ctx.asNumber(ctx.get("islands.cpu_panic.expandHeight", "85"), 85)
	local cornerRad = ctx.asNumber(ctx.get("islands.cpu_panic.cornerRadius", "15"), 15)
	local expandMargin = math.floor(ctx.monitorResolution / 2 - maxExpandWidth)
	local pollInterval = ctx.asNumber(ctx.get("islands.cpu_panic.pollInterval", "12"), 12)
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
		token = token + 1
		local current = token

		textItem:set({
			drawing = true,
			label = {
				string = "􀇿 CPU Panic: " .. appName .. " (" .. cpuUsage .. "%)",
			},
		})

		ctx.Sbar.animate("tanh", 10, function()
			ctx.Sbar.bar({
				margin = expandMargin,
				corner_radius = cornerRad,
				height = expandHeight,
			})
			textItem:set({
				label = { color = 0xffff3333 }, -- Red color
			})
		end)

		ctx.delay(4.0, function()
			if current ~= token then
				return
			end

			ctx.Sbar.animate("tanh", 10, function()
				textItem:set({ label = { color = ctx.colorTransparent } })
			end)

			ctx.delay(0.2, function()
				if current ~= token then
					return
				end

				textItem:set({ drawing = false })
				ctx.Sbar.animate("tanh", 10, function()
					ctx.Sbar.bar({
						height = ctx.defaultHeight,
						corner_radius = ctx.cornerRadius,
						margin = ctx.margin,
					})
				end)
			end)
		end)
	end

	listener:subscribe("routine", function()
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
