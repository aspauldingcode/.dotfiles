# AUDIO VISUALIZER:
# https://github.com/FelixKratz/SketchyBar/discussions/12#discussioncomment-6224928

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/source_sketchybar.sh"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

#kill cava if there is more than 1 instance running.
cava_count=$(pgrep cava | wc -l)
if [ "$cava_count" -gt 1 ]; then
  sudo pkill -9 -f cava
fi

# open Background Music if it is not open.
if ! pgrep BackgroundMusic > /dev/null; then
  nohup open -g -a "Background Music" >/dev/null 2>&1 &
fi

if ! pgrep cava > /dev/null; then
  $cava -p $PLUGIN_DIR/cava.conf | sed -u 's/ //g; s/0/▁/g; s/1/▂/g; s/2/▃/g; s/3/▄/g; s/4/▅/g; s/5/▆/g; s/6/▇/g; s/7/█/g; s/8/█/g' | while read -r line; do
    $SKETCHYBAR_EXEC --set cava label="$line" label.font="Droid Sans Mono for Powerline:Regular:12.0"
  done
fi

# Check which app is currently playing media
PLAYING_APP=$(osascript -e '
  tell application "System Events"
    set mediaApps to {"Spotify", "Music", "Safari", "Firefox", "Chrome"}
    repeat with appName in mediaApps
      if application appName is running then
        tell application appName
          if playing then
            return name
          end if
        end tell
      end if
    end repeat
    return ""
  end tell
')

# Only fetch Spotify cover if Spotify is playing
if [[ "$PLAYING_APP" == "Spotify" ]]; then
  spotify_cover_url=$(osascript -e 'tell application "Spotify" to return artwork url of current track')
  curl -s --max-time 20 "$spotify_cover_url" -o /tmp/now_playing.jpg

  # Define popup properties for Spotify album cover
  cover_popup=(
    $NAME.cover label.drawing=off
    icon.drawing=off
    padding_left=12
    padding_right=10
    background.image.scale=0.13
    background.image.drawing=on
    background.drawing=on
    background.image="/tmp/now_playing.jpg"
  )

  # Use update command to set the cover popup
  $SKETCHYBAR_EXEC --add item $NAME.cover popup.$NAME --set "${cover_popup[@]}"
fi

# Function to update cava popups with now playing information
update_cava_popups() {
  # Get raw now playing info and parse it
  raw_info=$($nowplaying_cli get-raw)

  if [ -z "$raw_info" ]; then
    # If nothing is playing, set default messages
    title="Nothing is currently playing"
    album=""
    artist=""
  else
    # Parse the raw info and check for empty strings
    title=$(echo "$raw_info" | grep "kMRMediaRemoteNowPlayingInfoTitle" | sed 's/.*= "\(.*\)";/\1/')
    album=$(echo "$raw_info" | grep "kMRMediaRemoteNowPlayingInfoAlbum" | sed 's/.*= "\(.*\)";/\1/')
    # Fix artist parsing by removing key/pair format and replacing \U2024 with period
    artist=$(echo "$raw_info" | grep "kMRMediaRemoteNowPlayingInfoArtist" | sed 's/.*= "\(.*\)";/\1/' | sed 's/^.*= //g' | sed 's/\\U2024/./g')
    
    # Clear variables if they're empty strings
    [ "$album" = '""' ] && album=""
    [ "$title" = '""' ] && title=""
    [ "$artist" = '""' ] && artist=""
    
    # Get duration and elapsed time for progress info
    duration=$(echo "$raw_info" | grep "kMRMediaRemoteNowPlayingInfoDuration" | sed 's/.*= "\(.*\)";/\1/')
    elapsed=$(echo "$raw_info" | grep "kMRMediaRemoteNowPlayingInfoElapsedTime" | sed 's/.*= "\(.*\)";/\1/')
    
    # Calculate progress percentage
    if [ ! -z "$duration" ] && [ ! -z "$elapsed" ]; then
      progress=$(echo "scale=2; ($elapsed/$duration) * 100" | bc)
      progress_info="Progress: ${progress}%"
    else
      progress_info=""
    fi
  fi

  # Define separate popup properties for media info
  title_popup=(
    $NAME.title label="Title: $title"
    icon.padding_left=10
    label.padding_left=8
    label.padding_right=10
    height=10
    blur_radius=100
  )

  album_popup=(
    $NAME.album label="Album: $album"
    icon.padding_left=10
    label.padding_left=8
    label.padding_right=10
    height=10
    blur_radius=100
  )

  artist_popup=(
    $NAME.artist label="Artist: $artist"
    icon.padding_left=10
    label.padding_left=8
    label.padding_right=10
    height=10
    blur_radius=100
  )

  progress_popup=(
    $NAME.progress label="$progress_info"
    icon.padding_left=10
    label.padding_left=8
    label.padding_right=10
    height=10
    blur_radius=100
  )

  # Only add popups for non-empty values
  [ ! -z "$title" ] && $SKETCHYBAR_EXEC --add item $NAME.title popup.$NAME --set "${title_popup[@]}"
  [ ! -z "$album" ] && $SKETCHYBAR_EXEC --add item $NAME.album popup.$NAME --set "${album_popup[@]}"
  [ ! -z "$artist" ] && $SKETCHYBAR_EXEC --add item $NAME.artist popup.$NAME --set "${artist_popup[@]}"
  [ ! -z "$progress_info" ] && $SKETCHYBAR_EXEC --add item $NAME.progress popup.$NAME --set "${progress_popup[@]}"
}

# Update cava popups
update_cava_popups

# Handle mouse events for hover status
case "$SENDER" in
  "mouse.entered")
    $SKETCHYBAR_EXEC --set $NAME popup.drawing=on
   
    # highlight effect
    $SKETCHYBAR_EXEC --set $NAME icon.highlight=on label.highlight=on icon.highlight_color=$base07 label.highlight_color=$base07
    ;;
  "mouse.exited" | "mouse.exited.global")
    $SKETCHYBAR_EXEC --set $NAME popup.drawing=off
    
    # unhighlight effect
    $SKETCHYBAR_EXEC --set $NAME icon.highlight=off label.highlight=off
    ;;
  "mouse.clicked")
    # clicked effect
    $SKETCHYBAR_EXEC --set $NAME icon.highlight_color=$base04 label.highlight_color=$base04
    $SKETCHYBAR_EXEC --set $NAME icon.highlight_color=$base07 label.highlight_color=$base07
    $SKETCHYBAR_EXEC --set $NAME icon.highlight=off label.highlight=off popup.drawing=off
    ;;
esac
