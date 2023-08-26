#!/bin/bash

HELPER=git.felix.helper
killall helper
cd "$HOME"/.config/sketchybar/helper && make
"$HOME"/.config/sketchybar/helper/helper "$HELPER" >/dev/null 2>&1 &
