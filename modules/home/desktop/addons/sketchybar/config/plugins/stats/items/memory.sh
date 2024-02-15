#!/usr/bin/env bash

source "$HOME/.config/sketchybar/colors.sh"

memory=(
	background.padding_left=0
	label.font="$FONT:Heavy:12"
	label.color="$TEXT"
	icon="$MEMORY"
	icon.font="$FONT:Bold:16.0"
	icon.color="$GREEN"
	update_freq=15
	script="$PLUGIN_DIR/stats/scripts/ram.sh"
)

sketchybar --add item memory right \
	--set memory "${memory[@]}"
