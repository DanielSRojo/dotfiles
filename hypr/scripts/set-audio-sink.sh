#!/usr/bin/env sh

# Prompt user to select an audio sink via rofi
# sink=$(pactl list short sinks | cut -f2 | rofi -dmenu -p "Audio Sink")

# Set selected sink as default (if any was chosen)
# [ -n "$sink" ] && pactl set-default-sink "$sink"

# sink=$(pactl list short sinks | cut -f2 | rofi -dmenu -p "Audio Sink")
sink_description=$(pactl list sinks | grep -E 'Description:' | cut -d':' -f2 | rofi -dmenu -i -p "Audio Sink")
sink_name=$(pactl list sinks | grep "$sink_description" -B1 | rg -i Name | cut -d":" -f2 | xargs)
[ -n "$sink_name" ] && pactl set-default-sink "$sink_name"
