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
yabai=$(realpath $(which yabai))
jq=$(realpath $(which jq))
osascript=$(realpath $(which osascript))
gcal=$(realpath $(which gcal))
toggle_sketchybar=$(realpath $(which toggle-sketchybar))
nightlight="${homebrewPath}/nightlight"
desktoppr=$(realpath $(which desktoppr))
wallpaper="/Users/Shared/Wallpaper/wallpaper-nix-colors.png"
blueutil=$(realpath $(which blueutil))