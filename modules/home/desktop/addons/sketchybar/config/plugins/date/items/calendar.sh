#!/usr/bin/env bash

calendar_date=(
	icon=date
	icon.font="$FONT:Black:14.0"
	icon.align=right
	icon.padding_right=0
	width=30
	y_offset=6
	update_freq=120
	script="$PLUGIN_DIR/date/scripts/date.sh"
	click_script="$PLUGIN_DIR/date/scripts/zen.sh"
)

calendar_clock=(
	icon=clock
	icon.font="$FONT:Bold:12.0"
	icon.align=right
	icon.padding_right=0
	background.padding_right=-20
	background.padding_left=0
	y_offset=-8
	update_freq=15
	script="$PLUGIN_DIR/date/scripts/clock.sh"
	click_script="$PLUGIN_DIR/date/scripts/zen.sh"
	label.padding_left=-50
)

sketchybar 	--add item calendar.date right 								\
						--set calendar.date "${calendar_date[@]}" 		\
						--subscribe calendar.date system_woke 				\
																													\
						--add item calendar.clock right 							\
						--set calendar.clock "${calendar_clock[@]}" 	\
						--subscribe calendar.clock system_woke
