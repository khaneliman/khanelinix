#!/usr/bin/env bash

sketchybar -m --set "$NAME" label="$(df -H | grep -E '^(/dev/disk3s1s1 ).' | awk '{ printf ("%s\n", $5) }')"
