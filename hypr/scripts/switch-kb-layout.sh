#!/usr/bin/env bash

# Switch to nex tkeyboard layout
hyprctl switchxkblayout rdmctmzt-rd-75 next

# Send singal to waybar so it resets and redraw the keyboard layout icon
pkill -SIGRTMIN+9 waybar

# Get current layout
kb_layout=$(hyprctl devices -j | jq -r '.keyboards[] | select(.name == "rdmctmzt-rd-75") | .active_keymap' | cut -d' ' -f1)

# Trigger notification
notify-send -e -u low " Keyboard Layout: $kb_layout"
