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
yabai="${homebrewPath}/yabai"
jq="/run/current-system/sw/bin/jq"
osascript="/usr/bin/osascript"
