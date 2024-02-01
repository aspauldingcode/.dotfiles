#!/bin/bash

# CALENDAR=$(gcal --starting-day=1 | sed 's/<\([^>]*\)>/ \1 /g')
CALENDAR=$(gcal --starting-day=1 | sed -e 's|<|\[|g' -e 's|>|\]|g')
# CALENDAR=$(gcal --starting-day=1 | sed -n '1,4p')


LINE_1="︳$(echo "$CALENDAR" | sed -n '2p') |"
LINE_2="︳$(echo "$CALENDAR" | sed -n '3p') |"
LINE_3="︳$(echo "$CALENDAR" | sed -n '4p') |"
LINE_4="︳$(echo "$CALENDAR" | sed -n '5p') |"
LINE_5="︳$(echo "$CALENDAR" | sed -n '6p') |"
LINE_6="︳$(echo "$CALENDAR" | sed -n '7p') |"
LINE_7="︳$(echo "$CALENDAR" | sed -n '8p') |"
LINE_8="︳$(echo "$CALENDAR" | sed -n '9p') |"

declare -a lines=(
  "$LINE_1"
  "$LINE_2"
  "$LINE_3"
  "$LINE_4"
  "$LINE_5"
  "$LINE_6"
  "$LINE_7"
  "$LINE_8"
)

for (( i = 0; i < ${#lines[@]}; i++ )); do
  current_line="${lines[$i]}"
  # Check if the line is not empty and contains at least one non-space character
  if [[ -n "${lines[$i+1]}" && "${lines[$i+1]}" =~ [^[:space:]] ]]; then #FIXME: CURRENTLY NOT WORKING!
    row=(
      label="$current_line"
      label.font="JetBrains Mono:Regular:12.0"
      icon.drawing=off
      padding_left=0
      padding_right=0
      width=0
      y_offset=$(( 56 - 16 * i ))
    )
    
    item_name="datetime.popup.cal_$((i+1))"
    sketchybar --add item "$item_name" popup.datetime --set "$item_name" "${row[@]}"
  fi
done

sketchybar --set "$item_name" background.padding_right=185