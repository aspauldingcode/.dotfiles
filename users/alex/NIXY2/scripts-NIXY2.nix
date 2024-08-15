{ pkgs, ... }:

{ 
  home = {
    packages = with pkgs; [
    #screenshot
    (pkgs.writeShellScriptBin "screenshot" ''
      # Specify the full path to your desktop directory
      output_directory="$HOME/Desktop"

      # Get the list of output names
      output_names=$(swaymsg -t get_outputs | jq -r '.[].name')

      # Loop through each output and save its contents to the desktop directory
      for output_name in $output_names
      do
          output_file="$output_directory/Screenshot $(date '+%Y-%m-%d at %I.%M.%S %p') $output_name.png"
          grim -o $output_name "$output_file"
      done      
    '')
    #maximize (FIXME maximize sway windows to window size rather than fullscreen)
    (pkgs.writeShellScriptBin "maximize" ''
      # un/maximize script for i3 and sway
      # bindsym $mod+m exec ~/.config/i3/maximize.sh

      WRKSPC_FILE=~/.config/wrkspc
      RESERVED_WORKSPACE=f
      MSG=swaymsg
      if [ "$XDG_SESSION_TYPE" == "x11"]
      then
        MSG=i3-msg
      fi

      # using xargs to remove quotes
      CURRENT_WORKSPACE=$($MSG -t get_workspaces | jq '.[] | select(.focused==true) | .name' | xargs)

      if [ -f "$WRKSPC_FILE" ]
      then # restore window back
        if [ "$CURRENT_WORKSPACE" != "$RESERVED_WORKSPACE" ]
        then
          RESERVED_WORKSPACE_EXISTS=$($MSG -t get_workspaces | jq '.[] .num' | grep "^$RESERVED_WORKSPACE$")
          if [ -z "$RESERVED_WORKSPACE_EXISTS" ]
          then
            notify-send "Reserved workspace $RESERVED_WORKSPACE does not exist. Noted."
            rm -f $WRKSPC_FILE
          else
            notify-send "Clean your workspace $RESERVED_WORKSPACE first."
          fi
        else
          # move the window back
          $MSG move container to workspace $(cat $WRKSPC_FILE)
          $MSG workspace number $(cat $WRKSPC_FILE)
          notify-send "Returned back to workspace $(cat $WRKSPC_FILE)."
          rm -f $WRKSPC_FILE
        fi
      else # send window to the reserved workspace
        if [ "$CURRENT_WORKSPACE" == "$RESERVED_WORKSPACE" ]
        then
          notify-send "You're already on reserved workspace $RESERVED_WORKSPACE."
        else
          # remember current workspace
          echo $CURRENT_WORKSPACE > $WRKSPC_FILE
          $MSG move container to workspace $RESERVED_WORKSPACE
          $MSG workspace $RESERVED_WORKSPACE
          notify-send "Saved workspace $CURRENT_WORKSPACE and moved to workspace $RESERVED_WORKSPACE."
        fi
      fi
    '')

      #fix-wm
      (pkgs.writeShellScriptBin "fix-wm" ''
        sway reload
        # Remove the initial states for gaps if the file exists
        [ -f /tmp/gaps_state ] && rm /tmp/gaps_state
        # Remove the waybar state file if it exists
        [ -f /tmp/waybar_state ] && rm /tmp/waybar_state
        toggle-gaps off && toggle-gaps on
        # systemctl --user restart pipewire.service
        # systemctl --user restart pipewire-pulse.service
        # way-displays --reload
        way-displays -g > /dev/null 2>&1
        toggle-nightlight on
        toggle-brightness on
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
      #wine-version
      (pkgs.writeShellScriptBin "wine-version" ''
        #!/bin/bash

        wine_version=$(wine --version | sed 's/^wine-//')
        system_reg_content=$(head -n 20 ~/.wine/system.reg)

        if [[ $system_reg_content == *"#arch=win64"* ]]; then
        echo "Wine wine-$wine_version win64"
        elif [[ $system_reg_content == *"#arch=win32"* ]]; then
        echo "Wine wine-$wine_version win32"
        else
        echo "Unknown-Architecture"
        fi
      '')

      # toggle-nightlight
      (pkgs.writeShellScriptBin "toggle-nightlight" ''
        #!/bin/sh

        statefile="/tmp/temperature_state"
        statefile_temp=$(tr -d '\0' < $statefile | head -n 1)
        current_temp=$(busctl --user get-property rs.wl-gammarelay / rs.wl.gammarelay Temperature | awk '{print $2}' | tr -d '\0' 2>/dev/null)

        turn_on() {
            # Turn on, by decreasing the temperature to the one recorded in statefile
            while [ "$(busctl --user get-property rs.wl-gammarelay / rs.wl.gammarelay Temperature | awk '{print $2}' | tr -d '\0' 2>/dev/null)" -gt "$statefile_temp" ]; do
                busctl --user -- call rs.wl-gammarelay / rs.wl.gammarelay UpdateTemperature n -50 > /dev/null 2>&1
            done
            echo "$statefile_temp" > $statefile
            echo "Nightlight is now on."
        }

        turn_off() {
            # Turn off by setting to default temp 6500 (maximum)
            while [ "$(busctl --user get-property rs.wl-gammarelay / rs.wl.gammarelay Temperature | awk '{print $2}' | tr -d '\0' 2>/dev/null)" -lt 6500 ]; do
                busctl --user -- call rs.wl-gammarelay / rs.wl.gammarelay UpdateTemperature n +50 > /dev/null 2>&1
            done
            echo "Nightlight is now off."
        }

        if [ "$(wc -l < $statefile)" -gt 1 ]; then
            echo "$statefile_temp" > $statefile
        fi

        if [ "$1" = "on" ]; then
            if [ "$current_temp" -lt 6500 ]; then
                echo "Nightlight is already on."
            else
                turn_on
            fi
        elif [ "$1" = "off" ]; then
            if [ "$current_temp" -eq 6500 ]; then
                echo "Nightlight is already off."
            else
                turn_off
            fi
        else
            if [ "$current_temp" -lt 6500 ]; then
                turn_off
            else
                turn_on
            fi
        fi
      '')

      # toggle-brightness FIXME: BROKEN AT THE MOMENT!
      #(pkgs.writeShellScriptBin "toggle-brightness" ''
      #  #!/bin/sh
      #
      #  statefile="/tmp/brightness_state"
      #  statefile_brightness=$(tr -d '\0' < $statefile | head -n 1)
      #  current_brightness=$(busctl --user get-property rs.wl-gammarelay / rs.wl.gammarelay Brightness | awk '{print $2}' | tr -d '\0' 2>/dev/null)
      #
      #  turn_on() {
      #      # Turn on, by decreasing the brightness to the one recorded in statefile
      #      while [ $(echo "$(busctl --user get-property rs.wl-gammarelay / rs.wl.gammarelay Brightness | awk '{print $2}' | tr -d '\0' 2>/dev/null) > $statefile_brightness" | bc -l) -eq 1 ]; do
#                busctl --user -- call rs.wl-gammarelay / rs.wl.gammarelay UpdateBrightness d -0.02 > /dev/null 2>&1
#            done
#            echo "$statefile_brightness" > $statefile
#            echo "Brightness is now on."
#        }

#        turn_off() {
#            # Turn off by setting to maximum brightness (1.0)
#            while [ $(echo "$(busctl --user get-property rs.wl-gammarelay / rs.wl.gammarelay Brightness | awk '{print $2}' | tr -d '\0' 2>/dev/null) < 1.0" | bc -l) -eq 1 ]; do
#                busctl --user -- call rs.wl-gammarelay / rs.wl.gammarelay UpdateBrightness d +0.02 > /dev/null 2>&1
#            done
#            echo "Brightness is now off."
#        }

#        if [ "$(wc -l < $statefile)" -gt 1 ]; then
#            echo "$statefile_brightness" > $statefile
#        fi

#        case "$1" in
#            on)
#                if [ $(echo "$current_brightness < 1.0" | bc -l) -eq 1 ]; then
#                    echo "Brightness is already on."
#                else
#                    turn_on
#                fi
#                ;;
#            off)
#                if [ $(echo "$current_brightness >= 1.0" | bc -l) -eq 1 ]; then
#                    echo "Brightness is already off."
#                else
#                    echo "$current_brightness" > $statefile
#                    turn_off
#                fi
#                ;;
#            *)
#                if [ $(echo "$current_brightness >= 1.0" | bc -l) -eq 1 ]; then
#                    turn_on
#                else
#                    echo "$current_brightness" > $statefile
#                    turn_off
#                fi
#                ;;
#        esac

      
      # toggle-waybar
      (pkgs.writeShellScriptBin "toggle-waybar" ''
        #!/bin/bash

        WAYBAR_STATE_FILE="/tmp/waybar_state"
        GAPS_STATE_FILE="/tmp/gaps_state"
        [ ! -f "$WAYBAR_STATE_FILE" ] && echo "on" > "$WAYBAR_STATE_FILE"
        [ ! -f "$GAPS_STATE_FILE" ] && echo "on" > "$GAPS_STATE_FILE"

        ensure_waybar_running() {
            if ! pgrep -x waybar > /dev/null; then
                echo "Waybar is not running. Starting it..."
                waybar > /dev/null 2>&1 &
                sleep 1
            fi
        }

        toggle_waybar() {
            current_state=$(cat "$WAYBAR_STATE_FILE")
            if [ "$current_state" = "on" ]; then
                if pgrep -x waybar > /dev/null; then
                    echo "Stopping Waybar..."
                    killall waybar
                fi
                echo "off" > "$WAYBAR_STATE_FILE"
                echo "Waybar is now disabled."
            else
                ensure_waybar_running
                echo "on" > "$WAYBAR_STATE_FILE"
                echo "Waybar is now enabled."
                
                # Handle gaps
                if [ "$(cat "$GAPS_STATE_FILE")" = "off" ]; then
                    echo "Gaps are off, toggling to gapless bar."
                    sleep 1
                    pkill -SIGUSR1 '^waybar$'
                fi
            fi
        }

        if [ "$1" = "on" ]; then
            if [ "$(cat "$WAYBAR_STATE_FILE")" = "off" ]; then
                toggle_waybar
            else
                echo "Waybar is already enabled."
            fi
        elif [ "$1" = "off" ]; then
            if [ "$(cat "$WAYBAR_STATE_FILE")" = "on" ]; then
                toggle_waybar
            else
                echo "Waybar is already disabled."
            fi
        elif [ -z "$1" ]; then
            toggle_waybar
        else
            echo "Usage: toggle-waybar [on|off]"
            exit 1
        fi
      '')

      #toggle-gaps
      (pkgs.writeShellScriptBin "toggle-gaps" ''
        #!/bin/sh

        # Define a file to keep track of the state
        gaps_state_file="/tmp/gaps_state"

        # Function to check current state and ensure file exists
        check_state() {
            if [ ! -f "$gaps_state_file" ]; then
                echo "State file not found. Creating it and setting gaps to on."
                echo "on" > "$gaps_state_file"
                turn_gaps_on
            fi
            state=$(cat "$gaps_state_file")
            echo "Gaps are currently $state"
        }

        # Ensure the state file exists and has valid content
        if [ ! -f "$gaps_state_file" ] || [ ! -s "$gaps_state_file" ]; then
            echo "on" > "$gaps_state_file"
        fi

        # Read the current state
        state=$(cat "$gaps_state_file")

        # Function to turn gaps on
        turn_gaps_on() {
            swaymsg -q gaps inner all set 10 > /dev/null 2>&1
            swaymsg -q gaps outer all set -2 > /dev/null 2>&1
            swaymsg -q corner radius all set 8 > /dev/null 2>&1
            
            # Check if waybar is running, if so, send SIGUSR1 to it.
            if pgrep -x "waybar" > /dev/null; then
                pkill -SIGUSR1 '^waybar$'
            fi
            echo "on" > "$gaps_state_file"
            echo "Gaps turned on"
        }

        # Function to turn gaps off
        turn_gaps_off() {
            swaymsg -q gaps inner all set 0 > /dev/null 2>&1
            swaymsg -q gaps outer all set 0 > /dev/null 2>&1
            swaymsg -q corner radius all set 0 > /dev/null 2>&1

            # Check if waybar is running, if so, send SIGUSR1 to it.
            if pgrep -x "waybar" > /dev/null; then
                pkill -SIGUSR1 '^waybar$'
            fi
            echo "off" > "$gaps_state_file"
            echo "Gaps turned off"
        }

        # Process command-line arguments
        case "$1" in
            on)
                turn_gaps_on
                ;;
            off)
                turn_gaps_off
                ;;
            status)
                check_state
                ;;
            *)
                # Toggle the state if no or invalid argument is provided
                if [ "$state" = "off" ]; then
                    turn_gaps_on
                else
                    turn_gaps_off
                fi
                ;;
        esac
      '')
      #update-watch
      (pkgs.writeShellScriptBin "watch-update" ''
        #!/bin/sh

        # Set the device serial number
        device_serial="4030658"

        # Check if the specific device is connected and authorized
        adb devices | grep -w "$device_serial" >/dev/null

        if [ $? -eq 0 ]; then
            echo "Device $device_serial is connected."

            # Proceed with commands for the specific device
            # Example: Set the date on the device
            new_date=$(date +"%m%d%H%M%Y.%S")
            adb -s $device_serial shell date $new_date
            adb -s $device_serial shell date
            adb -s $device_serial shell opkg update && opkg upgrade # update watch.
            adb -s $device_serial shell opkg install ssh bash-completion neofetch 
        else
            echo "Device $device_serial (Oppo Watch BelugaXL) is not connected or unauthorized."
            exit 1
        fi
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
            echo "To connect to your iPhone's VNC serfor i in {1..10}; do notify-send -i path/to/icon.png "Notification $i" "This is the content of notification $i."; donever, use the following details:"
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

      
# restart-input-remapper
(pkgs.writeShellScriptBin "restart-input-remapper" ''
  sudo pkill input-remapper || log "No running input-remapper processes found."

  pkexec input-remapper-control --command start-reader-service

  # Wait briefly to ensure the service has time to start
  sleep 2

  # Check if the service is running
  if ! pgrep -f "input-remapper-reader-service" > /dev/null; then
    log "Error: input-remapper service did not start correctly."
    exit 1
  fi

  # Apply the preset for the specified device
  retry input-remapper-control --command start --device "Apple Internal Keyboard / Trackpad" --preset swap_internal_mod_keys

  log "Input-remapper service restarted successfully."
'')

    ];
  };
}
