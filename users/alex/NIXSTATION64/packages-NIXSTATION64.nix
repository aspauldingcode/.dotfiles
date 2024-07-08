{ pkgs, ... }:

# NIXSTATION-specific packages
{
  imports = [ ];
  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [ "electron-19.1.9" ];
      allowUnfreePredicate = (_: true);
      allowUnsupportedSystem = false;
      allowBroken = false;
    };
  };

  home = {
    packages = with pkgs; [
      # Development tools
      arduino-language-server
      cmake-language-server
      jdt-language-server
      kotlin-language-server
      lua-language-server
      vscode

      # System utilities
      avahi
      busybox
      docker
      fd
      gcal
      gimp
      home-manager
      jq
      lsof
      ncdu
      nmap
      pciutils
      pmbootstrap
      ripgrep
      socat
      sshfs
      tigervnc
      usbmuxd
      wget
      xarchiver
      xz
      zip

      # Networking and communication
      android-tools
      checkra1n
      idevicerestore
      libimobiledevice
      libusb1
      libusbmuxd
      obsidian
      rofi-wayland-unwrapped
      zoom-us

      # Multimedia and graphics
      blender-hip
      brave
      cava
      ffmpeg-full
      flameshot
      obs-studio-plugins.obs-vkcapture
      obs-studio-plugins.wlrobs
      spotify-unwrapped
      sway-contrib.grimshot
      yt-dlp # youtube-dl fork
      tartube-yt-dlp # GUI to use yt-dlp 

      # Desktop environment and window management
      albert
      autotiling
      bemenu
      clipman
      eww
      glpaper
      gnomeExtensions.dark-variant
      gtk-layer-shell
      i3status-rust
      imv
      lavalauncher
      lxappearance
      pcmanfm
      pinentry-bemenu
      swaybg
      swaylock-effects
      swayr
      swayrbar
      wbg
      wev
      wl-clipboard
      wl-screenrec
      wlroots
      wlogout
      wl-gammactl
      gammastep
      wlsunset
      wofi
      wshowkeys
      wtype

      # Gaming and emulation
      android-studio
      element
      element-desktop
      wineasio
      wineWow64Packages.waylandFull
      winetricks

      # Fonts and theming
      corefonts
      glib
      sassc

      # Miscellaneous
      beeper
      lolcat
      pfetch
      ruby_3_3
      sl
      thefuck
      waypipe
      wayvnc
      lavat

      (python311.withPackages (
        ps: with ps; [
          toml
          python-lsp-server
          pyls-isort
          flake8
          evdev
          pynput
          # pygame
          matplotlib
          libei
          keyboard
          sympy
          numpy
          i3ipc
        ]
      ))
      (prismlauncher.override {
        jdks = [
          jdk8
          jdk17
          # jdk19
          # Minecraft requires jdk21 SOON!
        ];
      })
      #fix-wm
      (pkgs.writeShellScriptBin "fix-wm" ''
        pkill waybar && sway reload
        sleep 4       #FIX waybar cava init issue:
        nohup ffplay ~/.dotfiles/users/alex/NIXSTATION64/waybar/silence.wav -t 5 -nodisp -autoexit > /dev/null 2>&1 &
        [ -f /tmp/sway_gaps_state ] && rm /tmp/sway_gaps_state # remove the initial states for gaps if it exists.
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

      (pkgs.writeShellScriptBin "toggle-waybar" ''
        # Try to send SIGUSR1 signal to waybar
        killall -SIGUSR1 waybar

        # Check if waybar was killed
        if [ $? -ne 0 ]; then
            # If no process was killed, run waybar and detach its output
            waybar >/dev/null 2>&1 &
        fi
      '')

      #toggle-gaps
      (pkgs.writeShellScriptBin "toggle-gaps" ''
        #!/bin/sh

        # Define a file to keep track of the state
        state_file="/tmp/sway_gaps_state"

        # Function to check current state
        check_state() {
            if [ -f "$state_file" ]; then
                state=$(cat "$state_file")
                echo "Gaps are currently $state"
            else
                echo "State file not found. Gaps are assumed to be off."
            fi
        }

        # Check if the state file exists and read the current state
        if [ -f "$state_file" ]; then
            state=$(cat "$state_file")
        else
            state="off"
            echo "$state" > "$state_file"
        fi

        # Function to turn gaps on
        turn_gaps_on() {
            swaymsg -q gaps inner all set 13 > /dev/null 2>&1
            swaymsg -q gaps outer all set -2 > /dev/null 2>&1
            swaymsg -q corner radius all set 8 > /dev/null 2>&1
            echo "on" > "$state_file"
        }

        # Function to turn gaps off
        turn_gaps_off() {
            swaymsg -q gaps inner all set 0 > /dev/null 2>&1
            swaymsg -q gaps outer all set 0 > /dev/null 2>&1
            swaymsg -q corner radius all set 0 > /dev/null 2>&1
            echo "off" > "$state_file"
        }

        # Process command-line arguments
        case "$1" in
            on)
                if [ "$state" = "on" ]; then
                    echo "Gaps are already on."
                else
                    turn_gaps_on
                fi
                ;;
            off)
                if [ "$state" = "off" ]; then
                    echo "Gaps are already off."
                else
                    turn_gaps_off
                fi
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
    ];
  };
}
