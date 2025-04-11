#!/usr/bin/env bash

# Get the temperature value from hyprctl
temp=$(hyprctl hyprsunset temperature 2>/dev/null)

# Remove any whitespace
temp=$(echo "$temp" | tr -d '[:space:]')

# Determine icon based on temperature value
if [ "$temp" -ge 5000 ]; then
    # Daytime mode
    icon="🌞"
else
    # Nighttime mode
    icon="🌙"
fi

echo "{\"text\": \"$icon\", \"alt\": \"$temp\"}"
