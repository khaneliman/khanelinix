#!/usr/bin/env lua

local colors = require("colors")
local power_config = require("power_config")

-- require order determines ui order on bar
local keep_awake = nil
if power_config.use_closed_lid_awake then
	keep_awake = require("items.control_center.keep_awake")
end
local battery = require("items.control_center.battery")
local wifi = require("items.control_center.wifi")
local bluetooth = require("items.control_center.bluetooth")
local brew = require("items.control_center.brew")
local github = require("items.control_center.github")
local volume = require("items.control_center.volume")

local items = {
	keep_awake and keep_awake.name or nil,
	battery.name,
	wifi.name,
	bluetooth.name,
	brew.name,
	github.name,
	volume.icon.name,
}

local visible_items = {}
for _, item in ipairs(items) do
	if item ~= nil then
		table.insert(visible_items, item)
	end
end

Sbar.add("bracket", visible_items, {
	background = {
		color = colors.surface0,
		border_color = colors.surface1,
		border_width = 2,
		padding_left = 5,
		padding_right = 10,
	},
})
