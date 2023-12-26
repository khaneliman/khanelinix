#!/bin/bash

HELPER=git.felix.helper
killall helper
make -C "$HOME"/.config/sketchybar/helper
"$HOME"/.config/sketchybar/helper/helper "$HELPER" >/dev/null 2>&1 &
