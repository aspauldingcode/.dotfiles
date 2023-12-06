#!/bin/bash

# Sourcing color and icon configurations
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

function set_date_and_time {
  sketchybar --set $NAME label="$(date '+%a, %b %d   %r')"
  sketchybar --set $NAME icon=$TIME
}

function set_calendar_popup {
  # Capture the output of the cal command
  cal_output=$(cal -h)

  # Split the output into an array of lines
  IFS=$'\n' read -r -d '' -a calendar_lines <<< "$cal_output"

  # Construct Sketchybar options dynamically for each line
  sketchybar_options=()
  for ((i=0; i<${#calendar_lines[@]}; i++)); do
    line=${calendar_lines[$i]}
    # Add each line to the Sketchybar options
    sketchybar_options+=(
      --add item datetime.popup.popup_line_$i popup.datetime \
      --set datetime.popup.popup_line_$i label=$(echo "$line" | tr ' ' '‎') \
      #--set datetime.popup.popup_line_$i label=$(echo "$line") \ 
      --set datetime.popup.popup_line_$i label.padding_left=10 \
      --set datetime.popup.popup_line_$i label.padding_right=10 \
      --set datetime.popup.popup_line_$i label.font=\"DejaVu Mono:Regular:12.0\" \
    )
  done

  # Add the Sketchybar items with the constructed options for each line
  sketchybar_options_str=$(IFS=' '; echo "${sketchybar_options[*]}")
  sketchybar $sketchybar_options_str
}

# Main execution
set_date_and_time
set_calendar_popup
