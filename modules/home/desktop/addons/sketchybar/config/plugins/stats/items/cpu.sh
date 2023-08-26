#!/usr/bin/env bash

source "$HOME/.config/sketchybar/colors.sh"

cpu_percent=(
	background.padding_left=0
	background.padding_right=0
	label.font="$FONT:Heavy:12"
	label=CPU%
	label.color="$TEXT"
	icon="$CPU"
	icon.color="$BLUE"
	update_freq=2
	mach_helper="$HELPER"
)

sketchybar --add item cpu.percent right \
	--set cpu.percent "${cpu_percent[@]}"
