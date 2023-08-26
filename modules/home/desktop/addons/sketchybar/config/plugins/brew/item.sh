#!/usr/bin/env bash

# Trigger the brew_udpate event when brew update or upgrade is run from cmdline
# e.g. via function in .zshrc or fish function

POPUP_CLICK_SCRIPT="sketchybar --set $NAME popup.drawing=toggle"

brew=(
	script="$PLUGIN_DIR/brew/scripts/brew.sh"
	click_script="$POPUP_CLICK_SCRIPT"
	icon=􀐛
	label=?
	update_freq=30
	popup.align=right
	popup.height=20
)

brew_details=(
	background.corner_radius=12
	background.padding_left=5
	background.padding_right=10
	click_script="sketchybar --set brew popup.drawing=off"
)

sketchybar  --add event brew_update                   	    \
            --add item 	brew right                     	    \
            --set brew  "${brew[@]}"                        \
                      	                                    \
            --subscribe brew  brew_update                   \
                              mouse.entered                 \
                              mouse.exited                  \
                              mouse.exited.global           \
                                                            \
            --add item  brew.details popup.brew             \
            --set brew.details "${brew_details[@]}"
