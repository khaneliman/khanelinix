#!/usr/bin/env lua

local settings = require("settings")
local colors = require("colors")
local icons = require("icons")

local nix = Sbar.add("item", "nix", {
	position = "right",
	background = {
		padding_left = 5,
		padding_right = 5,
	},
	label = {
		font = {
			family = settings.font,
			size = 9.0,
			style = "Heavy",
		},
		color = colors.text,
		padding_left = -16, -- Pull label left over the icon
		y_offset = -6,
	},
	icon = {
		string = icons.nix,
		color = colors.blue,
		font = {
			size = 14,
		},
		y_offset = 6,
	},
	popup = {
		align = "center",
		height = 30,
	},
	update_freq = 5,
	drawing = false,
})

local nix_details = Sbar.add("item", "nix.details", {
	position = "popup." .. nix.name,
	label = {
		font = {
			family = settings.font,
			size = 12.0,
			style = "Heavy",
		},
		color = colors.text,
	},
	background = {
		padding_left = 10,
		padding_right = 10,
	},
	icon = {
		drawing = false,
	},
})

nix:subscribe("mouse.entered", function()
	nix:set({ popup = { drawing = true } })
end)

nix:subscribe("mouse.exited", function()
	nix:set({ popup = { drawing = false } })
end)

nix:subscribe({ "routine", "forced", "system_woke" }, function()
	-- Check for specific nix operations and get runtime
	local cmd = [[
		if pgrep -f 'nix-collect-garbage' >/dev/null; then
			pid=$(pgrep -f 'nix-collect-garbage' | head -n 1)
			runtime=$(ps -o etime= -p "$pid" | tr -d ' ')
			echo "GC|$runtime"
		elif pgrep -f 'nix-store --optimise' >/dev/null; then
			pid=$(pgrep -f 'nix-store --optimise' | head -n 1)
			runtime=$(ps -o etime= -p "$pid" | tr -d ' ')
			echo "Optimize|$runtime"
		else
			echo ""
		fi
	]]
	Sbar.exec(cmd, function(result)
		result = result:gsub("\n", "")
		if result ~= "" then
			local op_type, runtime = result:match("([^|]+)|([^|]+)")
			if op_type and runtime then
				nix:set({
					drawing = true,
					label = op_type,
					icon = { color = colors.red },
				})
				nix_details:set({
					label = "Runtime: " .. runtime,
				})
			end
		else
			nix:set({ drawing = false })
			nix:set({ popup = { drawing = false } })
		end
	end)
end)

nix:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "right" then
		-- Right click kills nix-store --optimise
		Sbar.exec(
			'osascript -e \'do shell script "pkill -f \\"nix-store --optimise\\"" with administrator privileges\''
		)
	else
		-- Left click kills nix-collect-garbage
		Sbar.exec('osascript -e \'do shell script "pkill -f \\"nix-collect-garbage\\"" with administrator privileges\'')
	end
end)

return nix
