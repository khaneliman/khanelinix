#!/usr/bin/env sh

STATE=$(blueutil -p)

if [ "$STATE" = "0" ]; then
	blueutil -p 1
else
	blueutil -p 0
fi
