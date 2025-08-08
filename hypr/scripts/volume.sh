#!/usr/bin/env bash
# Source: https://github.com/JaKooLit
# Scripts for volume controls for audio and mic

icons_dir="$HOME/.config/swaync/icons"
scripts_dir="$HOME/.config/hypr/scripts"

get_volume() {
  volume=$(pamixer --get-volume)
  if [[ "$volume" -eq "0" ]]; then
    echo "Muted"
  else
    echo "$volume %"
  fi
}

get_icon() {
  current=$(get_volume)
  if [[ "$current" == "Muted" ]]; then
    echo "$icons_dir/volume-mute.png"
  elif [[ "${current%\%}" -le 30 ]]; then
    echo "$icons_dir/volume-low.png"
  elif [[ "${current%\%}" -le 60 ]]; then
    echo "$icons_dir/volume-mid.png"
  else
    echo "$icons_dir/volume-high.png"
  fi
}

notify_user() {
  if [[ "$(get_volume)" == "Muted" ]]; then
    notify-send -e -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(get_icon)" " Volume:" " Muted"
  else
    notify-send -e -h int:value:"$(get_volume | sed 's/%//')" -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(get_icon)" " Volume Level:" " $(get_volume)" &&
      "$scripts_dir/Sounds.sh" --volume
  fi
}

increase_volume() {
  if [ "$(pamixer --get-mute)" == "true" ]; then
    toggle_mute
  else
    pamixer -i 5 --allow-boost --set-limit 150 && notify_user
  fi
}

# Decrease Volume
decrease_volume() {
  if [ "$(pamixer --get-mute)" == "true" ]; then
    toggle_mute
  else
    pamixer -d 5 && notify_user
  fi
}

toggle_mute() {
  if [ "$(pamixer --get-mute)" == "false" ]; then
    pamixer -m && notify-send -e -u low -i "$icons_dir/volume-mute.png" " Mute"
  elif [ "$(pamixer --get-mute)" == "true" ]; then
    pamixer -u && notify-send -e -u low -i "$(get_icon)" " Volume:" " Switched ON"
  fi
}

toggle_mic() {
  if [ "$(pamixer --default-source --get-mute)" == "false" ]; then
    pamixer --default-source -m && notify-send -e -u low -i "$icons_dir/microphone-mute.png" " Microphone:" " Switched OFF"
  elif [ "$(pamixer --default-source --get-mute)" == "true" ]; then
    pamixer -u --default-source u && notify-send -e -u low -i "$icons_dir/microphone.png" " Microphone:" " Switched ON"
  fi
}

get_mic_icon() {
  current=$(pamixer --default-source --get-volume)
  if [[ "$current" -eq "0" ]]; then
    echo "$icons_dir/microphone-mute.png"
  else
    echo "$icons_dir/microphone.png"
  fi
}

get_mic_volume() {
  volume=$(pamixer --default-source --get-volume)
  if [[ "$volume" -eq "0" ]]; then
    echo "Muted"
  else
    echo "$volume %"
  fi
}

notify_mic_user() {
  volume=$(get_mic_volume)
  icon=$(get_mic_icon)
  notify-send -e -h int:value:"$volume" -h "string:x-canonical-private-synchronous:volume_notif" -u low -i "$icon" " Mic Level:" " $volume"
}

increase_mic_volume() {
  if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
    toggle_mic
  else
    pamixer --default-source -i 5 && notify_mic_user
  fi
}

decrease_mic_volume() {
  if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
    toggle-mic
  else
    pamixer --default-source -d 5 && notify_mic_user
  fi
}

if [[ "$1" == "--get" ]]; then
  get_volume
elif [[ "$1" == "--inc" ]]; then
  increase_volume
elif [[ "$1" == "--dec" ]]; then
  decrease_volume
elif [[ "$1" == "--toggle" ]]; then
  toggle_mute
elif [[ "$1" == "--toggle-mic" ]]; then
  toggle_mic
elif [[ "$1" == "--get-icon" ]]; then
  get_icon
elif [[ "$1" == "--get-mic-icon" ]]; then
  get_mic_icon
elif [[ "$1" == "--mic-inc" ]]; then
  increase_mic_volume
elif [[ "$1" == "--mic-dec" ]]; then
  decrease_mic_volume
else
  get_volume
fi

