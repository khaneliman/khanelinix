#!/usr/bin/env bash

zen_items=(
	apple.logo
	'/cpu.*/'
	calendar
	system.yabai
	separator
	front_app
	spotify.anchor
	spotify.play
	brew
	battery
	disk
	memory
	bluetooth.alias
	wifi.alias
	separator_left
	separator_right
	github.bell
	network.up
	network.down
)

zen_on() {
	args=()
	for item in "${zen_items[@]}"; do
		args+=(--set "$item" drawing=off)
	done

	sketchybar "${args[@]}"
}

zen_off() {
	args=()
	for item in "${zen_items[@]}"; do
		args+=(--set "$item" drawing=on)
	done

	sketchybar "${args[@]}"
}

if [ "$1" = "on" ]; then
	zen_on
elif [ "$1" = "off" ]; then
	zen_off
else
	if [ "$(sketchybar --query apple.logo | jq -r ".geometry.drawing")" = "on" ]; then
		zen_on
	else
		zen_off
	fi
fi
