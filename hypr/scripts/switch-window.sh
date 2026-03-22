#!/usr/bin/env sh

# Get window title name
title=$(hyprctl clients -j | jq ".[].title" | cut -d'"' -f2 | sort | rofi -i -dmenu -p "Windows")

# Get that title window address
address=$(hyprctl clients -j | jq --arg TITLE "$title" -r '[.[] | select(.title | test($TITLE; "i"))][0] | .address')

# Change focus to that window
hyprctl dispatch focuswindow address:$address
