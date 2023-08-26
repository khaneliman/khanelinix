#!/usr/bin/env bash

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/userconfig.sh" # Loads all defined icons

render_bar_item() {
	if [ "$PAIRED" = "" ]; then
		args+=(--set "$NAME" label.drawing=off)
	else
		args+=(--set "$NAME" label="$COUNT_PAIRED" label.drawing=on)
	fi
}

add_paired_header() {
	bluetooth_details=(
		label="$(echo -e 'Paired Devices')"
		label.font="$FONT:Bold:14.0"
		label.align=left
		icon.drawing=off
		click_script="sketchybar --set $NAME popup.drawing=off"
	)

	sketchybar -m --set bluetooth.details "${bluetooth_details[@]}"
}

render_popup() {
	add_paired_header

	COUNTER=0

	if [ "$COUNT_PAIRED" -lt "$PREV_COUNT" ]; then
		sketchybar -m --remove '/bluetooth.device\.*/'
	fi

	while IFS= read -r device; do

		if [ "$COUNT_PAIRED" -gt "$PREV_COUNT" ]; then
			sketchybar -m --add item bluetooth.device."$COUNTER" popup."$NAME"
		fi

		bluetooth_device=(
			label="$(echo "$device" | grep -Eo '".*."')"
			label.align=right
			icon="$COUNT_PAIRED : $PREV_COUNT"
			icon.drawing=off
			click_script="sketchybar --set $NAME popup.drawing=off"
		)

		sketchybar -m --set bluetooth.device."$COUNTER" "${bluetooth_device[@]}"

		COUNTER=$((COUNTER + 1))

	done <<<"$(echo -e "$PAIRED")"
}

update() {
	args=()

	PAIRED="$(blueutil --paired)"
	CONNECTED="$(blueutil --connected)"
	COUNT_PAIRED="$(echo "$PAIRED" | grep "^.*$" -c)"
	COUNT_CONNECTED="$(echo "$CONNECTED" | grep "^.*$" -c)"
	PREV_COUNT=$(sketchybar --query bluetooth.alias | jq -r .popup.items | grep ".device*" -c)

	render_bar_item
	render_popup

	if [ "$COUNT_PAIRED" -ne "$PREV_COUNT" ] 2>/dev/null || [ "$SENDER" = "forced" ]; then
		sketchybar --animate tanh 15 --set "$NAME" label.y_offset=5 label.y_offset=0
	fi
}

popup() {
	sketchybar --set "$NAME" popup.drawing="$1"
}

case "$SENDER" in
"routine" | "forced")
	update
	;;
"mouse.entered")
	popup on
	;;
"mouse.exited" | "mouse.exited.global")
	popup off
	;;
"mouse.clicked")
	popup toggle
	;;
esac
