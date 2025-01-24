#!/bin/bash

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/source_sketchybar.sh"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

# File to store the calendar output and the date it was generated
CACHE_FILE="$HOME/.config/sketchybar/calendar_cache"

# Flag file to indicate whether the function has been called
INIT_FLAG_FILE="$HOME/.config/sketchybar/calendar_init_flag"

# Function to generate the calendar
generate_calendar() {
  CALENDAR=$($gcal | awk '{printf "%-21s\n", $0}' | sed -e 's|<|\[|g' -e 's|>|\]|g' | sed -e '/^$/d' | sed -e 's/\]$/&/' -e '/\]$/!s/$/ /')
  echo "$(date +%Y-%m-%d)" > "$CACHE_FILE"
  echo "$CALENDAR" >> "$CACHE_FILE"
}

# Function to initialize the popup items
initialize_popup_items() {
  # Read the cached calendar data
  CALENDAR=$(tail -n +2 "$CACHE_FILE")

  declare -a lines=(
    "| $(echo "$CALENDAR" | sed -n '2p') |"
    "| $(echo "$CALENDAR" | sed -n '3p') |"
    "| $(echo "$CALENDAR" | sed -n '4p') |"
    "| $(echo "$CALENDAR" | sed -n '5p') |"
    "| $(echo "$CALENDAR" | sed -n '6p') |"
    "| $(echo "$CALENDAR" | sed -n '7p') |"
    "| $(echo "$CALENDAR" | sed -n '8p') |"
    "| $(echo "$CALENDAR" | sed -n '9p') |"
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
        label.color=$base07                       # Set this to your popup border color. Must be 2px at least!
        label.padding_left=-182                 # To overwrite the '|' character on the left of the line. Fixes graphical text issues. 
        label.drawing=on
      )
      item_name="datetime.popup.cal_$((i+1))"
      $SKETCHYBAR_EXEC --add item "$item_name" popup.datetime --set "$item_name" "${row[@]}"
    fi
  done

  $SKETCHYBAR_EXEC --set "$item_name" background.padding_right=185
  echo "initialized" > "$INIT_FLAG_FILE"
}

# Check if cache file exists and if it's up-to-date
if [[ -f "$CACHE_FILE" ]]; then
  LAST_UPDATE=$(head -n 1 "$CACHE_FILE")
  TODAY=$(date +%Y-%m-%d)
  if [[ "$LAST_UPDATE" != "$TODAY" ]]; then
    generate_calendar
  fi
else
  generate_calendar
fi

# Initialize the popup items if not already done
if [[ ! -f "$INIT_FLAG_FILE" ]]; then
  initialize_popup_items
fi

# Function to set date and time
function set_date_and_time {
  $SKETCHYBAR_EXEC --set $NAME label="$(date '+%a, %b %d  %I:%M %p')"
  $SKETCHYBAR_EXEC --set $NAME icon=$DATE
}

set_date_and_time # call it first

# Handle mouse events
case "$SENDER" in
  "mouse.entered")
    # popup effect
    $SKETCHYBAR_EXEC --set $NAME popup.drawing=on

    # highlight effect
    $SKETCHYBAR_EXEC --set $NAME icon.highlight=on label.highlight=on icon.highlight_color=$base07 label.highlight_color=$base07
    ;;
  "mouse.exited" | "mouse.exited.global")
    $SKETCHYBAR_EXEC --set $NAME popup.drawing=off
    
    # unhighlight effect
    $SKETCHYBAR_EXEC --set $NAME icon.highlight=off label.highlight=off
    ;;
  "mouse.clicked")
    open https://calendar.google.com/calendar/u/oldstrumpet321@gmail.com/r/month
    
    # button clicked effect
    $SKETCHYBAR_EXEC --set $NAME icon.highlight_color=$base04 label.highlight_color=$base04
    $SKETCHYBAR_EXEC --set $NAME icon.highlight_color=$base07 label.highlight_color=$base07
    $SKETCHYBAR_EXEC --set $NAME icon.highlight=off label.highlight=off popup.drawing=off
    ;;
esac
