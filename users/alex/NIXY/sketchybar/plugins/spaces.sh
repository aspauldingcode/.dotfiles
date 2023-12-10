#!/bin/sh

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

ACTIVE_SPACE=$(yabai -m query --spaces --space | jq '.index')
CURRENT_APP_IN_SPACE=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')

space_bg=(
  background.color=$SPACEBG
  background.height=19
  background.corner_radius=50
)

space_popup=(
  #icon.padding_left=10
  label.font="DejaVu Mono:Bold:12.0"
  label.padding_left=10
  label.padding_right=10
  blur_radius=100
  sticky=on
)

for i in "${!SPACE_ICONS[@]}"; do
  sid=$(($i + 1))
  if [[ $sid -eq $ACTIVE_SPACE ]]; then
    sketchybar --set space.$sid "${space_bg[@]}"
  else
    sketchybar --set space.$sid background.color=$TEMPUS
  fi

  #sketchybar --set space.$sid icon="$CURRENT_ICON"
  #sketchybar --set current_space icon=${CURRENT_SPACE_ICONS[$(($ACTIVE_SPACE - 1))]}
  # sketchybar --set space label="$CURRENT_APP_IN_SPACE" \
  #  icon=${CURRENT_SPACE_ICONS[$(($ACTIVE_SPACE - 1))]}
done
