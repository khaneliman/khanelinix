return function(ctx)
	local token = 0
	local lastBatteryState = nil
	local inFlight = false

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.power.maxExpandWidth", "190"), 190)
	local expandHeight = ctx.asNumber(ctx.get("islands.power.expandHeight", "56"), 56)
	local cornerRad = ctx.asNumber(ctx.get("islands.power.cornerRadius", "15"), 15)
	local expandMargin = math.floor(ctx.monitorResolution / 2 - maxExpandWidth)
	local pollInterval = ctx.asNumber(ctx.get("islands.power.pollInterval", "300"), 300)

	local textItem = ctx.Sbar.add("item", "island.power_text", {
		position = "right",
		drawing = false,
		label = {
			color = ctx.colorTransparent,
		},
		width = 0,
	})

	local listener = ctx.Sbar.add("item", "powerChangeListener", {
		position = "center",
		width = 0,
		update_freq = pollInterval,
	})

	local function showIsland(text, textColor, duration)
		textItem:set({
			drawing = true,
			label = {
				string = text,
			},
		})

		ctx.animateIsland({
			margin = expandMargin,
			cornerRadius = cornerRad,
			height = expandHeight,
			duration = duration,
			onExpand = function()
				textItem:set({ label = { color = textColor } })
			end,
			onHideContent = function()
				textItem:set({ label = { color = ctx.colorTransparent } })
			end,
			onCleanup = function()
				textItem:set({ drawing = false })
			end,
		})
	end

	listener:subscribe("power_source_change", function(env)
		if ctx.islandState.isSleeping then
			return
		end
		local source = ctx.trim(env.INFO or "")
		local icon = ctx.get("icons.power.onBattery", "􀺸")
		local text = "On Battery"

		if source == "AC" then
			icon = ctx.get("icons.power.connectedAC", "􀢋")
			text = "Charging"
		elseif source == "BATTERY" then
			text = "On Battery"
		else
			text = source ~= "" and source or text
		end

		ctx.logger.debug("power", "source_changed", { source = source })
		showIsland(icon .. " " .. text, ctx.colorWhite, 0.8)
	end)

	listener:subscribe("routine", function()
		if ctx.islandState.isSleeping then
			return
		end
		if inFlight then
			return
		end
		inFlight = true

		ctx.Sbar.exec("pmset -g batt", function(batt_info)
			inFlight = false
			local found, _, percent = string.find(batt_info, "(%d+)%%")
			if found then
				local current_percent = tonumber(percent)
				local is_charging = string.find(batt_info, "AC Power")

				-- If battery drops below 20% and we aren't charging
				if current_percent <= 20 and not is_charging then
					-- Only alert once when it drops into the low state, or every 5% drop
					if lastBatteryState == nil or lastBatteryState > current_percent then
						ctx.logger.warn("power", "low_battery", { percent = current_percent })
						showIsland("􀛨 Low Battery: " .. tostring(current_percent) .. "%", 0xffff3333, 3.0)
						-- Update last known state, snap to nearest 5% step so we alert again if it keeps dropping
						lastBatteryState = math.floor(current_percent / 5) * 5
					end
				else
					-- Reset state when charged back up
					if current_percent > 20 then
						lastBatteryState = nil
					end
				end
			end
		end)
	end)

	ctx.registry.powerTextItem = textItem
	ctx.registry.powerListener = listener
	ctx.subscribeItem("powerChangeListener", { "power_source_change", "routine" })
	ctx.logDebug("[power][lua] module loaded")
end
