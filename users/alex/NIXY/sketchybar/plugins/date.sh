#!/bin/bash

# Sourcing color and icon configurations
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

POPUP_OFF="sketchybar --set apple.logo popup.drawing=off"
POPUP_CLICK_SCRIPT="sketchybar --set \$NAME popup.drawing=toggle"


function set_date_and_time {
  sketchybar --set $NAME label="$(date '+%a, %b %d   %r')"
  sketchybar --set $NAME icon=$TIME
}
title=(
  label.y_offset=0
  label.padding_left=10
  label.padding_right=10
  label.font="DejaVu Mono:Bold:16.0"
  icon.font="DejaVu Mono:Regular:14.0"
  icon.padding_left=10
  height=10
  background.margin=25
  blur_radius=100
  width=175
)

content=(
  label.y_offset=0
  label.padding_left=10
  label.padding_right=10
  label.font="DejaVu Mono:Bold:12.0"
  icon.font="DejaVu Mono:Regular:14.0"
  icon.padding_left=10
  height=10
  background.margin=25
  blur_radius=100
  width=175
)

# Main execution
set_date_and_time

sketchybar --add item datetime.popup.title popup.datetime \
  --set datetime.popup.title label="$(cal -h | sed -n '1p' )" "${title[@]}" \
  icon=$TIME "${title[@]}" \
  \
  --add item datetime.popup.row_2 popup.datetime \
  --set datetime.popup.row_2 label="$(cal -h | sed -n '2p')" "${content[@]}" \
  \
  --add item datetime.popup.row_3 popup.datetime \
  --set datetime.popup.row_3 label="$(cal -h | sed -n '3p')" "${content[@]}" \
  \
  --add item datetime.popup.row_4 popup.datetime \
  --set datetime.popup.row_4 label="$(cal -h | sed -n '4p')" "${content[@]}" \
  \
  --add item datetime.popup.row_5 popup.datetime \
  --set datetime.popup.row_5 label="$(cal -h | sed -n '5p')" "${content[@]}" \
  \
  --add item datetime.popup.row_6 popup.datetime \
  --set datetime.popup.row_6 label="$(cal -h | sed -n '6p')" "${content[@]}" \
  \
  --add item datetime.popup.row_7 popup.datetime \
  --set datetime.popup.row_7 label="$(cal -h | sed -n '7p')" "${content[@]}" \
  \
  --add item datetime.popup.row_8 popup.datetime \
  --set datetime.popup.row_8 label="$(cal -h | sed -n '8p')" "${content[@]}" \
