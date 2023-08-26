#!/usr/bin/env bash

source "$HOME/.config/sketchybar/colors.sh"

# False = night
# True = daytime
weather_icon_map() {
	shopt -s extglob
	# check if first argument is true or false to determine whether day or night
	# then check if second argument wildcard contains a string for determining which icon to show
	# if no match, return default icon
	if [ "$1" = "true" ]; then # Daytime
		case $2 in
		*Snow*)
			icon_result=""
			;;
		*Rain*)
			icon_result=""
			;;
		*"Partly Sunny"* | *"Partly Cloudy"*)
			icon_result=""
			;;
		*Sunny*)
			icon_result=""
			;;
		*Cloudy*)
			icon_result=""
			;;
		*)
			icon_result=""
			;;
		esac
	else
		case $2 in # Night
		*Snow*)
			icon_result=""
			;;
		*Rain*)
			icon_result=""
			;;
		*Clear*)
			icon_result=""
			;;
		*Cloudy*)
			icon_result=""
			;;
		*Fog*)
			icon_result=""
			;;
		*)
			icon_result=""
			;;
		esac
	fi
	echo $icon_result
}

render_bar() {
	sketchybar --set weather.icon icon="$icon"
	sketchybar --set weather.temp label="$temp""°"
}

render_popup() {
	sketchybar --remove '/weather.details.\.*/'

	weather_details=(
		label="$forecast $popup_weather"
		label.padding_left=80
		click_script="sketchybar --set $NAME popup.drawing=off"
		position=popup.weather.temp
		drawing=on
	)

	COUNTER=0

	sketchybar --clone weather.details."$COUNTER" weather.details
	sketchybar --set weather.details."$COUNTER" "${weather_details[@]}"

	echo "$weather" | jq -r '.properties.periods[] | @base64' | while read -r period; do
		COUNTER=$((COUNTER + 1))

		if [ "$COUNTER" -lt 4 ]; then
			decoded_period=$(echo "$period" | base64 --decode)
			period_name=$(echo "$period" | base64 --decode | jq -r '.name')
			detailed_forecast=$(echo "$decoded_period" | jq -r '.detailedForecast')
			temperature=$(echo "$decoded_period" | jq -r '.temperature')
			temperature_unit=$(echo "$decoded_period" | jq -r '.temperatureUnit')

			weather_period=(
				icon="$period_name - $temperature $temperature_unit"
				icon.color="$BLUE"
				label="$sentence"
				label.drawing=on
				click_script="sketchybar --set $NAME popup.drawing=off"
				drawing=on
			)

			item=weather.details."$COUNTER"
			sketchybar --add item "$item" popup.weather.temp
			sketchybar --set "$item" "${weather_period[@]}"

			SUBCOUNTER=0
			echo "$detailed_forecast" | grep -o -E '\b[^.!?]*[.!?]' | while read -r sentence; do

				SUBCOUNTER=$((SUBCOUNTER + 1))
				weather_period=(
					label="$sentence"
					label.drawing=on
					click_script="sketchybar --set $NAME popup.drawing=off"
					drawing=on
				)

				item=weather.details."$COUNTER"."$SUBCOUNTER"
				sketchybar --add item "$item" popup.weather.temp
				sketchybar --set "$item" "${weather_period[@]}"
			done

			sketchybar --add item weather.details.newline."$COUNTER" popup.weather.temp
		fi
	done
}

update() {
	# Bar
	url=$(jq -r '.weathergov | "\(.url)\(.location)/\(.format)"' ~/weather_config.json)
	weather=$(curl -s "$url")
	temp=$(echo "$weather" | jq -r '.properties.periods[0].temperature')
	forecast=$(echo "$weather" | jq -r '.properties.periods[0].shortForecast')
	time=$(echo "$weather" | jq -r '.properties.periods[0].isDaytime')
	icon=$(weather_icon_map "$time" "$forecast")

	# popup
	url=$(jq -r '.wttr | "\(.url)\(.location)?\(.format)"' ~/weather_config.json)
	popup_weather=$(curl -s "$url" | sed 's/  */ /g')

	render_bar
	render_popup

	if [ "$COUNT" -ne "$PREV_COUNT" ] 2>/dev/null || [ "$SENDER" = "forced" ]; then
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
