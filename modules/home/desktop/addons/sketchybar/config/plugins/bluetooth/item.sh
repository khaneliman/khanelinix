#!/usr/bin/env bash

bluetooth_alias=(
	icon.drawing=off
	alias.color="$PEACH"
	background.padding_right=0
	align=right
	click_script="$PLUGIN_DIR/bluetooth/scripts/bluetooth_click.sh"
	script="$PLUGIN_DIR/bluetooth/scripts/bluetooth.sh"
	popup.height=30
	update_freq=1
)

bluetooth_details=(
	background.corner_radius=12
	background.padding_left=5
	background.padding_right=10
)

sketchybar --add alias  "Control Center,Bluetooth" right                                    \
           --rename     "Control Center,Bluetooth" bluetooth.alias                          \
           --set        bluetooth.alias  "${bluetooth_alias[@]}"                            \
           --subscribe  bluetooth.alias  mouse.entered                                      \
                                         mouse.exited                                       \
                                         mouse.exited.global                                \
                                                                                            \
            --add       item              bluetooth.details popup.bluetooth.alias           \
            --set       bluetooth.details "${bluetooth_details[@]}"                         \
                                          click_script="sketchybar --set bluetooth.alias popup.drawing=off"
