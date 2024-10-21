{ pkgs, inputs, config, lib, ... }:

# window management toggle scripts.
let
  systemType = pkgs.stdenv.hostPlatform.system;
  homebrewPath =
    if systemType == "aarch64-darwin" then
      "/opt/homebrew/bin"
    else if systemType == "x86_64-darwin" then
      "/usr/local/bin"
    else
      throw "Homebrew Unsupported architecture: ${systemType}";
  jq = "${pkgs.jq}/bin/jq";
  yabai = "${pkgs.yabai}/bin/yabai";
  sketchybar = "${pkgs.sketchybar}/bin/sketchybar";
  # borders = "${pkgs.jankyborders}/bin/borders";
  borders = "";
  skhd = "${pkgs.skhd}/bin/skhd";
  inherit (config.colorScheme) palette;
in
{
  environment.systemPackages = with pkgs; [
    #fix-wm
    (pkgs.writeShellScriptBin "fix-wm" ''
      # remove statefiles if they exist
      [ -f /tmp/fullscreen_state ] && rm -f /tmp/fullscreen_state
      [ -f /tmp/dock_state ] && rm -f /tmp/dock_state
      [ -f /tmp/gaps_state ] && rm -f /tmp/gaps_state
      [ -f /tmp/sketchybar_state ] && rm -f /tmp/sketchybar_state
      [ -f /tmp/menubar_state ] && rm -f /tmp/menubar_state
      [ -f /tmp/darkmode_state ] && rm -f /tmp/darkmode_state

      #restart window management (yabai, skhd, sketchybar, borders, etc.)
      if pgrep yabai > /dev/null; then killall yabai > /dev/null 2>&1; fi
      if pgrep skhd > /dev/null; then killall skhd > /dev/null 2>&1; fi
      if pgrep sketchybar > /dev/null; then killall sketchybar > /dev/null 2>&1; fi
      if pgrep borders > /dev/null; then killall borders > /dev/null 2>&1; fi
      if pgrep flameshot > /dev/null; then killall flameshot > /dev/null 2>&1; fi
      if pgrep "Background Music" > /dev/null; then killall "Background Music" > /dev/null 2>&1; fi
      if pgrep "macOS InstantView" > /dev/null; then killall "macOS InstantView" > /dev/null 2>&1; fi
      if pgrep kdeconnectd > /dev/null; then killall kdeconnectd > /dev/null 2>&1; fi
      if pgrep karabiner_grabber > /dev/null; then sudo pkill karabiner_grabber > /dev/null 2>&1; fi
      if pgrep Karabiner-VirtualHIDDevice-Daemon > /dev/null; then sudo pkill Karabiner-VirtualHIDDevice-Daemon > /dev/null 2>&1; fi
      if pgrep karabiner_observer > /dev/null; then sudo pkill karabiner_observer > /dev/null 2>&1; fi
      if pgrep karabiner_console_user_server > /dev/null; then sudo pkill karabiner_console_user_server > /dev/null 2>&1; fi
      if pgrep Karabiner-Menu > /dev/null; then pkill Karabiner-Menu > /dev/null 2>&1; fi
      if pgrep Karabiner-Elements > /dev/null; then pkill Karabiner-Elements > /dev/null 2>&1; fi
      if pgrep cava > /dev/null; then sudo pkill -9 -f cava > /dev/null 2>&1; fi
      launchctl stop org.pqrs.karabiner.karabiner_console_user_server > /dev/null 2>&1 && launchctl start org.pqrs.karabiner.karabiner_console_user_server > /dev/null 2>&1
      launchctl stop org.pqrs.karabiner.karabiner_grabber > /dev/null 2>&1 && launchctl start org.pqrs.karabiner.karabiner_grabber > /dev/null 2>&1
      launchctl stop org.pqrs.karabiner.karabiner_observer > /dev/null 2>&1 && launchctl start org.pqrs.karabiner.karabiner_observer > /dev/null 2>&1

      if pgrep -x "XQuartz" > /dev/null; then
        xrdb -merge ~/.Xresources
      fi

      if ! pgrep -x "borders" > /dev/null; then
        sh ~/.config/borders/bordersrc > /dev/null 2>&1 & # source borders config in background and suppress output
      fi

      if ! pgrep -x "Finder" > /dev/null; then
        open -a Finder # fixes yabai workspaces issue.
      fi

      if ! pgrep -x "flameshot" > /dev/null; then
        flameshot > /dev/null 2>&1 &
      fi
      if ! pgrep -x "Background Music" > /dev/null; then
        open -a "Background Music"
      fi
      if ! pgrep -x "macOS InstantView" > /dev/null; then
        open -a "macOS InstantView"
      fi
      if ! pgrep -x "kdeconnectd" > /dev/null; then
        kdeconnectd > /dev/null 2>&1 &
      fi

      toggle-darkmode ${config.colorScheme.variant}

      # start borders with order above
      ${borders} order=above > /dev/null 2>&1 &
    '')

    # init_alias_items
    (pkgs.writeShellScriptBin "init_alias_items" ''
      sleep 4
      # Fetch the menu items from sketchybar query
      ${sketchybar} --query default_menu_items | ${jq} -r '.[]' | while read -r item; do
          ${sketchybar} --set "$item" alias.update_freq=0
      done

      # Sleep for 5 seconds
      sleep 3

      # Set menubar_opacity to 0.0
      ${yabai} -m config menubar_opacity 0.0 # back to invisible!
    '')

    #disable-hud
    (pkgs.writeShellScriptBin "disable-hud" ''
      #!/bin/bash
      # echo "Note: SIP must be is disabled."
      launchctl unload -F /System/Library/LaunchAgents/com.apple.OSDUIHelper.plist
      #(crontab -l ; echo "@reboot launchctl unload -F /System/Library/LaunchAgents/com.apple.OSDUIHelper.plist") | crontab -
      # echo "Volume and Brightness HUD disabled."
    '')

    #dismiss-notifications
    (pkgs.writeShellScriptBin "dismiss-notifications" ''
          osascript -e 'tell application "System Events"
      	tell process "NotificationCenter"
      		if not (window "Notification Center" exists) then return
      		set alertGroups to groups of first UI element of first scroll area of first group of window "Notification Center"
      		repeat with aGroup in alertGroups
      			try
      				perform (first action of aGroup whose name contains "Close" or name contains "Clear")
      			on error errMsg
      				log errMsg
      			end try
      		end repeat
      		-- Show no message on success
      		return ""
      	end tell
      end tell'
    '')

    # notif-test
    (pkgs.writeShellScriptBin "notif-test" ''
      if [[ "$OSTYPE" == "darwin"* ]]; then
        for i in {1..10}; do
          osascript -e "display notification \"This is the detailed content for notification number $i. It includes an icon, a title, and this message body.\" with title \"Notification $i\" subtitle \"Subtitle $i\" sound name \"default\""
          sleep 1
        done
      else
        for i in {1..10}; do
          notify-send -i ~/.dotfiles/users/alex/face.png \
               "Notification $i" \
               "This is the detailed content for notification number $i. It includes an icon, a title, and this message body."
          sleep 1
        done
      fi
    '')

    #yabai_i3_switch
    (pkgs.writeShellScriptBin "yabai_i3_switch" ''
      # Get the name of the frontmost application
      front_app=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')

      # Check if the frontmost application is X11.bin
      if [ "$front_app" = "X11.bin" ]; then
          # If X11.bin is the frontmost app, set the mouse modifier to cmd
          ${yabai} -m config mouse_modifier cmd # turns off yabai mouse shortcut
      else
          # If the frontmost app is not X11.bin, set the mouse modifier to alt
          ${yabai} -m config mouse_modifier alt # enables alt modifier for yabai again
      fi
    '')

        #brightness
    (pkgs.writeShellScriptBin "brightness" ''
      #!/bin/sh

      # Function to press the brightness up key
      brightness_up() {
        osascript -e 'tell application "System Events" to key code 144'
      }

      # Function to press the brightness down key
      brightness_down() {
        osascript -e 'tell application "System Events" to key code 145'
      }

      # Adjust brightness based on the provided number of times
      adjust_brightness() {
        local times=$1

        if [[ $times -gt 0 ]]; then
          for ((i = 0; i < times; i++)); do
            brightness_up
          done
        elif [[ $times -lt 0 ]]; then
          for ((i = 0; i < -times; i++)); do
            brightness_down
          done
        fi
      }

      # Check the argument passed to the script
      if [[ $# -ne 1 ]]; then
        echo "Usage: $0 <number>"
        exit 1
      fi

      adjust_brightness "$1"
    '')

        #mic (for sketchybar!)
    (pkgs.writeShellScriptBin "mic" ''
      MIC_VOLUME=$(osascript -e 'input volume of (get volume settings)')
      if [[ $MIC_VOLUME -eq 0 ]]; then
      ${sketchybar} -m --set mic icon=
      elif [[ $MIC_VOLUME -gt 0 ]]; then
      ${sketchybar} -m --set mic icon=
      fi 
    '')

    #mic_click (for sketchybar!)
    (pkgs.writeShellScriptBin "mic_click" ''
      MIC_VOLUME=$(osascript -e 'input volume of (get volume settings)')
      if [[ $MIC_VOLUME -eq 0 ]]; then
      osascript -e 'set volume input volume 25'
      ${sketchybar} -m --set mic icon=
      elif [[ $MIC_VOLUME -gt 0 ]]; then
      osascript -e 'set volume input volume 0'
      ${sketchybar} -m --set mic icon=
      fi 
    '')

    #toggle-sketchybar
    (pkgs.writeShellScriptBin "toggle-sketchybar" ''
      toggle_sketchybar() {
        local hidden_status=$(${sketchybar} --query bar | ${jq} -r '.hidden')
        local sketchybar_state_file="/tmp/sketchybar_state"
        
        # Check if the sketchybar state file exists
        if [ ! -f "$sketchybar_state_file" ]; then
            # If the state file doesn't exist, initialize it with the current state
            echo "$hidden_status" > "$sketchybar_state_file"
        fi

        update_spaces_and_bar() {
          local sketchybar_state=$(cat "$sketchybar_state_file")
          local gaps_status=$(cat "/tmp/gaps_state")
          # Determine external_bar configuration based on sketchybar and gaps status
          if [ "$sketchybar_state" = "on" ]; then
            if [ "$gaps_status" = "on" ]; then
                ${yabai} -m config external_bar all:50:0
            else
                ${yabai} -m config external_bar all:40:0
            fi
          else
            if [ "$gaps_status" = "on" ]; then
                ${yabai} -m config external_bar all:0:0
            else
                ${yabai} -m config external_bar all:0:0
            fi
          fi
          ${borders} background_color=0xff${palette.base00}
        }

        if [ "$1" == "on" ]; then
            if [ "$hidden_status" == "off" ]; then
                echo "Sketchybar is already toggled on"
            else
                ${sketchybar} --bar hidden=off
                echo "Sketchybar toggled on"
                echo "on" > "$sketchybar_state_file"  # Write state to file
            fi
        elif [ "$1" == "off" ]; then
            if [ "$hidden_status" == "on" ]; then
                echo "Sketchybar is already toggled off"
            else
                ${sketchybar} --bar hidden=on
                echo "Sketchybar toggled off"
                echo "off" > "$sketchybar_state_file"  # Write state to file
            fi
        else
            # No arguments provided, toggle based on current state
            if [ "$hidden_status" == "off" ]; then
                ${sketchybar} --bar hidden=on
                echo "Sketchybar toggled off"
                echo "off" > "$sketchybar_state_file"  # Write state to file
            else
                ${sketchybar} --bar hidden=off
                echo "Sketchybar toggled on"
                echo "on" > "$sketchybar_state_file"  # Write state to file
            fi
        fi
        update_spaces_and_bar
      }

      # Example usage
      toggle_sketchybar "$1"
    '')

    #toggle-gaps
    (pkgs.writeShellScriptBin "toggle-gaps" ''
      # Initialize a variable to store the current state
      state_file="/tmp/gaps_state"
      sketchybar_state_file="/tmp/sketchybar_state"

      # Initialize the state file if it doesn't exist
      if [ ! -f "$state_file" ]; then
        echo "on" > "$state_file"
      fi

      # Read the current state from the state file
      gaps_state=$(cat "$state_file")

      # Initialize the sketchybar state file if it doesn't exist
      if [ ! -f "$sketchybar_state_file" ]; then
        echo "off" > "$sketchybar_state_file"
      fi

      sketchybar_state=$(cat "$sketchybar_state_file")

      toggle() {
        if [ "$gaps_state" == "off" ]; then
          on
          echo "on" > "$state_file"
        else
          off
          echo "off" > "$state_file"
        fi
      }

      on() {
        ${yabai} -m config top_padding     15
        ${yabai} -m config bottom_padding  15
        ${yabai} -m config left_padding    15
        ${yabai} -m config right_padding   15
        ${yabai} -m config window_gap      15
        if [ "$sketchybar_state" == "off" ]; then
          ${yabai} -m config external_bar all:0:0 # disables the bar window gap
        else
          ${yabai} -m config external_bar all:50:0 # enables the bar window gap
        fi
        ${borders} style=round width=2.0 order=above
        ${sketchybar} --bar corner_radius=10
        ${sketchybar} --bar margin=13
        ${sketchybar} --bar y_offset=13
      }

      off() {
        ${yabai} -m config top_padding     2
        ${yabai} -m config bottom_padding  2
        ${yabai} -m config left_padding    2
        ${yabai} -m config right_padding   2
        ${yabai} -m config window_gap      5
        if [ "$sketchybar_state" == "off" ]; then
          ${yabai} -m config external_bar all:0:0
        else
          ${yabai} -m config external_bar all:40:0
        fi
        ${borders} style=square order=below width=5.0
        ${sketchybar} --bar corner_radius=0
        ${sketchybar} --bar margin=0
        ${sketchybar} --bar y_offset=0
      }

      if [ "$#" -eq 0 ]; then
        toggle
      elif [ "$1" == "on" ]; then
        if [ "$gaps_state" == "on" ]; then
          echo "Already enabled"
        else
          on
          echo "on" > "$state_file"
        fi
      elif [ "$1" == "off" ]; then
        if [ "$gaps_state" == "off" ]; then
          echo "Already disabled"
        else
          off
          echo "off" > "$state_file"
        fi
      else
        echo "Invalid argument. Usage: $0 [on|off]"
      fi
    '')

    # toggle-dock
    (pkgs.writeShellScriptBin "toggle-dock" ''
      dock_state_file="/tmp/dock_state"
      gaps_state_file="/tmp/gaps_state"
      sketchybar_state_file="/tmp/sketchybar_state"

      toggle_dock() {
          local dock_status=$(osascript -e 'tell application "System Events" to get autohide of dock preferences')
          local current_state=$(cat "$dock_state_file" 2>/dev/null || echo "off")
          local new_state="$current_state"

          if [ "$1" = "on" ]; then
              if [ "$current_state" = "on" ]; then
                  echo "Warning: Dock is already visible"
              else
                  osascript -e 'tell application "System Events" to set autohide of dock preferences to false'
                  new_state="on"
              fi
          elif [ "$1" = "off" ]; then
              if [ "$current_state" = "off" ]; then
                  echo "Warning: Dock is already hidden"
              else
                  osascript -e 'tell application "System Events" to set autohide of dock preferences to true'
                  new_state="off"
              fi
          else
              if [ "$current_state" = "off" ]; then
                  osascript -e 'tell application "System Events" to set autohide of dock preferences to false'
                  new_state="on"
              else
                  osascript -e 'tell application "System Events" to set autohide of dock preferences to true'
                  new_state="off"
              fi
          fi

          echo "$new_state" > "$dock_state_file"
          echo "Dock toggled $new_state"
      }

      # Example usage
      toggle_dock "$1"
    '')

    #toggle-menubar
    (pkgs.writeShellScriptBin "toggle-menubar" ''
      menubar_state_file="/tmp/menubar_state"

      # Function to toggle the macOS menu bar on
      toggle_on() {
          if [ "$(cat "$menubar_state_file")" = "on" ]; then
              echo "Menu bar is already ON"
          else
              osascript -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to false'
              sleep 0.1
              echo "Menu bar turned ON"
              echo "on" > "$menubar_state_file"
          fi
      }

      # Function to toggle the macOS menu bar off
      toggle_off() {
          if [ "$(cat "$menubar_state_file")" = "off" ]; then
              echo "Menu bar is already OFF"
          else
              osascript -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to true'
              echo "Menu bar turned OFF"
              echo "off" > "$menubar_state_file"
          fi
      }

      # Main function to toggle the menu bar based on the argument
      toggle_menubar() {
          if [ "$1" = "on" ]; then
              toggle_on
          elif [ "$1" = "off" ]; then
              toggle_off
          else
              # Toggle between on/off states if no argument is provided
              if [ "$(cat "$menubar_state_file")" = "on" ]; then
                  toggle_off
              else
                  toggle_on
              fi
          fi
      }

      # Example usage
      toggle_menubar "$1"
    '')

    #toggle-float
    (pkgs.writeShellScriptBin "toggle-float" ''
      # update the sketchybar front_app
      ${sketchybar} --trigger window_focus

      # Function to check if the current window is floating
      is_floating() {
          ${yabai} -m query --windows --window | ${jq} -r '."is-floating"' | grep -q "true"
      }

      # Function to check if the current window is topmost
      is_topmost() {
          ${yabai} -m query --windows --window | ${jq} -r '."is-topmost"' | grep -q "true"
      }

      fullscreen_state_file="/tmp/fullscreen_state"
      window_id=$(${yabai} -m query --windows --window | ${jq} -r '."id"')

      # Function to check if the current window is in fullscreen mode
      is_fullscreen() {
          grep -q "id: $window_id fullscreen: on" "$fullscreen_state_file"
      }

      # Check if the script is provided with an argument
      if [ $# -eq 0 ]; then
          # Toggle between on/off states if no argument is provided
          if is_floating; then
              set_arg="off"
          else
              set_arg="on"
          fi
      else
          set_arg="$1"
      fi

      # Check the value of the argument
      if [ "$set_arg" = "on" ]; then
          if is_fullscreen; then
              echo "Cannot toggle float on: window is in fullscreen mode."
          elif is_floating; then
              echo "Window is already floating."
          else
              ${yabai} -m window --toggle float
              ${yabai} -m window --grid 60:60:5:5:50:50
              ${borders} apply-to=$window_id width=2.0 style=round order=above
              if ! is_topmost; then
                  ${yabai} -m window --toggle topmost
              fi
              echo "Window is now floating and topmost."
          fi
      elif [ "$set_arg" = "off" ]; then
          if is_fullscreen; then
              echo "Cannot toggle float off: window is in fullscreen mode."
          elif ! is_floating; then
              echo "Window is already not floating."
          else
              ${yabai} -m window --toggle float
              gaps_state=$(cat /tmp/gaps_state)
              if [ "$gaps_state" = "on" ]; then
                  ${borders} apply-to=$window_id width=2.0 style=round order=above
              else
                  ${borders} apply-to=$window_id width=5.0 style=square order=below
              fi
              if is_topmost; then
                  ${yabai} -m window --toggle topmost
              fi
              echo "Window is no longer floating."
          fi
      else
          echo "Usage: $0 [on|off]"
          exit 1
      fi
    '')

    #toggle-float2
    (pkgs.writeShellScriptBin "toggle-float2" ''
      #!/bin/bash

      # Used to toggle a window between floating and tiling

      read -r id floating <<< $(echo $(${yabai} -m query --windows --window | ${jq} '.id, .floating'))
      tmpfile=/tmp/${yabai}-float-toggle/$id

      # If the window is floating, toggle it to be tiling and record its position and size
      if [ "$floating" = "1" ]
      then
        [ -e $tmpfile ] && rm $tmpfile
        echo $(${yabai} -m query --windows --window | ${jq} .frame) >> $tmpfile
        ${yabai} -m window --toggle float

      # If the window is tiling, toggle it to be floating, 
      # and restore its previous position and size
      else
        ${yabai} -m window --toggle float
        if [ -e $tmpfile ]
        then
          read -r x y w h <<< $(echo $(cat $tmpfile | ${jq} '.x, .y, .w, .h'))
          ${yabai} -m window --move abs:$x:$y
          ${yabai} -m window --resize abs:$w:$h
          rm $tmpfile
        fi
      fi
    '')

    # toggle-darkmode
    (pkgs.writeShellScriptBin "toggle-darkmode" ''
      current_mode=$(osascript -e 'tell app "System Events" to tell appearance preferences to return dark mode')

      if [ -z "$1" ]; then
        # No argument provided, toggle based on current state
        if [ "$current_mode" == "true" ]; then
            toggle-cursor-theme dark
            osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to false'
        elif [ "$current_mode" == "false" ]; then
            toggle-cursor-theme light
            osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to true'
        fi

      elif [ "$1" == "light" ]; then
        if [ "$current_mode" == "false" ]; then
          echo "Light mode is already on."
        else
          # Toggle light mode on
          toggle-cursor-theme dark
          osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to false'
        fi
      elif [ "$1" == "dark" ]; then
        if [ "$current_mode" == "true" ]; then
          echo "Dark mode is already on."
        else
          # Toggle dark mode on
          toggle-cursor-theme light
          osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to true'
        fi
      else
        echo "Invalid argument. Please specify 'light' or 'dark' or leave empty to toggle."
        exit 1
      fi
    '')

    # toggle-instant-fullscreen
    (pkgs.writeShellScriptBin "toggle-instant-fullscreen" ''
      fullscreen_state_file="/tmp/fullscreen_state"
      window_id=$(${yabai} -m query --windows --window | ${jq} -r '."id"')

      function update_state_file() {
          local state=$1
          if grep -q "id: $window_id " "$fullscreen_state_file"; then
              # Update the existing line
              sed -i "" "s/id: $window_id fullscreen: .*/id: $window_id fullscreen: $state/" "$fullscreen_state_file"
          else
              # Append a new line
              echo "id: $window_id fullscreen: $state" >> "$fullscreen_state_file"
          fi
      }

      function fullscreen_on() {
          #first, we should check the window position, and then save it to the fullscreen statefile. also check if the current window floating.
          if [ "$(${yabai} -m query --windows --window | ${jq} -r '."is-floating"')" = "true" ]; then
            window_position=$(${yabai} -m query --windows --window | ${jq} -r '."frame"')
            if grep -q "id: $window_id position:" "$fullscreen_state_file"; then
              sed -i "" "s/id: $window_id position: .*/id: $window_id position: $window_position floating: true/" "$fullscreen_state_file"
            else
              echo "id: $window_id position: $window_position floating: true" >> "$fullscreen_state_file"
            fi
          fi
          
          toggle-dock off
          if [ "$(cat /tmp/menubar_state)" = "on" ]; then
              toggle-menubar off
          fi
          local is_floating=$(${yabai} -m query --windows --window | ${jq} -r '."is-floating"')
          local current_display_frame=$(${yabai} -m query --displays --display | ${jq} '.frame')
          local x=$(echo "$current_display_frame" | ${jq} -r '.x')
          local y=$(echo "$current_display_frame" | ${jq} -r '.y')

          ${borders} apply-to=$window_id width=0.0 style=square order=below background_color=0xff${palette.base00} active_color=0xff${palette.base00} inactive_color=0xff${palette.base00}
          if [ "$is_floating" = "true" ]; then
            ${yabai} -m window --move abs:$x:$y
            ${yabai} -m window --grid 0:0:0:0:0:0
          else
            ${yabai} -m window --toggle float
            ${yabai} -m window --move abs:$x:$y
            ${yabai} -m window --grid 0:0:0:0:0:0
          fi
          update_state_file "on"
      }

      function fullscreen_off() {
        # Read the gaps state file
          gaps_state=$(cat /tmp/gaps_state)
          if [ "$gaps_state" = "off" ]; then
              ${borders} apply-to=$window_id width=5.0 style=square background_color=0x11${palette.base00} active_color=0xff${palette.base07} inactive_color=0xff${palette.base05} order=above 
          else
              ${borders} apply-to=$window_id width=2.0 style=round  background_color=0x11${palette.base00} active_color=0xff${palette.base07} inactive_color=0xff${palette.base05} order=above 
          fi

          # ${borders} apply-to=$window_id width=2 style=round background_color=0x11${palette.base00} active_color=0xff${palette.base07} inactive_color=0xff${palette.base05} order=above 
          window_position=$(grep -A 4 "id: $window_id position:" "$fullscreen_state_file" | tr -d '\n' | sed 's/$/ }/')
          echo "Window position block extracted: $window_position"  # Debugging statement

          if [ -n "$window_position" ]; then
              # Extract the position part and format it as JSON
              position_json=$(echo "$window_position" | sed -n 's/.*position: {\(.*\)}/\1/p' | jq -R 'split(",") | map(split(":") | {(.[0] | gsub("[^a-zA-Z]";"")): (.[1] | tonumber)}) | add')
              echo "Extracted JSON: $position_json"  # Debugging statement

              # Directly parse the JSON without checking if it's null since we are assuming it's always valid
              x=$(echo "$position_json" | jq -r '.x')
              y=$(echo "$position_json" | jq -r '.y')
              width=$(echo "$position_json" | jq -r '.w')
              height=$(echo "$position_json" | jq -r '.h')

              echo "Parsed x: $x, y: $y, width: $width, height: $height"  # Debugging statement
              # Move and resize the window using the parsed coordinates
              ${yabai} -m window --move abs:$x:$y
              ${yabai} -m window --resize abs:$width:$height
              sed -i "" "/id: $window_id position:/,/floating: true/d" "$fullscreen_state_file"
          else
              if [ "$(${yabai} -m query --windows --window | ${jq} '."is-floating"')" = "true" ]; then
                  ${yabai} -m window --toggle float
              fi
          fi
          update_state_file "off"
      }

      if [ ! -f "$fullscreen_state_file" ]; then
          echo "id: $window_id fullscreen: false" >> "$fullscreen_state_file"
      fi

      function check_fullscreen_state() {
          local search_id=$1
          grep "id: $search_id fullscreen:" "$fullscreen_state_file" | tail -1 | awk '{print $NF}'
      }

      # Set the fullscreen state for the current window
      fullscreen_state=$(check_fullscreen_state $window_id)

      if [ "$1" = "on" ]; then
          if [ "$fullscreen_state" = "on" ]; then
              echo "Fullscreen is already on. Running again..."
          fi
          fullscreen_on
      elif [ "$1" = "off" ]; then
          if [ "$fullscreen_state" = "off" ]; then
              echo "Fullscreen is already off. Running again..."
          fi
          fullscreen_off
      else
          if [ "$fullscreen_state" = "on" ]; then
              fullscreen_off
          else
              fullscreen_on
          fi
      fi
      ${sketchybar} --trigger front_app_switched
    '')

    # mousecape-switcher
    (pkgs.writeShellScriptBin "mousecape-switcher" ''
      #!/bin/sh

      # List available capes
      echo "Available capes:"
      CAPE_FILES=($(ls "$HOME/Library/Application Support/Mousecape/capes/"))
      for i in "''${!CAPE_FILES[@]}"; do
        echo "$((i+1)). ''${CAPE_FILES[$i]}"
      done

      # Prompt user to select the cape by number
      read -p "Enter the number of the cape to apply: " CAPE_INDEX
      CAPE_NAME=''${CAPE_FILES[$((CAPE_INDEX-1))]}

      # Command to apply the cape
      cd "$HOME/Applications/Nix Trampolines/Mousecape.app/Contents/MacOS"
      ./mousecloak --apply "$HOME/Library/Application Support/Mousecape/capes/$CAPE_NAME"
      echo "Applied cape: $CAPE_NAME"
    '')

    # toggle-cursor-theme
    (pkgs.writeShellScriptBin "toggle-cursor-theme" ''
      #!/bin/bash

      # Define the two capes
      CAPE_LIGHT="com.alex.bibata-modern-ice.cape" # for darkmode. label this light
      CAPE_DARK="com.aspauldingcode.bibata-modern-classic.cape" # for lightmode. label this dark

      # Apply the appropriate cape based on the command line argument or toggle if no argument is provided
      if [ -z "$1" ]; then
        # Read the current cape state
        CURRENT_CAPE=$(cat "$HOME/Library/Application Support/Mousecape/current_cape.txt")
        if [ "$CURRENT_CAPE" == "$CAPE_LIGHT" ]; then
          CAPE_NAME=$CAPE_DARK
          echo "Toggling to dark cape for light mode."
        else
          CAPE_NAME=$CAPE_LIGHT
          echo "Toggling to light cape for dark mode."
        fi
      elif [ "$1" == "light" ]; then
        CAPE_NAME=$CAPE_LIGHT
        echo "Applying light cape for dark mode."
      elif [ "$1" == "dark" ]; then
        CAPE_NAME=$CAPE_DARK
        echo "Applying dark cape for light mode."
      else
        echo "Invalid argument. Please specify 'light' or 'dark' or leave empty to toggle."
        exit 1
      fi

      # Command to apply the selected cape
      cd "$HOME/Applications/Nix Trampolines/Mousecape.app/Contents/MacOS"
      ./mousecloak --apply "$HOME/Library/Application Support/Mousecape/capes/$CAPE_NAME"
      echo "Applied cape: $CAPE_NAME"

      # Save the current cape state
      echo "$CAPE_NAME" > "$HOME/Library/Application Support/Mousecape/current_cape.txt"
    '')
  ];
}