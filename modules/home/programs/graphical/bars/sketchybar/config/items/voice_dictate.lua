#!/usr/bin/env lua

local colors = require("colors")
local icons = require("icons")

local voice_dictate = Sbar.add("item", "voice_dictate", {
	position = "center",
	drawing = false,
	update_freq = 1,
	icon = {
		string = "󰍬",
		color = colors.teal,
		padding_left = 10,
		padding_right = 4,
	},
	label = {
		string = "Listening",
		color = colors.text,
		padding_left = 0,
		padding_right = 10,
	},
	background = {
		color = colors.surface0,
		border_color = colors.surface1,
		border_width = 2,
	},
})

local state = "idle"
local frame_idx = 1
local frames = { "◐", "◓", "◑", "◒" }
local recording_frames = { "●", "◉", "●", "◎" }

local function set_state(next_state)
	state = next_state

	if state == "idle" then
		voice_dictate:set({
			drawing = false,
		})
		return
	end

	if state == "listening" then
		voice_dictate:set({
			drawing = true,
			icon = { string = "󰍬", color = colors.teal },
			label = { string = frames[frame_idx] .. " Listening", color = colors.text },
		})
		return
	end

	if state == "recording" then
		voice_dictate:set({
			drawing = true,
			icon = { string = "󰻃", color = colors.red },
			label = { string = recording_frames[frame_idx] .. " Recording", color = colors.red },
		})
		return
	end

	if state == "transcribing" then
		voice_dictate:set({
			drawing = true,
			icon = { string = icons.loading, color = colors.peach },
			label = { string = "Transcribing", color = colors.text },
		})
		return
	end

	if state == "done" then
		voice_dictate:set({
			drawing = true,
			icon = { string = "✓", color = colors.green },
			label = { string = "Done", color = colors.text },
		})
		Sbar.exec("sh -c 'sleep 2; sketchybar --trigger voice_dictate_state STATE=idle'")
		return
	end

	if state == "error" then
		voice_dictate:set({
			drawing = true,
			icon = { string = "!", color = colors.red },
			label = { string = "No speech", color = colors.red },
		})
		Sbar.exec("sh -c 'sleep 3; sketchybar --trigger voice_dictate_state STATE=idle'")
		return
	end
end

voice_dictate:subscribe("voice_dictate_state", function(env)
	local next_state = (env.STATE or "idle"):lower()
	frame_idx = 1
	set_state(next_state)
end)

voice_dictate:subscribe("routine", function()
	if state ~= "listening" and state ~= "recording" then
		return
	end

	frame_idx = (frame_idx % #frames) + 1
	if state == "listening" then
		voice_dictate:set({
			label = { string = frames[frame_idx] .. " Listening" },
		})
	else
		voice_dictate:set({
			label = { string = recording_frames[frame_idx] .. " Recording" },
		})
	end
end)

return voice_dictate
