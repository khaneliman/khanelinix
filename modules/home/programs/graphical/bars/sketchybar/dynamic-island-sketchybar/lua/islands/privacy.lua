return function(ctx)
	-- Privacy dots are small, persistent indicators that appear within the island boundary
	-- when camera or microphone are in use.
	local inFlight = false
	local lastCameraState = nil
	local lastMicState = nil
	local pollInterval = ctx.asNumber(ctx.get("islands.privacy.pollInterval", "12"), 12)

	local camDot = ctx.Sbar.add("item", "island.privacy.camera", {
		position = "center",
		drawing = false,
		icon = {
			string = "􀌞", -- Camera icon
			color = 0xff33ff33, -- Green
			font = { size = 10 },
		},
		y_offset = 0,
		width = 0,
	})

	local micDot = ctx.Sbar.add("item", "island.privacy.mic", {
		position = "center",
		drawing = false,
		icon = {
			string = "􀊰", -- Mic icon
			color = 0xffff9933, -- Orange
			font = { size = 10 },
		},
		y_offset = 0,
		width = 0,
	})

	local listener = ctx.Sbar.add("item", "privacyListener", {
		position = "center",
		width = 0,
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
				camDot:set({ drawing = camActive })
			end

			if lastMicState ~= micActive then
				lastMicState = micActive
				micDot:set({ drawing = micActive })
			end
		end)
	end)

	ctx.registry.privacyCamDot = camDot
	ctx.registry.privacyMicDot = micDot
	ctx.registry.privacyListener = listener
	ctx.subscribeItem("privacyListener", "routine")
	ctx.logDebug("[privacy][lua] module loaded")
end
