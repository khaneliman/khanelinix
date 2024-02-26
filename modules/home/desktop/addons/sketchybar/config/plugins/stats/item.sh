#!/usr/bin/env bash

source "$CONFIG_DIR/plugins/stats/events/toggle_stats.sh"

source "$CONFIG_DIR/plugins/stats/items/separator-right.sh"

source "$CONFIG_DIR/plugins/stats/items/cpu.sh"
source "$CONFIG_DIR/plugins/stats/items/memory.sh"
source "$CONFIG_DIR/plugins/stats/items/disk.sh"
source "$CONFIG_DIR/plugins/stats/items/network.sh"
