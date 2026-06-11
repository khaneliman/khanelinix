return function(ctx)
	local token = 0
	local lastBatteryState = nil
	local inFlight = false

	local maxExpandWidth = ctx.asNumber(ctx.get("islands.power.maxExpandWidth", "190"), 190)
	local expandHeight = ctx.asNumber(ctx.get("islands.power.expandHeight", "76"), 76)
	local cornerRad = ctx.asNumber(ctx.get("islands.power.cornerRadius", "22"), 22)
	local pollInterval = ctx.asNumber(ctx.get("islands.power.pollInterval", "300"), 300)

	local textItem = ctx.Sbar.add("item", "island.power_text", {
		position = "center",
		drawing = false,
		label = {
			align = "center",
			color = ctx.colorTransparent,
			y_offset = ctx.contentYOffset,
		},
		width = ctx.layout.dimensions.emptyWidth,
	})

	local listener = ctx.Sbar.add("item", "powerChangeListener", {
		position = "center",
		width = ctx.layout.dimensions.emptyWidth,
		update_freq = pollInterval,
	})

	local function showIsland(text, textColor, duration)
		local layout = ctx.layoutForText(text, {
			maxHalfWidth = maxExpandWidth,
			horizontalPadding = ctx.layout.text.powerHorizontalPadding,
		})

		textItem:set({
			drawing = true,
			width = layout.width,
			label = {
				string = text,
			},
		})

		ctx.animateIsland({
			margin = layout.margin,
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
				textItem:set({
					drawing = false,
					width = ctx.layout.dimensions.emptyWidth,
				})
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
		showIsland(icon .. " " .. text, ctx.colorWhite, ctx.layout.animation.shortEventDuration)
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
						showIsland(
							ctx.get("icons.power.lowBattery", "􀛨")
								.. " Low Battery: "
								.. tostring(current_percent)
								.. "%",
							ctx.get("colors.alertRed", 0xffff3333),
							ctx.layout.animation.warningDuration
						)
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
