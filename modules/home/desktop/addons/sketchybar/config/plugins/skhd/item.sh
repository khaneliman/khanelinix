#!/usr/bin/env bash

skhd=(
	icon.color="$BLUE"
	background.color="$SURFACE0"
	background.border_color="$SURFACE1"
	background.border_width=2
	icon.padding_left=10
	icon.padding_right=5
	drawing=off
	icon="N"
)

sketchybar --add item skhd left \
	--set skhd "${skhd[@]}"
