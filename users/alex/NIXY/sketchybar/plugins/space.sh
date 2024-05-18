#!/bin/sh

source "$HOME/.config/sketchybar/colors.sh"

ACTIVE=$(yabai -m query --spaces --space | jq '.index') #When ignore-association=on!
sketchybar --set $NAME icon.highlight=$SELECTED icon.highlight_color=$ORANGE