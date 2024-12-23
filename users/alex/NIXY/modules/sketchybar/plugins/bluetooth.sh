#!/bin/bash

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"
source "$PLUGIN_DIR/detect_arch_and_source_homebrew_packages.sh"

# Default Bluetooth icon and status
GLOBAL_ICON="$BLUETOOTH_UNKNOWN"
GLOBAL_STATUS="unknown"

get_global_power_status() {
  if [ "$($blueutil -p)" -eq 0 ]; then
    GLOBAL_STATUS="Bluetooth (off)"
    GLOBAL_ICON="$BLUETOOTH_OFF"
  else
    GLOBAL_STATUS="Bluetooth (on)"
    GLOBAL_ICON="$BLUETOOTH_ON"
  fi
}

get_device_power_status() {
  $blueutil --paired --format json-pretty | $jq -r '.[] | select(.address == "'"$1"'") | .connected'
}

get_device_connection_status() {
  $blueutil --paired --format json-pretty | $jq -r '.[] | select(.address == "'"$1"'") | .connected'
}

get_device_mac() {
  $blueutil --paired --format json-pretty | $jq -r '.[] | select(.address == "'"$1"'") | .address'
}

get_device_name() {
  $blueutil --paired --format json-pretty | $jq -r '.[] | select(.address == "'"$1"'") | .name'
}

list_discovered_devices() {
  $blueutil --inquiry --format json-pretty
}

list_paired_devices() {
  $blueutil --paired --format json-pretty
}

# Function to set the global Bluetooth power status
# Usage: set_global_power_status <status>
# <status>: "on" to turn Bluetooth on, "off" to turn it off
set_global_power_status() {
  if [ "$1" == "on" ]; then
    $blueutil -p 1
  else
    $blueutil -p 0
  fi
}

# Function to set the connection status of a Bluetooth device
# Usage: set_device_connection_status <device_address> <connection_status>
# <device_address>: The MAC address of the Bluetooth device
# <connection_status>: "true" to connect, "false" to disconnect
set_device_connection_status() {
  local device_address="$1"
  local connection_status="$2"
  
  if [ "$connection_status" == "true" ]; then
    $blueutil --connect "$device_address"
  else
    $blueutil --disconnect "$device_address"
  fi
}

# Function to update bluetooth display
update_bluetooth() {
    # Get global power status
    get_global_power_status
    
    # Get discoverable status
    local discoverable=$($blueutil --discoverable)
    local global_status_text="$GLOBAL_STATUS"
    if [ "$GLOBAL_STATUS" = "Bluetooth (on)" ]; then
        if [ "$discoverable" -eq 1 ]; then
            global_status_text="Bluetooth (on, Discoverable)"
        else
            global_status_text="Bluetooth (on)"
        fi
    fi
    
    # Update the main bluetooth icon and status
    sketchybar --set $NAME icon="$GLOBAL_ICON"

    # Create/update global status popup item
    sketchybar --add item "global_status" popup.$NAME \
        --set "global_status" \
        label="$global_status_text" \
        icon="$GLOBAL_ICON" \
        icon.padding_left=10 \
        label.padding_left=8 \
        label.padding_right=10 \
        height=20 \
        blur_radius=100

    # Get list of all paired devices and create individual popup items
    while IFS= read -r device; do
        if [ ! -z "$device" ]; then
            local mac=$(echo "$device" | $jq -r '.address')
            local name=$(echo "$device" | $jq -r '.name')
            local connected=$(echo "$device" | $jq -r '.connected')
            local status="disconnected, paired"
            local device_icon="$BLUETOOTH_UNKNOWN"
            
            if [ "$connected" = "true" ]; then
                status="connected, paired"
                device_icon="$BLUETOOTH_CONNECTED"
            else
                device_icon="$BLUETOOTH_DISCONNECTED"
            fi
            
            # Create/update popup item for this device
            sketchybar --add item "$mac" popup.$NAME \
                --set "$mac" \
                label="$name ($mac) - $status" \
                icon="$device_icon" \
                icon.padding_left=10 \
                label.padding_left=8 \
                label.padding_right=10 \
                height=20 \
                blur_radius=100
        fi
    done < <($blueutil --paired --format json-pretty | $jq -c '.[]')
}

discover_devices() {
    # Run inquiry and filter out timestamp logs, keeping only the JSON output
    local discovered=$($blueutil --inquiry --format json-pretty | grep -v "blueutil\|IOBluetoothDeviceInquiry" | jq -c '.[]')
    
    while IFS= read -r device; do
        if [ ! -z "$device" ]; then
            local mac=$(echo "$device" | $jq -r '.address')
            local name=$(echo "$device" | $jq -r '.name')
            local connected=$(echo "$device" | $jq -r '.connected')
            local paired=$(echo "$device" | $jq -r '.paired')
            local status="discovered"
            local device_icon="$BLUETOOTH_SCANNING"
            
            if [ "$paired" = "true" ]; then
                if [ "$connected" = "true" ]; then
                    status="connected, paired"
                    device_icon="$BLUETOOTH_CONNECTED"
                else
                    status="disconnected, paired"
                    device_icon="$BLUETOOTH_DISCONNECTED"
                fi
            fi
            
            # Create/update popup item for this discovered device
            sketchybar --add item "discovered.$mac" popup.$NAME \
                --set "discovered.$mac" \
                label="$name ($mac) - $status" \
                icon="$device_icon" \
                icon.padding_left=10 \
                label.padding_left=8 \
                label.padding_right=10 \
                height=20 \
                blur_radius=100
        fi
    done <<< "$discovered"
}

# Update bluetooth info
update_bluetooth

# Handle mouse events
case "$SENDER" in
    "mouse.entered")
        sketchybar --set $NAME popup.drawing=on
        sketchybar --set $NAME icon.highlight=on label.highlight=on \
            icon.highlight_color=$base07 label.highlight_color=$base07
        discover_devices
        ;;
    "mouse.exited" | "mouse.exited.global")
        # Remove all discovered device items when popup closes
        while IFS= read -r item; do
            if [[ $item == discovered.* ]]; then
                sketchybar --remove "$item"
            fi
        done < <(sketchybar --query bar | $jq -r '.items[]')
        
        sketchybar --set $NAME popup.drawing=off
        sketchybar --set $NAME icon.highlight=off label.highlight=off
        ;;
    "mouse.clicked")
        sketchybar --set $NAME icon.highlight_color=$base04 label.highlight_color=$base04
        sketchybar --set $NAME icon.highlight_color=$base07 label.highlight_color=$base07
        sketchybar --set $NAME icon.highlight=off label.highlight=off popup.drawing=off
        ;;
    "routine")
        update_bluetooth
        ;;
esac
