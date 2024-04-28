#!/bin/sh

source "$HOME/.config/sketchybar/colors.sh"

# Assuming $SID is the index of the workspace in the array
#ACTIVE=$(yabai -m query --spaces --space $SID | jq '.index') #WHEN ignore-association=off!
ACTIVE=$(yabai -m query --spaces --has-focus $SID | jq '.index') #When ignore-association=on!


# Store the output of the print-spaces command in a variable
# active_spaces=$(print-spaces)

# Loop through each space in the output
# for space in $active_spaces; do
#     echo "Active space: $space"
# done

sketchybar --set $NAME icon.highlight=$SELECTED icon.highlight_color=$ORANGE

# FIXME: Set font style to Bold or Regular for the current space
# sketchybar --set ${NAME[$ACTIVE]} font.style="Bold"

