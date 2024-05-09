#!/usr/bin/env bash
echo "volume"
echo "$INFO"

dynamic-island-sketchybar --trigger dynamic_island_queue INFO="volume" ISLAND_ARGS="$INFO"
