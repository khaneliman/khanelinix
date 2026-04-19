#!/usr/bin/env lua

local settings = require("helpers.settings")
local colors = require("helpers.colors")
local icons = require("helpers.icons")
local logger = require("helpers.logger")

local nix = Sbar.add("item", "nix", {
	position = "right",
	background = {
		padding_left = 5,
		padding_right = 5,
	},
	updates = true,
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
	update_freq = 120,
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

SETUP_POPUP_HOVER(nix)

nix:subscribe({ "forced", "system_woke", "routine", "nix_update" }, function()
	logger.debug("nix", "update_start", {})
	local cmd = [[
		launchd_pid() {
			launchctl print "$1" 2>/dev/null | awk '
				/state = running/ { running = 1 }
				$1 == "pid" && $2 == "=" { pid = $3 }
				END {
					if (running && pid != "") {
						print pid
					}
				}
			'
		}

		print_status() {
			runtime=$(ps -o etime= -p "$2" | tr -d ' ')

			if [ -n "$runtime" ]; then
				printf '%s|%s|%s\n' "$1" "$runtime" "$3"
			fi
		}

		pid=$(launchd_pid system/org.nixos.nix-gc)
		if [ -n "$pid" ]; then
			print_status "GC" "$pid" "system"
			exit 0
		fi

		pid=$(launchd_pid system/org.nixos.nix-optimise)
		if [ -n "$pid" ]; then
			print_status "Optimize" "$pid" "system"
			exit 0
		fi

		pid=$(launchd_pid "gui/$(id -u)/org.nix-community.home.nh-clean")
		if [ -n "$pid" ]; then
			print_status "GC" "$pid" "user"
			exit 0
		fi

		pid=$(pgrep -f -u "$(id -u)" 'nix store gc' | head -n 1)
		if [ -n "$pid" ]; then
			print_status "GC" "$pid" "user"
		fi
	]]
	Sbar.exec(cmd, function(result)
		if IS_EMPTY(result) then
			logger.debug("nix", "no_active_jobs", {})
			nix:set({ drawing = false })
			nix:set({ popup = { drawing = false } })
			return
		end

		result = result:gsub("\n", "")
		if result ~= "" then
			local op_type, runtime, scope = result:match("([^|]+)|([^|]+)|([^|]+)")
			if op_type and runtime and scope then
				local icon_color = op_type == "Optimize" and colors.yellow or colors.red

				nix:set({
					drawing = true,
					label = op_type,
					icon = { color = icon_color },
				})
				nix_details:set({
					label = "Runtime: " .. runtime .. " (" .. scope .. ")",
				})
				logger.info("nix", "job_active", { type = op_type, runtime = runtime, scope = scope })
			else
				logger.warn("nix", "parse_failed", { payload = result })
				nix:set({ drawing = false })
				nix:set({ popup = { drawing = false } })
			end
		end
	end)
end)

nix:subscribe("mouse.clicked", function(env)
	logger.debug("nix", "manual_kill_requested", { button = env.BUTTON })
	if env.BUTTON == "right" then
		-- Right click kills nix-store --optimise
		Sbar.exec(
			'osascript -e \'do shell script "pkill -f \\"nix-store --optimise\\"" with administrator privileges\''
		)
		Sbar.trigger("nix_update")
	else
		-- Left click kills active garbage-collection jobs
		Sbar.exec(
			'osascript -e \'do shell script "pkill -f \\"nix-collect-garbage\\"; pkill -f \\"nix store gc\\"; pkill -f \\"nh clean user\\"" with administrator privileges\''
		)
		Sbar.trigger("nix_update")
	end
end)

return nix
