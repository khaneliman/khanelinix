return function(ctx)
	-- Privacy dots are small, persistent indicators that appear within the island boundary
	-- when camera or microphone are in use.

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
		update_freq = 5, -- Check every 5 seconds
	})

	listener:subscribe("routine", function()
		-- Check Camera (Lightweight check using lsof for the system camera driver)
		ctx.Sbar.exec("lsof -n | grep -i 'AppleCamera' | grep -v 'grep' | head -n 1", function(cam_result)
			local camActive = cam_result ~= ""
			camDot:set({ drawing = camActive })
		end)

		-- Check Microphone (Checking if any process has an open handle to the CoreAudio input)
		-- This is a bit tricky without a specialized tool, but checking for 'Capture' handles in lsof works for many apps.
		ctx.Sbar.exec("lsof -n | grep -i 'Capture' | grep -v 'grep' | head -n 1", function(mic_result)
			local micActive = mic_result ~= ""
			micDot:set({ drawing = micActive })
		end)
	end)

	ctx.registry.privacyCamDot = camDot
	ctx.registry.privacyMicDot = micDot
	ctx.registry.privacyListener = listener
	ctx.subscribeItem("privacyListener", "routine")
	ctx.appendLog(ctx.debugLogPath, "[privacy][lua] module loaded")
end
