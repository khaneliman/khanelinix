#!/usr/bin/env bash

POPUP_CLICK_SCRIPT="sketchybar --set weather popup.drawing=toggle"

weather_icon=(
	icon=
	icon.align=right
	y_offset=6
	background.padding_right=-15
	icon.padding_left=12
	icon.padding_right=2
)

weather_temp=(
	label="temp"
	update_freq=60
	popup.align=right
	popup.height=20
	y_offset=-8
	script="$PLUGIN_DIR/weather/scripts/weather.sh"
	click_script="$POPUP_CLICK_SCRIPT"
	label.align=right
	label.padding_left==0
	label.padding_right==0
	background.padding_right=-30
	background.padding_left=5
)

weather_details=(
	drawing=off
	background.corner_radius=12
	padding_left=7
	padding_right=7
	icon.font="$FONT:Bold:14.0"
	icon.background.height=2
	icon.background.y_offset=-12
)

sketchybar 	--add item weather.icon right 								\
						--set weather.icon "${weather_icon[@]}" 			\
																													\
						--add item weather.temp right 								\
						--set weather.temp "${weather_temp[@]}" 			\
																													\
						--add item weather.details popup.weather.temp \
						--set weather.details "${weather_details[@]}" \
						--subscribe weather.temp mouse.entered 				\
																		 mouse.exited 				\
																		 mouse.exited.global
