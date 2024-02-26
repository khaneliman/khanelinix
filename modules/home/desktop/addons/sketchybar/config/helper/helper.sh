#!/bin/bash

HELPER=git.felix.helper
killall helper
make -C "$CONFIG_DIR/helper"
"$CONFIG_DIR/helper/helper" "$HELPER" >/dev/null 2>&1 &
