#!/bin/bash

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"
source "$HOME/.config/sketchybar/source_sketchybar.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

case "$1" in
    "toggle")
        $nowplaying_cli togglePlayPause
        ;;
    "next")
        $nowplaying_cli next
        ;;
    "previous")
        $nowplaying_cli previous
        ;;
esac
