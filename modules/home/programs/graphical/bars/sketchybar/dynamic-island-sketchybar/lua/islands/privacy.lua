return function(ctx)
	-- Privacy dots are small, persistent indicators that appear within the island boundary
	-- when camera or microphone are in use.
	local inFlight = false
	local lastCameraState = nil
	local lastMicState = nil
	local suppressed = false
	local pollInterval = ctx.asNumber(ctx.get("islands.privacy.pollInterval", "60"), 60)
	local yOffset = ctx.asNumber(ctx.get("islands.privacy.yOffset", "0"), 0)

	local camDot = ctx.Sbar.add("item", "island.privacy.camera", {
		position = "center",
		drawing = false,
		icon = {
			string = ctx.get("icons.privacy.camera", "􀌞"),
			color = ctx.get("colors.privacyCamera", 0xff33ff33),
			font = { size = ctx.layout.fontSizes.privacyIcon },
		},
		y_offset = yOffset,
		width = ctx.layout.dimensions.emptyWidth,
	})

	local micDot = ctx.Sbar.add("item", "island.privacy.mic", {
		position = "center",
		drawing = false,
		icon = {
			string = ctx.get("icons.privacy.microphone", "􀊰"),
			color = ctx.get("colors.privacyMicrophone", 0xffff9933),
			font = { size = ctx.layout.fontSizes.privacyIcon },
		},
		y_offset = yOffset,
		width = ctx.layout.dimensions.emptyWidth,
	})

	local function applyCameraState()
		camDot:set({ drawing = lastCameraState == true and not suppressed })
	end

	local function applyMicState()
		micDot:set({ drawing = lastMicState == true and not suppressed })
	end

	local listener = ctx.Sbar.add("item", "privacyListener", {
		position = "center",
		width = ctx.layout.dimensions.emptyWidth,
		update_freq = pollInterval,
	})

	listener:subscribe("routine", function()
		if ctx.islandState.isSleeping then
			return
		end
		if inFlight then
			return
		end
		inFlight = true

		local privacyCheckCommand = [[lsof -n 2>/dev/null | awk 'BEGIN{IGNORECASE=1} ]]
			.. [[/AppleCamera/ {cam=1} /Capture/ {mic=1} ]]
			.. [[END {printf "%d|%d", cam ? 1 : 0, mic ? 1 : 0}']]

		ctx.Sbar.exec(privacyCheckCommand, function(result)
			inFlight = false
			local cameraFlag, micFlag = tostring(result or ""):match("^(%d)|(%d)$")
			local camActive = cameraFlag == "1"
			local micActive = micFlag == "1"

			if lastCameraState ~= camActive then
				lastCameraState = camActive
				applyCameraState()
			end

			if lastMicState ~= micActive then
				lastMicState = micActive
				applyMicState()
			end
		end)
	end)

	ctx.registry.setPrivacySuppressed = function(value)
		suppressed = value == true
		applyCameraState()
		applyMicState()
	end

	ctx.registry.privacyCamDot = camDot
	ctx.registry.privacyMicDot = micDot
	ctx.registry.privacyListener = listener
	ctx.subscribeItem("privacyListener", "routine")
	ctx.logDebug("[privacy][lua] module loaded")
end
