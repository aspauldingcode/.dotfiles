#!/bin/sh

arch=$(uname -m)
if [ "$arch" = "arm64" ]; then
    homebrewPath="/opt/homebrew/bin"
elif [ "$arch" = "x86_64" ]; then
    homebrewPath="/usr/local/bin"
else
    exit 1
fi

# define software fullpaths
yabai=$(which yabai)
jq=$(which jq)
osascript=$(which osascript)
gcal=$(which gcal)
toggle_sketchybar=$(which toggle-sketchybar)
nightlight="${homebrewPath}/nightlight"