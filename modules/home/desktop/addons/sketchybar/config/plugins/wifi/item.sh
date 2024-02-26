#!/usr/bin/env bash

POPUP_CLICK_SCRIPT="sketchybar --set \$NAME popup.drawing=toggle"

wifi=(
	icon="$WIFI"
	icon.color="$YELLOW"
	background.padding_left=5
	align=right
	click_script="$POPUP_CLICK_SCRIPT"
	script="$CONFIG_DIR/plugins/wifi/scripts/wifi.sh"
	update_freq=1
)

wifi_details=(
	background.corner_radius=12
	background.padding_left=5
	background.padding_right=10
	icon.background.height=2
	icon.background.y_offset=-12
	label.align=center
	click_script="sketchybar --set wifi popup.drawing=off"
)

sketchybar  --add item   wifi right 								                     \
            --set        wifi         "${wifi[@]}"                       \
            --subscribe  wifi          mouse.entered                     \
                                       mouse.exited                      \
                                       mouse.exited.global               \
                                                                         \
            --add       item          wifi.details popup.wifi            \
            --set       wifi.details  "${wifi_details[@]}"
