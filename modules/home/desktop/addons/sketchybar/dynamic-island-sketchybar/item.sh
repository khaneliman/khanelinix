#!/usr/bin/env bash

# clear cache
PREVIOUS_ISLAND_CACHE="$HOME/.config/dynamic-island-sketchybar/scripts/islands/previous_island"
true >"$PREVIOUS_ISLAND_CACHE"

# module initalization
if [[ $P_DYNAMIC_ISLAND_MUSIC_ENABLED == 1 ]]; then
	if [[ $P_DYNAMIC_ISLAND_MUSIC_SOURCE == "Music" ]]; then
		MUSIC_EVENT="com.apple.Music.playerInfo"
	elif [[ $P_DYNAMIC_ISLAND_MUSIC_SOURCE == "Spotify" ]]; then
		MUSIC_EVENT="com.spotify.client.PlaybackStateChanged"
	else
		exit 0
	fi

	source "$DYNAMIC_ISLAND_DIR/scripts/islands/music/creator.sh"

	dynamic-island-sketchybar --add event music_change "$MUSIC_EVENT" \
		--add item musicListener center \
		--set musicListener script="$DYNAMIC_ISLAND_DIR/scripts/islands/music/handler.sh $P_DYNAMIC_ISLAND_MUSIC_SOURCE" \
		width=0 \
		--subscribe musicListener music_change
fi

if [[ $P_DYNAMIC_ISLAND_APPSWITCH_ENABLED == 1 ]]; then
	source "$DYNAMIC_ISLAND_DIR/scripts/islands/appswitch/creator.sh"
	dynamic-island-sketchybar --add item frontAppSwitchListener center \
		--set frontAppSwitchListener script="$DYNAMIC_ISLAND_DIR/scripts/islands/appswitch/handler.sh" \
		width=0 \
		--subscribe frontAppSwitchListener front_app_switched
fi

if [[ $P_DYNAMIC_ISLAND_VOLUME_ENABLED == 1 ]]; then
	source "$DYNAMIC_ISLAND_DIR/scripts/islands/volume/creator.sh"
	dynamic-island-sketchybar --add item volumeChangeListener center \
		--set volumeChangeListener script="$DYNAMIC_ISLAND_DIR/scripts/islands/volume/handler.sh" \
		width=0 \
		--subscribe volumeChangeListener volume_change
fi

if [[ $P_DYNAMIC_ISLAND_BRIGHTNESS_ENABLED == 1 ]]; then
	source "$DYNAMIC_ISLAND_DIR/scripts/islands/brightness/creator.sh"
	dynamic-island-sketchybar --add item brightnessChangeListener center \
		--set brightnessChangeListener script="$DYNAMIC_ISLAND_DIR/scripts/islands/brightness/handler.sh" \
		width=0 \
		--subscribe brightnessChangeListener brightness_change
fi

if [[ $P_DYNAMIC_ISLAND_WIFI_ENABLED == 1 ]]; then
	source "$DYNAMIC_ISLAND_DIR/scripts/islands/wifi/creator.sh"
	dynamic-island-sketchybar --add item wifiChangeListener center \
		--set wifiChangeListener script="$DYNAMIC_ISLAND_DIR/scripts/islands/wifi/handler.sh" \
		width=0 \
		--subscribe wifiChangeListener wifi_change
fi

if [[ $P_DYNAMIC_ISLAND_POWER_ENABLED == 1 ]]; then
	source "$DYNAMIC_ISLAND_DIR/scripts/islands/power/creator.sh"
	dynamic-island-sketchybar --add item powerChangeListener center \
		--set powerChangeListener script="$DYNAMIC_ISLAND_DIR/scripts/islands/power/handler.sh" \
		width=0 \
		--subscribe powerChangeListener power_source_change
fi

if [[ $P_DYNAMIC_ISLAND_NOTIFICATION_ENABLED == 1 ]]; then
	source "$DYNAMIC_ISLAND_DIR/scripts/islands/notification/creator.sh"
fi

# initialize listener to communicate with helper
source "$DYNAMIC_ISLAND_DIR/listener.sh"
