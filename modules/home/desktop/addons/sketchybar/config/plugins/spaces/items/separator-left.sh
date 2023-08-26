#!/usr/bin/env bash

separator_left=(
	icon=
	icon.font="$NERD_FONT:Regular:16.0"
	background.padding_left=10
	background.padding_right=10
	label.drawing=off
	associated_display=active
	click_script='yabai -m space --create
                sketchybar --trigger space_change'
	icon.color="$TEXT"
)

sketchybar --add item separator_left left \
	--set separator_left "${separator_left[@]}"
