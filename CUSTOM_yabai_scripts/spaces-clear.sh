#!/bin/bash

# count all spaces.
# all=length(spaces)
max_spaces=$(yabai -m query --spaces | jq 'max_by(.index) | .index')

# Query for the highest space containing a window
lastwindow=$(yabai -m query --spaces | jq '[.[] | select(.windows | length > 0) | .index] | max')

# remaining=max_spaces - last space with a window
remaining=$((max_spaces - lastwindow))

# from last to
for ((i=1; i<=$remaining; i++))
do
    yabai -m space $(($lastwindow + 1)) --destroy
done
