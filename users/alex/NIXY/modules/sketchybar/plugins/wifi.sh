#!/bin/sh

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/source_sketchybar.sh"
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"
CURRENT_WIFI="$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I)"
SSID="$(printf "%s" "$CURRENT_WIFI" | grep -o "SSID: .*" | sed 's/^SSID: //')"
CURR_TX="$(printf "%s" "$CURRENT_WIFI" | grep -o "lastTxRate: .*" | sed 's/^lastTxRate: //')"
POPUP_OFF="$SKETCHYBAR_EXEC --set wifi.ssid popup.drawing=off && $SKETCHYBAR_EXEC --set wifi.speed popup.drawing=off"
WIFI_INTERFACE=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
WIFI_POWER=$(networksetup -getairportpower $WIFI_INTERFACE | awk '{print $4}')

# Get the second IP address line REQUIRES iproute2mac HOMEBREW!
IP_ADDR="$(ip addr show dev en0 | awk '/inet / {print $2}')"

#IP_ADDR=$(ipconfig getifaddr $WIFI_INTERFACE)

ssid=(
  icon=$NETWORK
  icon.padding_left=10
  label="$SSID"
  label.font="DejaVu Mono:Bold:12.0"
  label.padding_left=10
  label.padding_right=10
  blur_radius=100
  sticky=on
  update_freq=100
  click_script="open /System/Library/PreferencePanes/Network.prefPane/; $POPUP_OFF"
)

$SKETCHYBAR_EXEC --add item wifi.ssid popup.wifi \
  --set wifi.ssid "${ssid[@]}"

ip=(
  icon=$IP
  icon.padding_left=10
  label="$IP_ADDR"
  label.font="DejaVu Mono:Bold:12.0"
  label.padding_left=10
  label.padding_right=10
  blur_radius=100
  sticky=on
  click_script="open /System/Library/PreferencePanes/Network.prefPane/; $POPUP_OFF"
)

$SKETCHYBAR_EXEC --add item wifi.ip popup.wifi \
  --set wifi.ip "${ip[@]}"

speed=(
  icon=$SPEED
  icon.padding_left=10
  label.font="DejaVu Mono:Bold:12.0"
  label.padding_left=10
  label.padding_right=10
  blur_radius=100
  sticky=on
  update_freq=10
  width=125
  script="$PLUGIN_DIR/speed.sh"
)

$SKETCHYBAR_EXEC --add item wifi.speed popup.wifi \
  --set wifi.speed "${speed[@]}"

if [ ! -f /tmp/sketchybar_wifi ]; then
  touch /tmp/sketchybar_wifi
fi

if [ ! -f /tmp/sketchybar_speed ]; then
  (
    COUNTER=0
    END_TIME=$(($(date +%s) + 9))
    while [ $(date +%s) -lt $END_TIME ]; do
      case $COUNTER in
      0) LABEL="Loading." ;;
      1) LABEL="Loading.." ;;
      2) LABEL="Loading..." ;;
      esac
      $SKETCHYBAR_EXEC --set wifi.speed icon="$LABEL"
      sleep 1
      COUNTER=$(((COUNTER + 1) % 3))
    done
  ) &
fi

if [ "$WIFI_POWER" == "Off" ]; then
  $SKETCHYBAR_EXEC --set $NAME icon=$WIFI_OFF
  exit 0
fi

SSID_LOWER=$(echo "$SSID" | tr '[:upper:]' '[:lower:]')
if [[ "$SSID_LOWER" == *iphone* ]]; then
  $SKETCHYBAR_EXEC --set $NAME icon=$HOTSPOT
  exit 0
fi

if [ $CURR_TX = 0 ]; then
  $SKETCHYBAR_EXEC --set $NAME icon=$WIFI_NO_INTERNET
  exit 0
fi

$SKETCHYBAR_EXEC --set $NAME icon=$WIFI

# Handle mouse events
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
    # button clicked effect
    $SKETCHYBAR_EXEC --set $NAME icon.highlight_color=$base04 label.highlight_color=$base04
    $SKETCHYBAR_EXEC --set $NAME icon.highlight_color=$base07 label.highlight_color=$base07
    $SKETCHYBAR_EXEC --set $NAME icon.highlight=off label.highlight=off popup.drawing=off
    ;;
  "routine")
    # Update battery info periodically
    # update_battery
    ;;
esac
