{
  pkgs,
  config,
  lib,
  ...
}:

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
  borders = "${homebrewPath}/borders";
  skhd = "${homebrewPath}/skhd";
  inherit (config.colorScheme) colors;
in
{
  # Copy Home-Manager Nix GUI apps to ~/Applications on darwin:
  home.activation = {
    rsync-home-manager-applications = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rsyncArgs="--archive --checksum --chmod=-w --copy-unsafe-links --delete"
      apps_source="$genProfilePath/home-path/Applications"
      moniker="Home Manager Trampolines"
      app_target_base="${config.home.homeDirectory}/Applications"
      app_target="$app_target_base/$moniker"
      mkdir -p "$app_target"
      ${pkgs.rsync}/bin/rsync $rsyncArgs "$apps_source/" "$app_target"
    '';
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      #allowUnfreePredicate = (_: true);
      allowUnsupportedSystem = false;
      allowBroken = false;
    };
  };

  home.packages = with pkgs; [
    # autotiling
    #ncdu
    calcurse
    chatgpt-cli
    cowsay
    cmus
    cmusfm
    bat
    newsboat
    audacity
    nmap
    neofetch
    darwin.cctools-port # is it needed tho?
    tshark
    termshark
    # wireshark
    # nmapsi4
    #ruby
    obsidian
    sl
    fzf
    lavat
    libsForQt5.ki18n
    #vscode
    # bonsai #Only available on mac?
    rustc
    cargo
    utm
    mas
    vscode
    audacity
    #yazi to upgrade temporarily with homebrew
    thefuck
    zsh-completions
    zoom-us
    unar
    # python39
    (pkgs.python311.withPackages (ps: [
      ps.tkinter
      #ps.pygame
      ps.cx-freeze
      # ps.pep517
      # ps.build
      #ps.i3ipc
      ps.matplotlib
    ]))

    # rebuild
    (pkgs.writeShellScriptBin "rebuild" ''
      # NIXY(aarch64-darwin)
      reset_launchpad=false
      run_fix_wm=false

      while [[ $# -gt 0 ]]; do
        case "$1" in
          -r)
            echo "User entered -r argument."
            echo "Will reset Launchpad after rebuild."
            reset_launchpad=true
            ;;
          -f)
            echo "User entered -f argument."
            echo "Will run 'fix-wm' after rebuild."
            run_fix_wm=true
            ;;
          *)
            echo "Unknown argument: $1"
            ;;
        esac
        shift
      done

      if [ "$reset_launchpad" = true ]; then
        echo "Resetting Launchpad!"
        defaults write com.apple.dock ResetLaunchPad -bool true
      fi

      echo "Rebuilding..."
      cd ~/.dotfiles
      darwin-rebuild switch --show-trace --flake .#NIXY
      #home-manager switch --show-trace --flake .#alex@NIXY
      echo "Done."

      if [ "$run_fix_wm" = true ]; then
        echo "Running 'fix-wm'..."
        fix-wm
        echo "Completed 'fix-wm'."
      else
        echo "Skipping 'fix-wm' as -f argument not provided."
      fi

      date +"%I:%M:%S %p"
    '')

    #update
    (pkgs.writeShellScriptBin "update" ''
      cd ~/.dotfiles
      git fetch
      git pull
      git merge origin/main
      echo "Enter a commit message:"
      read commit_message
      git add .
      git commit -m "$commit_message"
      git push origin main
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

    # #singleusermode on ##FIXME: Totally broken atm.
    # (pkgs.writeShellScriptBin "sumode" ''
    # if [[ "$1" == "on" ]]; then
    #   echo "User entered 'on' argument."
    #   echo "Turning on Single User Mode..."
    #   sudo nvram boot-args="-arm64e_preview_abi amfi_get_out_of_my_way=0x80 -v -s"
    # elif [[ "$1" == "off" ]]; then
    #   echo "User entered 'off' argument."
    #   echo "Turning off Single User Mode..."
    #   sudo nvram boot-args="-arm64e_preview_abi amfi_get_out_of_my_way=0x80 -v"
    # fi
    # if [[ "$1" == "on" || "$1" == "off" ]]; then
    #   echo "Completed. Your boot args are listed below:"
    #   nvram -p | grep boot-args
    #   echo "Done. Rebooting..."
    #   sleep 2
    #   sudo reboot
    # else
    #   echo "No argument provided. Please add arguments 'on' or 'off' for this command."
    #   echo "Your current boot args are listed below:"
    #   nvram -p | grep boot-args
    # fi
    # '')

    #json2nix converter
    (pkgs.writeScriptBin "json2nix" ''
      ${pkgs.python3}/bin/python ${
        pkgs.fetchurl {
          url = "https://gist.githubusercontent.com/Scoder12/0538252ed4b82d65e59115075369d34d/raw/e86d1d64d1373a497118beb1259dab149cea951d/json2nix.py";
          hash = "sha256-ROUIrOrY9Mp1F3m+bVaT+m8ASh2Bgz8VrPyyrQf9UNQ=";
        }
      } $@
    '')

    #fix-wm
    (pkgs.writeShellScriptBin "fix-wm" ''
      ${yabai} --stop-service && ${yabai} --start-service #helps with adding initial service
      ${skhd} --stop-service && ${skhd} --start-service #otherwise, I have to run manually first time.
      # brew services restart felixkratz/formulae/sketchybar
      launchctl stop org.pqrs.karabiner.karabiner_console_user_server && launchctl start org.pqrs.karabiner.karabiner_console_user_server
      xrdb -merge ~/.Xresources
      ${sketchybar} --reload # allows start_programs_correctly" package to run.
      rm /tmp/fullscreen_state /tmp/dock_state /tmp/gaps_state /tmp/sketchybar_state /tmp/menubar_state /tmp/darkmode_state  #remove statefiles
      echo -ne '\n' | sudo pkill "Background Music" && "/Applications/Background Music.app/Contents/MacOS/Background Music" > /dev/null 2>&1 &
      dismiss-notifications
      # NOT WORKING CORRECTLY: (Should only kill apps that are not injected with paintcan..)
      # if [ ! -f "/tmp/programs_started_state" ]; then
      #   ${pkgs.start_programs_correctly}/bin/start_programs_correctly #run only once.
      #   echo "programs started already with fix-wm." > "/tmp/programs_started_state"
      # fi
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

    #assign-inputs
    (pkgs.writeShellScriptBin "assign-inputs" ''
      # Specify the input file path
      input_file=~/.dotfiles/users/alex/NIXY/sketchybar/cal-output.txt

      # Read input from the file
      while IFS= read -r line; do
          # Extract variable name and content
          var_name=$(echo "$line" | cut -d ':' -f 1)
          var_content="$(echo "$line" | cut -d ':' -f 2- | sed 's/^[[:space:]]*//')"

          # Assign content to variable
          declare "$var_name=$var_content"

          # Print variable name and content
          echo "Variable: $var_name"
          echo "Content: $var_content"
      done < "$input_file"

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
                ${yabai} -m config external_bar all:42:0
            fi
          else
            if [ "$gaps_status" = "on" ]; then
                ${yabai} -m config external_bar all:0:0
            else
                ${yabai} -m config external_bar all:0:0
            fi
          fi
          ${borders} background_color=0x11${colors.base00} blur_radius=15.0
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
        ${borders} style=round width=2.0 #order=above
        ${sketchybar} --bar corner_radius=10
        ${sketchybar} --bar margin=13
        ${sketchybar} --bar y_offset=13
      }

      off() {
        ${yabai} -m config top_padding     0
        ${yabai} -m config bottom_padding  0
        ${yabai} -m config left_padding    0
        ${yabai} -m config right_padding   0
        ${yabai} -m config window_gap      5
        if [ "$sketchybar_state" == "off" ]; then
          ${yabai} -m config external_bar all:0:0
        else
          ${yabai} -m config external_bar all:42:0
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
          local gaps_status=$(cat "$gaps_state_file")
          local sketchybar_status=$(cat "$sketchybar_state_file")

          update_spaces_and_bar() {
            # Check if sketchybar_state file exists
            if [ -f "/tmp/sketchybar_state" ]; then
                sketchybar_state=$(cat "/tmp/sketchybar_state")
            else
                sketchybar_state="on"
            fi

            # Determine external_bar configuration based on sketchybar and gaps status
            if [ "$sketchybar_state" = "on" ]; then
                if [ "$gaps_status" = "on" ]; then
                    ${yabai} -m config external_bar all:50:0
                else
                    ${yabai} -m config external_bar all:42:0
                fi
            else
                if [ "$gaps_status" = "on" ]; then
                    ${yabai} -m config external_bar all:0:0
                else
                    ${yabai} -m config external_bar all:0:0
                fi
            fi

            ${borders} background_color=0x11${colors.base00} blur_radius=15.0
          }
          if [ $# -eq 0 ]; then
              # No arguments provided, toggle based on current state
              if [ "$dock_status" = "true" ]; then
                  osascript -e 'tell application "System Events" to set autohide of dock preferences to false'
                  echo "Dock toggled on"
                  echo "on" > "$dock_state_file"  # Save state to file
                  update_spaces_and_bar
              else
                  osascript -e 'tell application "System Events" to set autohide of dock preferences to true'
                  echo "Dock toggled off"
                  echo "off" > "$dock_state_file"  # Save state to file
                  update_spaces_and_bar
              fi

          elif [ "$1" = "on" ]; then
              if [ "$dock_status" = "true" ]; then
                  osascript -e 'tell application "System Events" to set autohide of dock preferences to false'
                  echo "Dock toggled on"
                  echo "on" > "$dock_state_file"  # Save state to file
                  update_spaces_and_bar
              else
                  echo "Dock is already toggled on"
              fi
          elif [ "$1" = "off" ]; then
              if [ "$dock_status" = "false" ]; then
                  osascript -e 'tell application "System Events" to set autohide of dock preferences to true'
                  echo "Dock toggled off"
                  echo "off" > "$dock_state_file"  # Save state to file
                  update_spaces_and_bar
              else
                  echo "Dock is already toggled off"
              fi
          else
              # Invalid argument, toggle based on current state
              if [ "$dock_status" = "true" ]; then
                  osascript -e 'tell application "System Events" to set autohide of dock preferences to false'
                  echo "Dock toggled on"
                  echo "on" > "$dock_state_file"  # Save state to file
                  update_spaces_and_bar
              else
                  osascript -e 'tell application "System Events" to set autohide of dock preferences to true'
                  echo "Dock toggled off"
                  echo "off" > "$dock_state_file"  # Save state to file
                  update_spaces_and_bar
              fi
          fi
      }

      # Example usage
      toggle_dock "$1"
    '')

    #toggle-menubar
    (pkgs.writeShellScriptBin "toggle-menubar" ''
      # Function to toggle the macOS menu bar
      toggle_menubar() {
          current_opacity=$(osascript -e 'tell application "System Events" to tell dock preferences to get autohide menu bar')
          menubar_state_file="/tmp/menubar_state"
          if [[ "$current_opacity" == "true" ]]; then
              osascript -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to false'
              ${yabai} -m config menubar_opacity 1.0
              echo "Menu bar turned ON"
              echo "on" > "$menubar_state_file"
          else
              ${yabai} -m config menubar_opacity 0.0
              osascript -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to true'
              echo "Menu bar turned OFF"
              echo "off" > "$menubar_state_file"
          fi
      }

      # Main
      if [[ "$#" -eq 0 ]]; then
          toggle_menubar
      elif [[ "$#" -eq 1 && ($1 == "on" || $1 == "off") ]]; then
          if [[ "$1" == "on" ]]; then
              osascript -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to false'
              echo "Menu bar turned ON"
              echo "on" > "/tmp/menubar_state"
          else
              osascript -e 'delay 0.5' -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to true'
              echo "Menu bar turned OFF"
              echo "off" > "/tmp/menubar_state"
          fi
      else
          echo "Usage: $0 <on | off>"
          exit 1
      fi
    '')

    #toggle-float
    (pkgs.writeShellScriptBin "toggle-float" ''
      # Check if the script is provided with an argument
      if [ $# -eq 0 ]; then
        # Toggle between on/off states if no argument is provided
        floating_state_file="/tmp/floating_state"
        if [ -f "$floating_state_file" ] && grep -q "on" "$floating_state_file"; then
          set_arg="off"
        else
          set_arg="on"
        fi
      else
        set_arg="$1"
      fi

      fullscreen_state_file="/tmp/fullscreen_state"
      window_id=$(${yabai} -m query --windows --window | ${jq} -r '."id"')

      # Function to check if the current window is in fullscreen mode
      function is_fullscreen() {
          grep -q "id: $window_id fullscreen: on" "$fullscreen_state_file"
      }

      # Function to check if the current window is floating
      function is_floating() {
          ${yabai} -m query --windows --window | ${jq} -r '."is-floating"' | grep -q "1"
      }

      # Check the value of the argument
      if [ "$set_arg" = "on" ]; then
        if is_fullscreen; then
          echo "Cannot toggle float on: window is in fullscreen mode."
        else
          ${yabai} -m window --toggle float; ${yabai} -m window --grid 60:60:5:5:50:50
          echo "on" > "$floating_state_file"
        fi
      elif [ "$set_arg" = "off" ]; then
        if is_fullscreen; then
          echo "Cannot toggle float off: window is in fullscreen mode."
        else
          ${yabai} -m window --toggle float; ${yabai} -m window --grid 60:60:5:5:50:50
          echo "off" > "$floating_state_file"
        fi
      else
        echo "Usage: $0 <on|off>"
        exit 1
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

          ${borders} apply-to=$window_id width=0.0 style=square order=below background_color=0xff${colors.base00} blur_radius=0.0 active_color=0xff${colors.base00} inactive_color=0xff${colors.base00}
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
              ${borders} apply-to=$window_id width=5.0 style=square background_color=0x11${colors.base00} blur_radius=15.0 active_color=0xff${colors.base07} inactive_color=0xff${colors.base05} #order=above 
          else
              ${borders} apply-to=$window_id width=2.0 style=round  background_color=0x11${colors.base00} blur_radius=15.0 active_color=0xff${colors.base07} inactive_color=0xff${colors.base05} #order=above 
          fi

          # ${borders} apply-to=$window_id width=2 style=round background_color=0x11${colors.base00} blur_radius=15.0 active_color=0xff${colors.base07} inactive_color=0xff${colors.base05} #order=above 
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
  ];
}
