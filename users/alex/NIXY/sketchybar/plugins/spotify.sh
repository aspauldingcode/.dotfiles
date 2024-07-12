#!/bin/sh
#FIXME: https://github.com/FelixKratz/SketchyBar/discussions/12#discussioncomment-1455842
#Adds Spotify Player Controls

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

# Function to truncate or append "..." to a string based on length
truncate_or_append_ellipsis() {
  local text="$1"
  local max_length=31

  if [ ${#text} -gt $max_length ]; then
    echo "${text:0:$max_length}..."
  else
    echo "$text"
  fi
}

# Fetching and processing values
CURRENT_SONG=$(truncate_or_append_ellipsis "$(osascript -e 'tell application "Spotify" to return name of current track')")
CURRENT_ARTIST=$(truncate_or_append_ellipsis "$(osascript -e 'tell application "Spotify" to return artist of current track')")
CURRENT_ALBUM=$(truncate_or_append_ellipsis "$(osascript -e 'tell application "Spotify" to return album of current track')")
CURRENT_COVER=$(osascript -e 'tell application "Spotify" to return artwork url of current track')
DURATION_MS=$(truncate_or_append_ellipsis "$(osascript -e 'tell application "Spotify" to get duration of current track')")
DURATION=$((DURATION_MS / 1000))
FLOAT=$(truncate_or_append_ellipsis "$(osascript -e 'tell application "Spotify" to get player position')")
TIME=${FLOAT%.*}

# Download Album Cover
curl -s --max-time 20 "$CURRENT_COVER" -o /tmp/cover.jpg

detail_on() {
  sketchybar --animate tanh 30 --set spotify_label slider.width=$WIDTH
}

detail_off() {
  sketchybar --animate tanh 30 --set spotify_label slider.width=0
}

spotify_cover=(
  label.drawing=off
  icon.drawing=off
  padding_left=12
  padding_right=10
  background.image.scale=0.13
  background.image.drawing=on
  background.drawing=on
  background.image="/tmp/cover.jpg"
)

sketchybar --add item spotify.cover popup.spotify \
  --set spotify.cover "${spotify_cover[@]}"

spotify_title=(
  label.font="DejaVu Mono:Bold:15.0"
  label="$CURRENT_SONG"
  icon.drawing=off
  padding_left=0
  padding_right=0
  width=0
  y_offset=30
)

sketchybar --add item spotify.title popup.spotify \
  --set spotify.title "${spotify_title[@]}"

spotify_artist=(
  icon.drawing=off
  y_offset=7
  padding_left=0
  padding_right=0
  width=0
  label.font="JetBrains Mono:Italic:14.0"
  label="$CURRENT_ARTIST"
)

sketchybar --add item spotify.artist popup.spotify \
  --set spotify.artist "${spotify_artist[@]}"

spotify_album=(
  icon.drawing=off
  padding_left=0
  padding_right=0
  y_offset=-25
  width=0
  label.font="JetBrains Mono:Bold:11.0"
  label="$CURRENT_ALBUM"
  background.padding_right=235
)

sketchybar --add item spotify.album popup.spotify \
  --set spotify.album "${spotify_album[@]}"

sketchybar --set spotify_label label="$CURRENT_SONG"

# Handle mouse events
case "$SENDER" in
  "mouse.entered")
    #sleep 1
    sketchybar --set $NAME popup.drawing=on
    #echo "Mouse Hovered in $NAME icon" >> /tmp/sketchybar_debug.log
    ;;
  "mouse.exited" | "mouse.exited.global")
    sketchybar --set $NAME popup.drawing=off
    #echo "Mouse left hover of $NAME icon" >> /tmp/sketchybar_debug.log
    ;;
  "mouse.clicked")
    #sketchybar --set $NAME popup.drawing=toggle
    #echo "Mouse clicked on $NAME icon" >> /tmp/sketchybar_debug.log
    # toggle_battery_popup
    ;;
  "routine")
    # Update plugin info periodically
    
    ;;
esac
