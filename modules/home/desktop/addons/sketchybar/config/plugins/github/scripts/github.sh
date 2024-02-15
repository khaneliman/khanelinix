#!/usr/bin/env bash

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/userconfig.sh" # Loads all defined variables

render_bar_item() {
	if [ "$NOTIFICATIONS" = "[]" ]; then
		args+=(--set "$NAME" icon="$BELL" label="0")
	else
		args+=(--set "$NAME" icon="$BELL_DOT" label="$COUNT")
	fi
}

render_popup() {
	args+=(--remove '/github.notification\.*/')

	COUNTER=0
	COLOR=$BLUE
	args+=(--set github.bell icon.color="$COLOR")

	while read -r repo url type title; do
		COUNTER=$((COUNTER + 1))
		IMPORTANT="$(echo "$title" | grep -E -i "(deprecat|break|broke)")"
		COLOR=$BLUE
		PADDING=0

		if [ "${repo}" = "" ] && [ "${title}" = "" ]; then
			repo="Note"
			title="No new notifications"
		fi
		case "${type}" in
		"'Issue'")
			COLOR=$GREEN
			ICON=$GIT_ISSUE
			URL="$(gh api "$(echo "${url}" | sed -e "s/^'//" -e "s/'$//")" | jq .html_url)"
			;;
		"'Discussion'")
			COLOR=$TEXT
			ICON=$GIT_DISCUSSION
			URL="https://www.github.com/notifications"
			;;
		"'PullRequest'")
			COLOR=$MAROON
			ICON=$GIT_PULL_REQUEST
			URL="$(gh api "$(echo "${url}" | sed -e "s/^'//" -e "s/'$//")" | jq .html_url)"
			;;
		"'Commit'")
			COLOR=$TEXT
			ICON=$GIT_COMMIT
			URL="$(gh api "$(echo "${url}" | sed -e "s/^'//" -e "s/'$//")" | jq .html_url)"
			;;
		esac

		if [ "$IMPORTANT" != "" ]; then
			COLOR=$RED
			ICON=􀁞
			args+=(--set github.bell icon.color="$COLOR")
		fi

		github_notification_repo=(
			icon.font="$NERD_FONT:Bold:14.0"
			icon="$ICON $(echo "$repo" | sed -e "s/^'//" -e "s/'$//")"
			icon.padding_left="$PADDING"
			label.padding_right="$PADDING"
			icon.color="$COLOR"
			position=popup.github.bell
			icon.background.color="$COLOR"
			drawing=on
			click_script="open $URL; sketchybar --set github.bell popup.drawing=off"
		)

		github_notification_message=(
			label="$(echo "$title" | sed -e "s/^'//" -e "s/'$//")"
			icon.padding_left="$PADDING"
			icon.drawing=off
			label.padding_right=10
			icon.color="$COLOR"
			position=popup.github.bell
			icon.background.color="$COLOR"
			drawing=on
			click_script="open $URL; sketchybar --set github.bell popup.drawing=off"
		)

		args+=(--clone github.notification."$COUNTER".repo github.template)
		args+=(--set github.notification."$COUNTER".repo "${github_notification_repo[@]}")
		args+=(--clone github.notification."$COUNTER".message github.template)
		args+=(--set github.notification."$COUNTER".message "${github_notification_message[@]}")

	done <<<"$(echo "$NOTIFICATIONS" | jq -r '.[] | [.repository.name, .subject.latest_comment_url, .subject.type, .subject.title] | @sh')"

	sketchybar -m "${args[@]}" >/dev/null

}

update() {
	NOTIFICATIONS="$(gh api notifications)"
	COUNT="$(echo "$NOTIFICATIONS" | jq 'length')"

	args=()

	PREV_COUNT=$(sketchybar --query github.bell | jq -r .label.value)
	# For sound to play around with:
	# afplay /System/Library/Sounds/Morse.aiff

	render_bar_item
	render_popup

	if [ "$COUNT" -gt "$PREV_COUNT" ] 2>/dev/null || [ "$SENDER" = "forced" ]; then
		sketchybar --animate tanh 15 --set github.bell label.y_offset=5 label.y_offset=0
	fi
}

popup() {
	PREV_COUNT=$(sketchybar --query github.bell | jq -r .label.value)

	if [[ "$PREV_COUNT" -gt 0 ]]; then
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
