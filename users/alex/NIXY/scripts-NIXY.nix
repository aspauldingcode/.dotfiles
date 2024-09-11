{ config, pkgs, ... }:

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
  yabai = "${homebrewPath}/yabai";
  sketchybar = "${homebrewPath}/sketchybar";
  # borders = "${homebrewPath}/borders";
  borders = "~/JankyBorders/bin/borders";
  skhd = "${homebrewPath}/skhd";
  inherit (config.colorScheme) colors;
in
{
  home = {
    packages = with pkgs; [
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

    # set-nvram-flags FIXME: UPDATE FLAGS so Karabiner still works.
    (pkgs.writeShellScriptBin "set-nvram-flags" ''
    # TLDR; DO NOT DISABLE AMFI.

    # So that this doesn't become an AltStore comment in a Karabiner-Elements thread, 
    # you can clear the NVRAM to reset AMFI if you do have it enabled. See the contents 
    # of your NVRAM boot arguments with sudo nvram -p | grep boot-args. 
    # On Apple silicon devices, clear it with sudo nvram -c, before rebooting to check 
    # if Karabiner-Elements has come back to life.


    if [[ "$1" == "on" ]]; then
      echo "User entered 'on' argument."
      echo "Enabling custom boot args..."
      sudo nvram boot-args="-arm64e_preview_abi -v" # amfi_get_out_of_my_way=0x80 -v"
      # Disable AutoBoot
      # sudo nvram auto-boot=false
    elif [[ "$1" == "off" ]]; then
      echo "User entered 'off' argument."
      echo "Disabling custom boot args..."
      sudo nvram -c
      # Disable AutoBoot
      # sudo nvram auto-boot=false
    fi
    if [[ "$1" == "on" || "$1" == "off" ]]; then
      echo "Completed. Your boot args are listed below:"
      nvram -p | grep boot-args
      echo "Done."
    else
      echo "No argument provided. Please add arguments 'on' or 'off' for this command."
      echo "Your current boot args are listed below:"
      nvram -p | grep boot-args
    fi
    '')

    #json2nix converter
    #(pkgs.writeScriptBin "json2nix" ''
    #  ${pkgs.python3}/bin/python ${
    #    pkgs.fetchurl {
    #      url = "https://gist.githubusercontent.com/Scoder12/0538252ed4b82d65e59115075369d34d/raw/e86d1d64d1373a497118beb1259dab149cea951d/json2nix.py";
    #      hash = "sha256-ROUIrOrY9Mp1F3m+bVaT+m8ASh2Bgz8VrPyyrQf9UNQ=";
    #    }
    #  } $@
    #'')

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
      if pgrep "Background Music" > /dev/null; then killall Background\ Music > /dev/null 2>&1; fi
      if pgrep InstantView > /dev/null; then killall InstantView > /dev/null 2>&1; fi
      if pgrep kdeconnectd > /dev/null; then killall kdeconnectd > /dev/null 2>&1; fi
      if pgrep karabiner_grabber > /dev/null; then sudo pkill karabiner_grabber > /dev/null 2>&1; fi
      if pgrep Karabiner-VirtualHIDDevice-Daemon > /dev/null; then sudo pkill Karabiner-VirtualHIDDevice-Daemon > /dev/null 2>&1; fi
      if pgrep karabiner_observer > /dev/null; then sudo pkill karabiner_observer > /dev/null 2>&1; fi
      if pgrep karabiner_console_user_server > /dev/null; then sudo pkill karabiner_console_user_server > /dev/null 2>&1; fi
      if pgrep Karabiner-Menu > /dev/null; then pkill Karabiner-Menu > /dev/null 2>&1; fi
      if pgrep Karabiner-Elements > /dev/null; then pkill Karabiner-Elements > /dev/null 2>&1; fi
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
      if ! pgrep -x "InstantView" > /dev/null; then
        open -a "InstantView"
      fi
      if ! pgrep -x "kdeconnectd" > /dev/null; then
        kdeconnectd > /dev/null 2>&1 &
      fi
    '')

    #analyze-output
    (pkgs.writeShellScriptBin "analyze-output" ''
        # Counter for variable names
        count=1
        # Specify the output file path
        output_file=~/.dotfiles/users/alex/NIXY/sketchybar/cal-output.txt
        
      # Delimiter to replace spaces
      delimiter="⌇"

      # Read input from the pipe
      while IFS= read -r line; do
          # Replace spaces with the specified delimiter
          formatted_line=$(echo "$line" | tr ' ' "$delimiter")

          # Assign each formatted line to a numbered variable
          var_name="line_$count"
          declare "$var_name=$formatted_line"

          # Print the variable name and formatted value
          echo "$var_name: $formatted_line"

          # Increment the counter
          ((count++))
      done > "$output_file"

      echo "Output saved to: $output_file"

    '')

    #disable-hud
    (pkgs.writeShellScriptBin "disable-hud" ''
      #!/bin/bash
      # echo "Note: SIP must be is disabled."
      launchctl unload -F /System/Library/LaunchAgents/com.apple.OSDUIHelper.plist
      #(crontab -l ; echo "@reboot launchctl unload -F /System/Library/LaunchAgents/com.apple.OSDUIHelper.plist") | crontab -
      # echo "Volume and Brightness HUD disabled."
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
          ${borders} background_color=0xff${colors.base00}
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

    # print-spaces
    (pkgs.writeShellScriptBin "print-spaces" ''
      #!/bin/bash

      # Query for spaces with windows
      spaces_with_windows=($(${yabai} -m query --spaces | ${jq} -r '.[] | select(.windows | length > 0) | .index'))

      # Query for the active space
      active_space=$(${yabai} -m query --spaces --space | ${jq} -r '.index')

      # active space per display
      # Query for the total number of displays
      total_displays=$(${yabai} -m query --displays | ${jq} 'length')

      # Initialize an array to store active display spaces
      active_display_spaces=()

      # Loop through each display
      for ((display=1; display<=$total_displays; display++)); do
          # Query for spaces on the current display that are visible
          spaces=$(${yabai} -m query --spaces --display $display | ${jq} -r '.[] | select(.["is-visible"] == true) | .index')

          # Add visible spaces to the active_display_spaces array
          for space in $spaces; do
              active_display_spaces+=("$space")
          done
      done

      # Combine spaces with windows and active spaces on all displays
      print=($(echo "''${spaces_with_windows[@]}" "''${active_display_spaces[@]}" | tr ' ' '\n' | sort -nu))

      echo "''${print[@]}"
    '')

    # spaces-clear
    (pkgs.writeShellScriptBin "spaces-clear" ''
      #!/bin/bash

      # count all spaces.
      # all=length(spaces)
      max_spaces=$(${yabai} -m query --spaces | ${jq} 'max_by(.index) | .index')

      # Query for the highest space containing a window
      lastwindow=$(${yabai} -m query --spaces | ${jq} '[.[] | select(.windows | length > 0) | .index] | max')

      # remaining=max_spaces - last space with a window
      remaining=$((max_spaces - lastwindow))

      # from last to
      for ((i=1; i<=$remaining; i++))
      do
          ${yabai} -m space $(($lastwindow + 1)) --destroy
      done

    '')

    # spaces-focus
    (pkgs.writeShellScriptBin "spaces-focus" ''
      # Define variables
      # How many displays are there?
      max_displays=$(${yabai} -m query --displays | ${jq} 'max_by(.index) | .index')
      # How many spaces are there?
      max_spaces=$(${yabai} -m query --spaces | ${jq} 'max_by(.index) | .index')
      # Current active space!
      current_space=$(${yabai} -m query --spaces --space | ${jq} -r '.index')
      # Current active display!
      current_display=$(${yabai} -m query --displays --display | ${jq} -r '.index')
      # Accept desired space number as input argument
      if [ $# -ne 1 ]; then
      echo "Usage: $0 <desired_space_number>"
      exit 1
      fi
      n=$1
      # Focus on a space
      # If space n is not created, create it
      if [ $n -gt $max_spaces ]; then
        iterations=$((n - max_spaces))
        for ((i=0; i<iterations; i++)); do
          ${yabai} -m space --create
          #reassign max_spaces:
          max_spaces=$(${yabai} -m query --spaces | ${jq} 'max_by(.index) | .index')
        done
      fi
      # then, focus on space n
      ${yabai} -m space --focus $n
    '')

    # move-to-space
    (pkgs.writeShellScriptBin "move-to-space" ''
      # Define variables
      # How many displays are there?
      max_displays=$(${yabai} -m query --displays | ${jq} 'max_by(.index) | .index')
      # How many spaces are there?
      max_spaces=$(${yabai} -m query --spaces | ${jq} 'max_by(.index) | .index')
      # Current active space!
      current_space=$(${yabai} -m query --spaces --space | ${jq} -r '.index')
      # Current active display!
      current_display=$(${yabai} -m query --displays --display | ${jq} -r '.index')
      # Accept desired space number as input argument
      if [ $# -ne 1 ]; then
      echo "Usage: $0 <desired_space_number>"
      exit 1
      fi
      n=$1
      # Focus on a space
      # If space n is not created, create it
      if [ $n -gt $max_spaces ]; then
        iterations=$((n - max_spaces))
        for ((i=0; i<iterations; i++)); do
          ${yabai} -m space --create
          #reassign max_spaces:
          max_spaces=$(${yabai} -m query --spaces | ${jq} 'max_by(.index) | .index')
        done
      fi
      # then, move window to space n
      ${yabai} -m window --space $n
      # then, focus on space n
      ${yabai} -m space --focus $n
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
              echo "Window is now floating."
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

    # statefile-reader
    (pkgs.writeShellScriptBin "statefile-reader" ''
      gaps_state_file="/tmp/gaps_state"
      sketchybar_state_file="/tmp/sketchybar_state"
      dock_state_file="/tmp/dock_state"
      menubar_state_file="/tmp/menubar_state"
      darkmode_state_file="/tmp/darkmode_state"

      # Function to read state from file
      read_state() {
          if [ -f "$1" ]; then
              cat "$1"
          else
              echo "off"
          fi
      }

      # Read the current state from the state files, if they exist
      gaps_state=$(read_state "$gaps_state_file")
      sketchybar_state=$(read_state "$sketchybar_state_file")
      dock_state=$(read_state "$dock_state_file")
      menubar_state=$(read_state "$menubar_state_file")
      darkmode_state=$(read_state "$darkmode_state_file")

      # Function to check dark mode status and update darkmode state file
      check_darkmode_status() {
          darkmode_status=$(osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode')
          if [ "$darkmode_status" = "true" ]; then
              darkmode_state="on"
          else
              darkmode_state="off"
          fi
          echo "$darkmode_state" > "$darkmode_state_file"
      }

      # Call the function to check dark mode status
      check_darkmode_status

      # Update the sketchybar state
      sketchybar_hidden_status=$(${sketchybar} --query bar | ${jq} -r '.hidden')
      if [ "$sketchybar_hidden_status" = "on" ]; then
          sketchybar_state="off"
      elif [ "$sketchybar_hidden_status" = "off" ]; then 
          sketchybar_state="on"
      fi

      # Update the dock state
      dock_status=$(osascript -e 'tell application "System Events" to get autohide of dock preferences')
      if [ "$dock_status" = "true" ]; then
          dock_state="off"
      elif [ "$dock_status" = "false" ]; then
          dock_state="on"
      fi

      echo "Gaps is: $gaps_state"
      echo "Sketchybar is: $sketchybar_state"
      echo "Dock is: $dock_state"
      echo "Menubar is: $menubar_state"
      echo "Dark Mode is: $darkmode_state"
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

          ${borders} apply-to=$window_id width=0.0 style=square order=below background_color=0xff${colors.base00} active_color=0xff${colors.base00} inactive_color=0xff${colors.base00}
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
              ${borders} apply-to=$window_id width=5.0 style=square background_color=0x11${colors.base00} active_color=0xff${colors.base07} inactive_color=0xff${colors.base05} order=above 
          else
              ${borders} apply-to=$window_id width=2.0 style=round  background_color=0x11${colors.base00} active_color=0xff${colors.base07} inactive_color=0xff${colors.base05} order=above 
          fi

          # ${borders} apply-to=$window_id width=2 style=round background_color=0x11${colors.base00} active_color=0xff${colors.base07} inactive_color=0xff${colors.base05} order=above 
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

    #search
    (pkgs.writeShellScriptBin "search" ''
      # Check if an argument is provided
      if [ $# -ne 1 ]; then
          echo "Usage: $0 <search_term>"
          exit 1
      fi

      # Perform the search (in the current directory) using find and fzf with provided options
      search_term=$1
      echo "Searching for: $search_term"
      echo "Press Ctrl+C to cancel..."
      find . -iname "*$search_term*" 2>/dev/null | fzf --preview="bat --color=always {}" --preview-window="right:60%" --height=80%
    '')

    #search-rg
    (pkgs.writeShellScriptBin "search-rg" ''
      if [ $# -ne 1 ]; then
          echo "Usage: $0 <search_term>"
          exit 1
      fi

      # Perform the search using ripgrep and fzf with provided options
      search_term=$1
      echo "Searching for: $search_term"
      echo "Press Ctrl+C to cancel..."
      rg --ignore-case --context 3 --color=always "$search_term" | fzf --preview="bat --color=always --style=numbers,changes {}" --preview-window="right:60%" --height=80%
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
        CURRENT_CAPE=$(cat "$HOME/Library/Application Support/Mousecape/current_cape.txt")
        if [ "$CURRENT_CAPE" == "$CAPE_LIGHT" ]; then
          echo "Light cape for dark mode is already applied."
          exit 0
        else
          CAPE_NAME=$CAPE_LIGHT
          echo "Applying light cape for dark mode."
        fi
      elif [ "$1" == "dark" ]; then
        CURRENT_CAPE=$(cat "$HOME/Library/Application Support/Mousecape/current_cape.txt")
        if [ "$CURRENT_CAPE" == "$CAPE_DARK" ]; then
          echo "Dark cape for light mode is already applied."
          exit 0
        else
          CAPE_NAME=$CAPE_DARK
          echo "Applying dark cape for light mode."
        fi
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

    #hexdiff_check
    (pkgs.writeShellScriptBin "hexdiff_check" ''
      #!/bin/sh

      # Function to pick a file using zenity and suppress GLib error messages
      pick_file() {
        zenity --file-selection --title="Select file to compare:" 2>/dev/null
      }

      # Function to format file path for display (splitting if longer than 60 characters)
      format_filepath() {
        local filepath=$1
        local max_length=60

        # Check if filepath length exceeds max_length
        if [ ''${#filepath} -le $max_length ]; then
          echo "$filepath"
        else
          # Split filepath into multiple lines
          local first_part="''${filepath:0:$max_length}"
          local remaining="''${filepath:$max_length}"

          echo "$first_part"
          while [ ''${#remaining} -gt $max_length ]; do
            echo "''${remaining:0:$max_length}"
            remaining="''${remaining:$max_length}"
          done

          # Print the remaining part or final line
          if [ -n "$remaining" ]; then
            echo "$remaining"
          fi
        fi
      }

      # Function to perform hex diff and format output
      hex_diff() {
        local file1=$1
        local file2=$2

        # Create temporary files for hex dumps
        temp1=$(mktemp)
        temp2=$(mktemp)

        # Create hex dumps of both files
        xxd "$file1" > "$temp1"
        xxd "$file2" > "$temp2"

        # Perform the comparison and format the output
        diff_output=$(diff -y --suppress-common-lines "$temp1" "$temp2")

        # Check if there are differences
        if [ -z "$diff_output" ]; then
          echo "The files are identical."
        else
          echo "Hexadecimal Differences:"
          echo "$diff_output" | while IFS= read -r line; do
            if [[ $line =~ ^[0-9a-f]+ ]]; then
              echo "$line"
            fi
          done
          # Save the diff output to a file
          echo "$diff_output" > /tmp/hex_differences.txt
          echo "For convenience, this diff output has been saved to /tmp/hex_differences.txt"
        fi

        # Clean up temporary files
        rm "$temp1" "$temp2"
      }

      # Pick the first file
      echo "Select the first file:"
      file1=$(pick_file)
      echo $(basename "$file1")

      # Check if a file was selected
      if [ -z "$file1" ]; then
        echo "No file selected. Exiting."
        exit 1
      fi

      # Pick the second file
      echo "Select the second file:"
      file2=$(pick_file)
      echo $(basename "$file2")

      # Check if a file was selected
      if [ -z "$file2" ]; then
        echo "No file selected. Exiting."
        exit 1
      fi


      echo "Comparing Files:"

      # Format file paths for display
      file1_formatted=$(format_filepath "$file1")
      file2_formatted=$(format_filepath "$file2")

      # Split formatted file paths into lines
      file1_lines=()
      file2_lines=()
      while IFS= read -r line; do
        file1_lines+=("$line")
      done <<< "$file1_formatted"

      while IFS= read -r line; do
        file2_lines+=("$line")
      done <<< "$file2_formatted"

      # Determine maximum number of lines
      max_lines=$((''${#file1_lines[@]} > ''${#file2_lines[@]} ? ''${#file1_lines[@]} : ''${#file2_lines[@]}))

      # Print the formatted output in a table format with left alignment
      for (( i=0; i<max_lines; i++ )); do
        file1_print="''${file1_lines[$i]:-}"
        file2_print="''${file2_lines[$i]:-}"

        printf "%-60s    |       %-60s\n" "$file1_print" "$file2_print"
      done

      # Perform hex diff between the selected files
      hex_diff "$file1" "$file2"


      echo "Compared Files:"
      # Print the formatted output in a table format with left alignment
      for (( i=0; i<max_lines; i++ )); do
        file1_print="''${file1_lines[$i]:-}"
        file2_print="''${file2_lines[$i]:-}"

        printf "%-60s    | %-60s\n" "$file1_print" "$file2_print"
      done
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

    # xvnc-iphone
    (pkgs.writeShellScriptBin "xvnc-iphone" ''
      #!/bin/sh

      echo -e "\n\033[1;31m\t⚠️  WARNING! ⚠️\033[0m"
      echo -e "\033[1;33m\tThis script is currently INSECURE over public networks.\033[0m"
      echo -e "\033[1;33m\tUse at your own risk!\033[0m\n"

      # Function to prompt for iPhone IP and save to config file
      prompt_and_save_ip() {
          read -p "Enter your iPhone's IP address: " IPHONE_IP
          mkdir -p ~/.config/xvnc-iphone
          echo "IPHONE_IP=$IPHONE_IP" > ~/.config/xvnc-iphone/config
      }

      # Function to prompt for iPhone password and save to config file
      prompt_and_save_password() {
          read -s -p "Enter your iPhone's password: " IPHONE_PASSWD
          echo
          echo "IPHONE_PASSWD=$IPHONE_PASSWD" >> ~/.config/xvnc-iphone/config
      }

      # Function to validate IP address
      validate_ip() {
          if [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
              return 0
          else
              return 1
          fi
      }

      # Function to clean up config file
      cleanup_config() {
          # Remove duplicate entries and keep only the first occurrence of each variable
          awk '!seen[$1]++' "$CONFIG_FILE" > "''${CONFIG_FILE}.tmp" && mv "''${CONFIG_FILE}.tmp" "$CONFIG_FILE"
      }

      # Function to find TigerVNC Viewer app
      find_tigervnc_app() {
          local tigervnc_app=$(find /Applications -maxdepth 1 -name "TigerVNC Viewer*.app" | head -n 1)
          if [ -z "$tigervnc_app" ]; then
              echo "TigerVNC Viewer app not found in /Applications"
              exit 1
          fi
          echo "$tigervnc_app"
      }

      # Function to launch VNC viewer
      launch_vnc_viewer() {
          local host="$1"
          local port="$2"

          if [[ "$OSTYPE" != "darwin"* ]]; then
              mkdir -p ~/.vnc
              if command -v vncpasswd >/dev/null 2>&1; then
                  echo "$IPHONE_PASSWD" | vncpasswd -f > ~/.vnc/passwd
                  chmod 600 ~/.vnc/passwd
              else
                  echo "Warning: vncpasswd not found. VNC connection may fail."
              fi
          fi

          pkill -f "vncviewer"

          if [[ "$OSTYPE" == "darwin"* ]]; then
              vncviewer "$host:$port" >/dev/null 2>&1 &
          elif [ -f ~/.vnc/passwd ]; then
              vncviewer -passwd ~/.vnc/passwd "$host:$port" >/dev/null 2>&1 &
          else
              vncviewer "$host:$port" >/dev/null 2>&1 &
          fi
      }

      # Check if config file exists and read IP and password
      CONFIG_FILE=~/.config/xvnc-iphone/config
      if [ -f "$CONFIG_FILE" ]; then
          cleanup_config
          source "$CONFIG_FILE"
          if ! validate_ip "$IPHONE_IP"; then
              echo "Invalid IP in config file. Please enter a new one."
              prompt_and_save_ip
          fi
          if [ -z "$IPHONE_PASSWD" ]; then
              echo "iPhone password not found in config file. Please enter it."
              prompt_and_save_password
          fi
          if [ -z "$VNC_PORT" ]; then
              echo "VNC_PORT=5901" >> "$CONFIG_FILE"
          fi
      else
          prompt_and_save_ip
          prompt_and_save_password
          echo "VNC_PORT=5901" >> "$CONFIG_FILE"
      fi

      # iPhone SSH details
      IPHONE_USER="mobile"
      VNC_PORT=''${VNC_PORT:-5901}  # Use the value from config or default to 5901
      START_X_SERVER_SCRIPT_CONTENT='#!/bin/bash

      # Full paths to commands
      XORG="/usr/bin/Xorg"
      XTERM="/usr/bin/xterm"

      # Kill any existing Xvnc, X, or window manager processes
      killall Xvnc >/dev/null 2>&1
      killall Xorg >/dev/null 2>&1
      killall fluxbox >/dev/null 2>&1

      # Check if VNC password is set
      if [ ! -f ~/.vnc/passwd ]; then
          echo "Please set your VNC password."
          if [[ "$OSTYPE" == "darwin"* ]]; then
              # macOS specific method
              echo
              sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -clientopts -setvnclegacy -vnclegacy yes -setvncpw -vncpw "$IPHONE_PASSWD"
          else
              # For non-macOS systems, use vncpasswd
              vncpasswd >/dev/null 2>&1
          fi
      fi

      # Remove any existing X lock files
      rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 >/dev/null 2>&1

      # Start VNC server with specified port
      Xvnc -PasswordFile ~/.vnc/passwd :1 -rfbport '$VNC_PORT' >/dev/null 2>&1 &

      # Wait for Xvnc to start
      sleep 5

      # Set up VNC and Fluxbox configurations
      mkdir -p ~/.vnc
      touch ~/.vnc/xstartup
      echo "#!/bin/sh" > ~/.vnc/xstartup
      echo "export DISPLAY=:1" >> ~/.vnc/xstartup
      echo "fluxbox &" >> ~/.vnc/xstartup
      echo "$XTERM &" >> ~/.vnc/xstartup
      chmod +x ~/.vnc/xstartup

      mkdir -p ~/.fluxbox
      touch ~/.fluxbox/startup
      echo "#!/bin/sh" > ~/.fluxbox/startup
      echo "x-terminal-emulator &" >> ~/.fluxbox/startup
      echo "exec /usr/bin/fluxbox" >> ~/.fluxbox/startup
      chmod +x ~/.fluxbox/startup

      # Set DISPLAY variable in zshrc and bashrc
      echo "export DISPLAY=:1" >> ~/.zshrc
      echo "export DISPLAY=:1" >> ~/.bashrc

      # Set DISPLAY variable for VNC
      export DISPLAY=:1

      # Start Fluxbox for X11
      fluxbox >/dev/null 2>&1 &

      # Launch an example application (xterm) on display :1
      $XTERM -display :1 >/dev/null 2>&1 &

      # Optional: Add more applications to launch as needed

      # Provide connection information to the user
      echo "You can use a VNC client to connect to your device locally at 127.0.0.1::'$VNC_PORT' or remotely using TigerVNC."
      '

      # Configure SSH to use key-based authentication for the iPhone
      cat << EOF > ~/.ssh/config
      Host iphone
          HostName ''${IPHONE_IP}
          User ''${IPHONE_USER}
          IdentityFile ~/.ssh/id_rsa_iphone
      EOF

      # Generate SSH key if it doesn't exist
      if [ ! -f ~/.ssh/id_rsa_iphone ]; then
          ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_iphone -N ""
          ssh-copy-id -i ~/.ssh/id_rsa_iphone.pub iphone
      fi

      # Create a temporary file for the script content
      TEMP_SCRIPT=$(mktemp)
      echo "$START_X_SERVER_SCRIPT_CONTENT" > "$TEMP_SCRIPT"

      # Use the configured SSH host to copy the script, make it executable, and run it
      echo "Copying start_x_server.sh to iPhone, making it executable, and running it..."
      ssh -i ~/.ssh/id_rsa_iphone iphone "cat > /var/mobile/start_x_server.sh && chmod +x /var/mobile/start_x_server.sh && /var/mobile/start_x_server.sh &" < "$TEMP_SCRIPT"

      # Remove the temporary file
      rm "$TEMP_SCRIPT"

      # Wait for the X server to start
      sleep 5

      # VNC server address
      VNC_SERVER="$IPHONE_IP"

      # Launch VNC viewer
      launch_vnc_viewer "$VNC_SERVER" "$VNC_PORT"

      # Try to connect to VNC server
      if nc -z $VNC_SERVER $VNC_PORT >/dev/null 2>&1; then
          echo "Successfully connected to VNC server."
          echo "To connect to your iPhone's VNC server, use the following details:"
          echo "iPhone IP: $IPHONE_IP"
          echo "VNC Port: $VNC_PORT"
          exit 0
      else
          echo "Failed to connect to VNC server."
          echo "To connect to your iPhone's VNC server, use the following details:"
          echo "iPhone IP: $IPHONE_IP"
          echo "VNC Port: $VNC_PORT"
      fi

      read -p "Would you like to enter a different iPhone IP address? (y/n): " RETRY
      if [[ $RETRY =~ ^[Yy]$ ]]; then
          prompt_and_save_ip
          prompt_and_save_password
          exec "$0"  # Restart the script with the new IP and password
      fi
      exit 1
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
    ];
  };
}
