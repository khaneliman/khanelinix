#!/usr/bin/env bash

source "$HOME/.config/sketchybar/colors.sh"

disk=(
	background.padding_left=0
	label.font="$FONT:Heavy:12"
	label.color="$TEXT"
	icon="$DISK"
	icon.color="$MAROON"
	update_freq=60
	script="$PLUGIN_DIR/stats/scripts/disk.sh"
)

sketchybar --add item disk right \
	--set disk "${disk[@]}"
