#!/bin/bash

# I like to source my colors, to reference them automatically in a colorScheme switch. 
source "$HOME/.config/sketchybar/colors.sh"

# Calendar output with gcal. MUST INSTALL gcal! requires awk and sed. 
CALENDAR=$(gcal | awk '{printf "%-21s\n", $0}' | sed -e 's|<|\[|g' -e 's|>|\]|g' | sed -e '/^$/d' | sed -e 's/\]$/&/' -e '/\]$/!s/$/ /')

LINE_1="| $(echo "$CALENDAR" | sed -n '2p') |"
LINE_2="| $(echo "$CALENDAR" | sed -n '3p') |"
LINE_3="| $(echo "$CALENDAR" | sed -n '4p') |"
LINE_4="| $(echo "$CALENDAR" | sed -n '5p') |"
LINE_5="| $(echo "$CALENDAR" | sed -n '6p') |"
LINE_6="| $(echo "$CALENDAR" | sed -n '7p') |"
LINE_7="| $(echo "$CALENDAR" | sed -n '8p') |"
LINE_8="| $(echo "$CALENDAR" | sed -n '9p') |"

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
  if [[ -n "${lines[$i]}" && "${lines[$i]}" =~ [^[:space:]] ]]; then
    row=(
      icon="$current_line"
      icon.padding_left=-3                    # set to -3 to hide behind border.
      icon.font="JetBrains Mono:Regular:12.0" # Non-negotiable!
      label.font="JetBrains Mono:Bold:12.0"   # Non-negotiable! 
      padding_left=0
      padding_right=0
      width=0
      y_offset=$(( 56 - 16 * i ))
      label="|"
      label.color=$GREY                       # Set this to your popup border color. Must be 2px at least!
      label.padding_left=-182                 # To overwrite the '|' character on the left of the line. Fixes graphical text issues. 
      label.drawing=on
    )
    item_name="datetime.popup.cal_$((i+1))"
    sketchybar --add item "$item_name" popup.datetime --set "$item_name" "${row[@]}"
  fi
done

sketchybar --set "$item_name" background.padding_right=185

# Function to set date and time
function set_date_and_time {
  sketchybar --set $NAME label="$(date '+%a, %b %d  %I:%M %p')"
  sketchybar --set $NAME icon=$TIME
}

set_date_and_time # call it first

# Handle mouse events
case "$SENDER" in
  "mouse.entered")
    sketchybar --set $NAME popup.drawing=on
    #echo "Mouse Hovered in $NAME icon" >> /tmp/sketchybar_debug.log
    ;;
  "mouse.exited" | "mouse.exited.global")
    sketchybar --set $NAME popup.drawing=off
    #echo "Mouse left hover of $NAME icon" >> /tmp/sketchybar_debug.log
    ;;
  "mouse.clicked")
    sketchybar --set $NAME popup.drawing=toggle
    #echo "Mouse clicked on $NAME icon" >> /tmp/sketchybar_debug.log
    ;;
esac
