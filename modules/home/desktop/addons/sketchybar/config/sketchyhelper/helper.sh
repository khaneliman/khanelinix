#!/bin/bash

HELPER=git.felix.helper
killall sketchyhelper
make -C "$CONFIG_DIR/sketchyhelper"
"$CONFIG_DIR/sketchyhelper/sketchyhelper" "$HELPER" >/dev/null 2>&1 &
