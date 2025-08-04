#!/usr/bin/env bash

# Init wallpaper daemon
swww-daemon &

# Set wallpaper
swww img ~/Pictures/wallpapers/Courtside-Sunset.png &

# Main bar
waybar &

# Notifications manager
dunst &

# Cliphist
wl-paste --watch cliphist store & # Stores only text data

# Default apps
brave &
obsidian &
hyprctl dispatch exec "[workspace 2 silent] obsidian" &
