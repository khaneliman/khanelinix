#!/usr/bin/env bash

POPUP_CLICK_SCRIPT="sketchybar --set ical popup.drawing=toggle"

ical=(
	update_freq=180
	icon=􀉉
	icon.padding_right=0
	icon.align=left
	popup.align=right
	popup.height=20
	background.padding_left=10
	y_offset=-8
	script="$PLUGIN_DIR/date/scripts/ical.sh"
	click_script="$POPUP_CLICK_SCRIPT"
)

ical_details=(
	drawing=off
	background.corner_radius=12
	padding_left=7
	padding_right=7
	icon.font="$FONT:Bold:14.0"
	icon.background.height=2
	icon.background.y_offset=-12
)

sketchybar  --add       item            ical right                            \
            --set       ical            "${ical[@]}"                          \
                                                                              \
            --add       item            ical.details popup.ical               \
            --set       ical.details    "${ical_details[@]}"                  \
            --subscribe ical            mouse.entered                         \
                                        mouse.exited                          \
                                        mouse.exited.global
