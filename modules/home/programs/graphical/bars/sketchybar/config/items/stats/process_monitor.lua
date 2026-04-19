#!/usr/bin/env lua

local settings = require("helpers.settings")
local colors = require("helpers.colors")
local logger = require("helpers.logger")

return function(parent_name, popup_width, header_text, header_color, exec_command, match_func)
	local protectedProcesses = {
		WindowServer = true,
		kernel_task = true,
		launchd = true,
		loginwindow = true,
		SystemUIServer = true,
		tccd = true,
		nix = true,
	}

	Sbar.add("item", parent_name .. ".details.header", {
		position = "popup." .. parent_name,
		width = popup_width,
		background = {
			padding_left = 10,
			padding_right = 10,
		},
		icon = {
			drawing = false,
		},
		label = {
			string = header_text,
			font = {
				family = settings.nerd_font,
				size = 11.0,
				style = "Bold",
			},
			align = "left",
			color = header_color,
			width = "100%",
		},
	})

	local rows = {}
	local row_pids = {}
	local row_commands = {}
	local update_top_processes

	for i = 1, 5 do
		rows[i] = Sbar.add("item", parent_name .. ".details." .. i, {
			position = "popup." .. parent_name,
			width = popup_width,
			background = {
				padding_left = 10,
				padding_right = 10,
			},
			icon = {
				drawing = false,
			},
			label = {
				string = "",
				font = {
					family = settings.nerd_font,
					size = 11.0,
					style = "Regular",
				},
				align = "left",
				color = colors.text,
				width = "100%",
			},
		})

		rows[i]:subscribe("mouse.clicked", function(env)
			local pid = row_pids[i]
			local command = row_commands[i]
			if env.BUTTON == "right" and pid ~= nil and not protectedProcesses[command] then
				logger.info("process_monitor", "kill_requested", { pid = pid, command = tostring(command) })
				Sbar.exec("kill -TERM " .. pid .. " >/dev/null 2>&1 || true")
				Sbar.exec("sleep 0.2", update_top_processes)
			else
				logger.debug("process_monitor", "kill_blocked", {
					pid = tostring(pid),
					command = tostring(command),
					button = tostring(env.BUTTON),
				})
			end
		end)
	end

	update_top_processes = function()
		Sbar.exec(exec_command, function(result)
			if result == nil then
				logger.warn("process_monitor", "command_no_output", {})
				return
			end

			local lines = {}

			for line in (result or ""):gmatch("[^\r\n]+") do
				table.insert(lines, line)
			end

			logger.debug("process_monitor", "update_start", {
				parent = parent_name,
				rows = #lines,
			})

			for i, row in ipairs(rows) do
				local row_string = lines[i] or ""
				local pid, command = match_func(row_string)
				row_pids[i] = pid
				row_commands[i] = command

				row:set({
					label = {
						string = row_string,
						color = protectedProcesses[command] and colors.yellow or colors.text,
					},
				})
			end
		end)
	end

	return {
		update = update_top_processes,
	}
end
