#!/bin/bash

POPUP_OFF="sketchybar --set apple.logo popup.drawing=off"
POPUP_CLICK_SCRIPT="sketchybar --set \$NAME popup.drawing=toggle"

current_day=$(date '+%e')

# Function to set date and time
function set_date_and_time {
  sketchybar --set $NAME label="$(date '+%a, %b %d   %r')"
  sketchybar --set $NAME icon=$TIME
}

# Define title line with bold font and space between month and day
row_1=(
  label="︳  $(date '+%B %e %Y')    |"
  label.font="JetBrains Mono:Bold:12.0"
  padding_left=-10
  padding_right=-10
  icon.drawing=off
  width=0
  y_offset=56
)
sketchybar --add item datetime.popup.title popup.datetime \
  --set datetime.popup.title "${row_1[@]}" \

# Define rows with updated LINE variables
cal_output=$(cal -h | sed -e "s/\b$current_day\b/\\033[1m$current_day\\033[0m/")
row_2=(
  label="︳$(echo "$cal_output" | sed -n '2p') |"
  label.font="JetBrains Mono:Regular:12.0"
  icon.drawing=off
  padding_left=0
  padding_right=0
  width=0
  y_offset=40
)
sketchybar --add item datetime.popup.cal_2 popup.datetime \
  --set datetime.popup.cal_2 "${row_2[@]}" 

row_3=(
  label="︳$(echo "$cal_output" | sed -n '3p') |"
  label.font="JetBrains Mono:Regular:12.0"
  icon.drawing=off
  padding_left=0
  padding_right=0
  width=0
  y_offset=24
)
sketchybar --add item datetime.popup.cal_3 popup.datetime \
  --set datetime.popup.cal_3 "${row_3[@]}" \

row_4=(
  label="︳$(echo "$cal_output" | sed -n '4p') |"
  label.font="JetBrains Mono:Regular:12.0"
  icon.drawing=off
  padding_left=0
  padding_right=0
  width=0
  y_offset=8
)
sketchybar --add item datetime.popup.cal_4 popup.datetime \
  --set datetime.popup.cal_4 "${row_4[@]}" \

row_5=(
  label="︳$(echo "$cal_output" | sed -n '5p') |"
  label.font="JetBrains Mono:Regular:12.0"
  icon.drawing=off
  padding_left=0
  padding_right=0
  width=0
  y_offset=-8
)
sketchybar --add item datetime.popup.cal_5 popup.datetime \
  --set datetime.popup.cal_5 "${row_5[@]}" \

row_6=(
  label="︳$(echo "$cal_output" | sed -n '6p') |"
  label.font="JetBrains Mono:Regular:12.0"
  icon.drawing=off
  padding_left=0
  padding_right=0
  width=0
  y_offset=-24
)
sketchybar --add item datetime.popup.cal_6 popup.datetime \
  --set datetime.popup.cal_6 "${row_6[@]}" \

row_7=(
  label="︳$(echo "$cal_output" | sed -n '7p') |"
  label.font="JetBrains Mono:Regular:12.0"
  width=150
  icon.drawing=off
  padding_left=0
  padding_right=0
  width=0
  y_offset=-40
)
sketchybar --add item datetime.popup.cal_7 popup.datetime \
  --set datetime.popup.cal_7 "${row_7[@]}" \

row_8=(
  label="︳$(echo "$cal_output" | sed -n '8p') |"
  label.font="JetBrains Mono:Regular:12.0"
  icon.drawing=off
  padding_left=0
  padding_right=10
  width=0
  y_offset=-56
  background.padding_right=185
)
sketchybar --add item datetime.popup.cal_8 popup.datetime \
  --set datetime.popup.cal_8 "${row_8[@]}" \

# Main execution
set_date_and_time
:w

