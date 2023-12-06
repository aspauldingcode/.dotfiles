#!/bin/sh

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

#sketchybar --set $NAME label="$(date '+%a, %b %d')" # DATE

sketchybar --set $NAME label="$(date '+%a, %b %d   %H:%M:%S')"
sketchybar --set $NAME icon=$TIME

calendar_popup=(
  icon=$TIME
  icon.padding_left=10
  label="Adding calendar here! $(date '+%H:%M:%S')"
  label.padding_left=10
  label.padding_right=10
  label.font="DejaVu Mono:Bold:12.0"
  height=200
  #label.align=center
  blur_radius=100
)

sketchybar --add item datetime.popup popup.datetime \
  --set datetime.popup "${calendar_popup[@]}"
