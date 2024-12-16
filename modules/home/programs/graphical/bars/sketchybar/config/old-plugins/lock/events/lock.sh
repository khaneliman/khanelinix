#!/usr/bin/env sh

sketchybar --add event lock "com.apple.screenIsLocked" \
    --add event unlock "com.apple.screenIsUnlocked" \
    \
    --add item animator left \
    --set animator drawing=off \
    updates=on \
    script="$CONFIG_DIR/plugins/lock/scripts/wake.sh" \
    --subscribe animator lock unlock
