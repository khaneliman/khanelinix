#!/usr/bin/env bash

bluetooth=(
	icon.drawing=on
	icon="$BLUETOOTH"
	icon.color="$PEACH"
	background.padding_right=0
	align=right
	click_script="$CONFIG_DIR/plugins/bluetooth/scripts/bluetooth_click.sh"
	script="$CONFIG_DIR/plugins/bluetooth/scripts/bluetooth.sh"
	popup.height=30
	update_freq=1
)

bluetooth_details=(
	background.corner_radius=12
	background.padding_left=5
	background.padding_right=10
)

sketchybar  --add item   bluetooth right                                                    \
            --set        bluetooth        "${bluetooth[@]}"                                 \
            --subscribe  bluetooth        mouse.entered                                     \
                                          mouse.exited                                      \
                                          mouse.exited.global                               \
                                                                                            \
            --add       item              bluetooth.details popup.bluetooth                 \
            --set       bluetooth.details "${bluetooth_details[@]}"                         \
                                          click_script="sketchybar --set bluetooth popup.drawing=off"
