#!/usr/bin/env sh

option=$(printf "Suspend\nReboot\nShutdown\nLock\nLogout" | rofi -dmenu -i -p "Power menu:")

case "$option" in
Lock)
  hyprlock
  ;;
Suspend)
  systemctl suspend
  ;;
Reboot)
  systemctl reboot
  ;;
Shutdown)
  systemctl poweroff
  ;;
Logout)
  hyprctl dispatch exit
  ;;
esac
