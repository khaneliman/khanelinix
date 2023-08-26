#!/usr/bin/env bash

battery_details=(
	background.corner_radius=12
	background.padding_left=5
	background.padding_right=10
	icon.background.height=2
	icon.background.y_offset=-12
)

sketchybar -m --add item    battery right 		                               \
              --set battery update_freq=1 			                             \
                            script="$PLUGIN_DIR/battery/scripts/battery.sh"  \
              --subscribe   battery           mouse.entered                  \
                                              mouse.exited                   \
                                              mouse.exited.global            \
                                                                             \
              --add         item              battery.details popup.battery  \
              --set         battery.details   "${battery_details[@]}"                                
