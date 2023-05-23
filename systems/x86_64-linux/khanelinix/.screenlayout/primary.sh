#!/usr/bin/env sh
xrandr \
	--output XWAYLAND0 --primary --mode 1920x1080 --pos 1420x0 --rotate normal \
	--output XWAYLAND1 --mode 5120x1440 --pos 0x1080 --rotate normal

wlr-randr \
	--output DP-3 --off && sleep 1 &&
	wlr-randr --output DP-3 --on --pos 1420,0 --mode 3840x2160@59.997 --scale 2
