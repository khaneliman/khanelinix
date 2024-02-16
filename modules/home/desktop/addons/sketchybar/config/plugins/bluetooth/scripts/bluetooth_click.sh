#!/usr/bin/env sh

STATE=$(blueutil -p)

if [ "$STATE" = "0" ]; then
	blueutil -p 1
	sketchybar --set bluetooth icon="$BLUETOOTH"
else
	blueutil -p 0
	sketchybar --set bluetooth icon="$BLUETOOTH_OFF"
fi
