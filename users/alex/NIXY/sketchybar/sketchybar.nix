{ config, pkgs, ... }:

let
  inherit (config.colorScheme) colors;
  nixy_colors = pkgs.writeShellScript "nixy-colors" ''
    export PURPLE="0xff${colors.base0C}" # Border color.
    export GREY="0xff${colors.base0C}"  # idk what this is for
    export TRANSPARENT=0x00000000
    export WHITE="0xff${colors.base05}"
    export BLUE="0xE6${colors.base0D}"  # Changes background of drop-down windows 
    export MAGENTA="0xff${colors.base0E}" # Changed border color? NO
    export ORANGE=0xff${colors.base0A}
    export TEMPUS="0xE6${colors.base02}" # backgrounds of RAM, spotify, apple logo, time and date
    export STATUS="0xE6${colors.base00}" #BACKGROUND of bar. make same as alacritty.
    export SPACEBG=0xFF808080 #Didn't change much?
    export MIDNIGHT="0xE6${colors.base03}" # Only worked on the mail icon?
  '';

  print_spaces = pkgs.writeShellScript "print_spaces" ''
    # Query for spaces with windows
    spaces_with_windows=($(yabai -m query --spaces | jq -r '.[] | select(.windows | length > 0) | .label'))

    # Query for the active space
    active_space=$(yabai -m query --spaces --space | jq -r '.label')

    # active space per display
    # Query for the total number of displays
    total_displays=$(yabai -m query --displays | jq 'length')

    # Initialize an array to store active display spaces
    active_display_spaces=()

    # Loop through each display
    for ((display=1; display<=$total_displays; display++)); do
        # Query for spaces on the current display that are visible
        spaces=$(yabai -m query --spaces --display $display | jq -r '.[] | select(.["is-visible"] == true) | .label')

        # Add visible spaces to the active_display_spaces array
        for space in $spaces; do
            active_display_spaces+=("$space")
        done
    done

    # Combine spaces with windows and active spaces on all displays
    print=($(echo "''${spaces_with_windows[@]}" "''${active_display_spaces[@]}" | tr ' ' '\n' | sort -u | sort -t '_' -k 2n))
    echo "''${print[@]}"
  '';

  spaces_focus = pkgs.writeShellScript "spaces_focus" ''
      SPACES_FOCUS() {
      # Define variables
      # How many displays are there?
      max_displays=$(yabai -m query --displays | jq 'max_by(.index) | .index')
      # How many spaces are there?
      max_spaces=$(yabai -m query --spaces | jq 'max_by(.index) | .index')
      # Current active space!
      current_space=$(yabai -m query --spaces --space | jq -r '.index')
      # Current active display!
      current_display=$(yabai -m query --displays --display | jq -r '.index')
      # Accept desired space number as input argument
      # if [ $# -ne 1 ]; then
      # echo "Usage: $0 <desired_space_number>"
      # exit 1
      # fi
      n=$1
      # Focus on a space
      # If space n is not created, create it
      if [ $n -gt $max_spaces ]; then
        iterations=$((n - max_spaces))
        for ((i=0; i<iterations; i++)); do
          yabai -m space --create
          #reassign max_spaces:
          max_spaces=$(yabai -m query --spaces | jq 'max_by(.index) | .index')
        done
      fi
      # then, focus on space n
      yabai -m space --focus $n
    }
      export -f SPACES_FOCUS
  '';

  spaces_clear = pkgs.writeShellScript "spaces_clear" ''
        SPACES_CLEAR() {
        # count all spaces.
        # all=length(spaces)
        max_spaces=$(yabai -m query --spaces | jq 'max_by(.index) | .index')

        # Query for the highest space containing a window
        lastwindow=$(yabai -m query --spaces | jq '[.[] | select(.windows | length > 0) | .index] | max')

        # remaining=max_spaces - last space with a window
        remaining=$((max_spaces - lastwindow))

        # from last to
        for ((i=1; i<=$remaining; i++))
        do
            yabai -m space $(($lastwindow + 1)) --destroy
        done
    }
    export -f SPACES_CLEAR
  '';

  move_to_space = pkgs.writeShellScript "move_to_space" ''
    MOVE_TO_SPACE() {
    # Define variables
    # How many displays are there?
    max_displays=$(yabai -m query --displays | jq 'max_by(.index) | .index')
    # How many spaces are there?
    max_spaces=$(yabai -m query --spaces | jq 'max_by(.index) | .index')
    # Current active space!
    current_space=$(yabai -m query --spaces --space | jq -r '.index')
    # Current active display!
    current_display=$(yabai -m query --displays --display | jq -r '.index')
    # Accept desired space number as input argument
    # if [ $# -ne 1 ]; then
    # echo "Usage: $0 <desired_space_number>"
    # exit 1
    # fi
    n=$1
    # Focus on a space
    # If space n is not created, create it
    if [ $n -gt $max_spaces ]; then
      iterations=$((n - max_spaces))
      for ((i=0; i<iterations; i++)); do
        yabai -m space --create
        #reassign max_spaces:
        max_spaces=$(yabai -m query --spaces | jq 'max_by(.index) | .index')
      done
    fi
    # then, move window to space n
    yabai -m window --space $n
    # then, focus on space n
    yabai -m space --focus $n
    }
    export -f MOVE_TO_SPACE
  '';

  dismiss_notifications = pkgs.writeShellScript "dismiss_notifications" ''
      DISMISS_NOTIFICATIONS() {
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
    }
    export -f DISMISS_NOTIFICATIONS
  '';

  toggle_menubar = pkgs.writeShellScript "toggle_menubar" ''
    TOGGLE_MENUBAR() {
            # Function to toggle the macOS menu bar
      toggle_menubar() {
          current_opacity=$(osascript -e 'tell application "System Events" to tell dock preferences to get autohide menu bar')
          if [[ "$current_opacity" == "true" ]]; then
              osascript -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to false'
              yabai -m config menubar_opacity 1.0
              echo "Menu bar turned ON"
          else
              osascript -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to true'
              yabai -m config menubar_opacity 0.0
              echo "Menu bar turned OFF"
          fi
      }

            # Main
      if [[ "$#" -eq 0 ]]; then
          toggle_menubar
      elif [[ "$#" -eq 1 && ($1 == "on" || $1 == "off") ]]; then
          if [[ "$1" == "on" ]]; then
              osascript -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to false'
               yabai -m config menubar_opacity 1.0
              echo "Menu bar turned ON"
          else
              osascript -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to true'
                yabai -m config menubar_opacity 0.0
              echo "Menu bar turned OFF"
          fi
      else
          echo "Usage: $0 <on | off>"
          exit 1
      fi
      }
      export -f TOGGLE_MENUBAR
  '';

  toggle_sketchybar = pkgs.writeShellScript "toggle_sketchybar" ''
    TOGGLE_SKETCHYBAR() {
    toggle_sketchybar() {
         local hidden_status=$(sketchybar --query bar | jq -r '.hidden')

         if [ "$hidden_status" == "off" ]; then
             STATE="on"
             sketchybar --bar hidden=on
             yabai -m config external_bar all:0:0
         else
             STATE="off"
             sketchybar --bar hidden=off
             yabai -m config external_bar all:45:0
         fi
     }

     # Example usage
     toggle_sketchybar
    }
    export -f TOGGLE_SKETCHYBAR
  '';

  toggle_darkmode = pkgs.writeShellScript "toggle_darkmode" ''
        TOGGLE_DARKMODE() {
          osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to not dark mode'
    }
          export -f TOGGLE_DARKMODE
  '';

  toggle_gaps = pkgs.writeShellScript "toggle_gaps" ''
    TOGGLE_GAPS() {

                # Initialize a variable to store the current state
    state_file="/tmp/gaps_state"

    # Initialize the state file if it doesn't exist
    if [ ! -f "$state_file" ]; then
        echo "off" > "$state_file"
    fi

    # Read the current state from the state file
    gaps_state=$(cat "$state_file")

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
        yabai -m config top_padding     15
        yabai -m config bottom_padding  15
        yabai -m config left_padding    15
        yabai -m config right_padding   15
        yabai -m config window_gap      15
        borders style=round
    }

    off() {
        yabai -m config top_padding     0
        yabai -m config bottom_padding  0
        yabai -m config left_padding    0
        yabai -m config right_padding   0
        yabai -m config window_gap      5
        borders style=square
    }

    if [ "$#" -eq 0 ]; then
        toggle
    elif [ "$1" == "on" ]; then
        on
        echo "on" > "$state_file"
    elif [ "$1" == "off" ]; then
        off
        echo "off" > "$state_file"
    else
        echo "Invalid argument. Usage: $0 [on|off]"
    fi
    }
    export -f TOGGLE_GAPS
  '';
in
{
  # ALL MUST BE MARKED AS EXECUTABLE!
  xdg.configFile."sketchybar/sketchybarrc".source = ./sketchybarrc.sh;
  xdg.configFile."sketchybar/icons.sh".source = ./icons.sh;
  xdg.configFile."sketchybar/colors.sh".source = nixy_colors;
  xdg.configFile."sketchybar/plugins/print_spaces.sh".source = print_spaces;
  xdg.configFile."sketchybar/plugins/spaces_focus.sh".source = spaces_focus;
  xdg.configFile."sketchybar/plugins/spaces_clear.sh".source = spaces_clear;
  xdg.configFile."sketchybar/plugins/move_to_space.sh".source = move_to_space;
  xdg.configFile."sketchybar/plugins/dismiss_notifications.sh".source = dismiss_notifications;
  xdg.configFile."sketchybar/plugins/toggle_menubar.sh".source = toggle_menubar;
  xdg.configFile."sketchybar/plugins/toggle_sketchybar.sh".source = toggle_sketchybar;
  xdg.configFile."sketchybar/plugins/toggle_darkmode.sh".source = toggle_darkmode;
  xdg.configFile."sketchybar/plugins/toggle_gaps.sh".source = toggle_gaps;
  xdg.configFile."sketchybar/plugins/apple.sh".source = ./plugins/apple.sh;
  xdg.configFile."sketchybar/plugins/battery.sh".source = ./plugins/battery.sh;
  xdg.configFile."sketchybar/plugins/cpu.sh".source = ./plugins/cpu.sh;
  xdg.configFile."sketchybar/plugins/datetime.sh".source = ./plugins/datetime.sh;
  xdg.configFile."sketchybar/plugins/mail.sh".source = ./plugins/mail.sh;
  xdg.configFile."sketchybar/plugins/ram.sh".source = ./plugins/ram.sh;
  xdg.configFile."sketchybar/plugins/space.sh".source = ./plugins/space.sh;
  xdg.configFile."sketchybar/plugins/front_app.sh".source = ./plugins/front_app.sh;
  xdg.configFile."sketchybar/plugins/speed.sh".source = ./plugins/speed.sh;
  xdg.configFile."sketchybar/plugins/spotify.sh".source = ./plugins/spotify.sh;
  xdg.configFile."sketchybar/plugins/cava.sh".source = ./plugins/cava.sh;
  xdg.configFile."sketchybar/plugins/cava.conf".source = ./plugins/cava.conf;
  xdg.configFile."sketchybar/plugins/time.sh".source = ./plugins/time.sh;
  xdg.configFile."sketchybar/plugins/volume.sh".source = ./plugins/volume.sh;
  xdg.configFile."sketchybar/plugins/wifi.sh".source = ./plugins/wifi.sh;
  # Specify executable for each file
  xdg.configFile."sketchybar/sketchybarrc".executable = true;
  xdg.configFile."sketchybar/icons.sh".executable = true;
  xdg.configFile."sketchybar/colors.sh".executable = true;
  xdg.configFile."sketchybar/plugins/print_spaces.sh".executable = true;
  xdg.configFile."sketchybar/plugins/spaces_focus.sh".executable = true;
  xdg.configFile."sketchybar/plugins/spaces_clear.sh".executable = true;
  xdg.configFile."sketchybar/plugins/move_to_space.sh".executable = true;
  xdg.configFile."sketchybar/plugins/dismiss_notifications.sh".executable = true;
  xdg.configFile."sketchybar/plugins/toggle_menubar.sh".executable = true;
  xdg.configFile."sketchybar/plugins/toggle_sketchybar.sh".executable = true;
  xdg.configFile."sketchybar/plugins/toggle_darkmode.sh".executable = true;
  xdg.configFile."sketchybar/plugins/toggle_gaps.sh".executable = true;
  xdg.configFile."sketchybar/plugins/apple.sh".executable = true;
  xdg.configFile."sketchybar/plugins/battery.sh".executable = true;
  xdg.configFile."sketchybar/plugins/cpu.sh".executable = true;
  xdg.configFile."sketchybar/plugins/datetime.sh".executable = true;
  xdg.configFile."sketchybar/plugins/mail.sh".executable = true;
  xdg.configFile."sketchybar/plugins/ram.sh".executable = true;
  xdg.configFile."sketchybar/plugins/space.sh".executable = true;
  xdg.configFile."sketchybar/plugins/front_app.sh".executable = true;
  xdg.configFile."sketchybar/plugins/speed.sh".executable = true;
  xdg.configFile."sketchybar/plugins/spotify.sh".executable = true;
  xdg.configFile."sketchybar/plugins/cava.sh".executable = true;
  xdg.configFile."sketchybar/plugins/cava.conf".executable = true;
  xdg.configFile."sketchybar/plugins/time.sh".executable = true;
  xdg.configFile."sketchybar/plugins/volume.sh".executable = true;
  xdg.configFile."sketchybar/plugins/wifi.sh".executable = true;
}
