#!/bin/sh

source "$HOME/.config/sketchybar/colors.sh"

# Assuming $SID is the index of the workspace in the array
ACTIVE=$(yabai -m query --spaces --space $SID | jq '.index')

sketchybar --set $NAME icon.highlight=$SELECTED icon.highlight_color=$ORANGE

# FIXME: Set font style to Bold or Regular for the current space
# sketchybar --set ${NAME[$ACTIVE]} font.style="Bold"