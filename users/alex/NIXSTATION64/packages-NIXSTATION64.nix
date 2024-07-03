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
    ];
  };
}
