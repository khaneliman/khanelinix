#!/usr/bin/env bash

source "$HOME/.config/sketchybar/colors.sh"

render_bar_item() {
	sketchybar --set "${NAME}" icon.color=0xff989898

	if [[ ${CHARGING} != "" ]]; then
		case ${BATT_PERCENT} in
		100) ICON="" COLOR="$GREEN" ;;
		9[0-9]) ICON="" COLOR="$GREEN" ;;
		8[0-9]) ICON="" COLOR="$GREEN" ;;
		7[0-9]) ICON="" COLOR="$GREEN" ;;
		6[0-9]) ICON="" COLOR="$YELLOW" ;;
		5[0-9]) ICON="" COLOR="$YELLOW" ;;
		4[0-9]) ICON="" COLOR="$PEACH" ;;
		3[0-9]) ICON="" COLOR="$PEACH" ;;
		2[0-9]) ICON="" COLOR="$RED" ;;
		1[0-9]) ICON="" COLOR="$RED" ;;
		*) ICON="" COLOR="$RED" ;;
		esac

		sketchybar --set "${NAME}" icon="${ICON}" icon.color="${COLOR}"
		sketchybar --set "${NAME}" label="${BATT_PERCENT}%"

		low_battery_label
		return 0
	fi

	case ${BATT_PERCENT} in
	100) ICON="" COLOR="$GREEN" ;;
	9[0-9]) ICON="" COLOR="$GREEN" ;;
	8[0-9]) ICON="" COLOR="$GREEN" ;;
	7[0-9]) ICON="" COLOR="$GREEN" ;;
	6[0-9]) ICON="" COLOR="$YELLOW" ;;
	5[0-9]) ICON="" COLOR="$YELLOW" ;;
	4[0-9]) ICON="" COLOR="$PEACH" ;;
	3[0-9]) ICON="" COLOR="$PEACH" ;;
	2[0-9]) ICON="" COLOR="$RED" ;;
	1[0-9]) ICON="" COLOR="$RED" ;;
	*) ICON="" COLOR="$RED" ;;
	esac

	sketchybar --set "${NAME}" icon="${ICON}" icon.color="${COLOR}"

	low_battery_label
}

low_battery_label() {
	if [[ "$BATT_PERCENT" -lt 50 ]]; then
		sketchybar --set "${NAME}" label="${BATT_PERCENT}%" label.drawing=on
	else
		sketchybar --set "${NAME}" label.drawing=off
	fi
}

render_popup() {
	battery_details=(
		label="${BATT_PERCENT}%"
		label.padding_right=0
		label.padding_right=0
		label.align=center
		click_script="sketchybar --set $NAME popup.drawing=off"
	)

	args+=(--set battery.details "${battery_details[@]}")

	sketchybar -m "${args[@]}" >/dev/null
}

update() {
	BATT_COMMAND=$(pmset -g batt)
	BATT_PERCENT=$(echo "$BATT_COMMAND" | grep -oE '[0-9]+%' | cut -d% -f1)
	CHARGING=$(echo "$BATT_COMMAND" | grep 'AC Power')

	render_bar_item
	render_popup
}

popup() {
	BATT_PERCENT=$(sketchybar --query battery.details | jq -r '.label.value | sub("%"; "")')

	if [[ "$BATT_PERCENT" -gt 49 ]]; then
		sketchybar --set "$NAME" popup.drawing="$1"
	else
		sketchybar --set "$NAME" popup.drawing=off
	fi
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
