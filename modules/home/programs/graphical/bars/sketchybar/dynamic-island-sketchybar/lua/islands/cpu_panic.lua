return function(ctx)
	local token = 0
	local lastPanicApp = nil

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.cpu_panic.maxExpandWidth", "200"), 200)
	local expandHeight = ctx.asNumber(ctx.get("islands.cpu_panic.expandHeight", "85"), 85)
	local cornerRad = ctx.asNumber(ctx.get("islands.cpu_panic.cornerRadius", "15"), 15)
	local expandMargin = math.floor(ctx.monitorResolution / 2 - maxExpandWidth)

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
		update_freq = 5, -- Check every 5 seconds
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

		ctx.Sbar.exec("sleep 4.0", function()
			if current ~= token then
				return
			end

			ctx.Sbar.animate("tanh", 10, function()
				textItem:set({ label = { color = ctx.colorTransparent } })
			end)

			ctx.Sbar.exec("sleep 0.2", function()
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
		-- Get top CPU consuming process, excluding Sketchybar itself
		ctx.Sbar.exec("ps -Ao %cpu,comm -r | grep -v 'sketchybar' | head -n 1", function(result)
			if not result or result == "" then
				return
			end

			local cpu, comm = result:match("^%s*(%d+%.?%d*)%s+(.*)$")
			if cpu and comm then
				local cpuVal = tonumber(cpu)
				local appName = comm:match("([^/]+)$") or comm

				if cpuVal > 90 then
					-- Alert if it's a new panic or the same app still panicking after some time
					if lastPanicApp ~= appName then
						ctx.appendLog(
							ctx.debugLogPath,
							"[cpu_panic][lua] high cpu detected: " .. appName .. " (" .. cpu .. "%)"
						)
						showPanic(appName, cpu)
						lastPanicApp = appName
					end
				else
					lastPanicApp = nil
				end
			end
		end)
	end)

	ctx.registry.cpuPanicTextItem = textItem
	ctx.registry.cpuPanicListener = listener
	ctx.subscribeItem("cpuPanicListener", "routine")
	ctx.appendLog(ctx.debugLogPath, "[cpu_panic][lua] module loaded")
end
