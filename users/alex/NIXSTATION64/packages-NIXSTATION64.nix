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
      #darling REQUIRES  Security wrapper SETUID!!!
      #darling-dmg
      lsof
      wget
      wlvncc
      tigervnc
      nmap
      # dependencies for menu-continuous
      # cmake
      # procps
      # musl
      # rocmPackages.llvm.clang
      # libdbusmenu
      # libsForQt5.baloo
      # # libsForQt5.libdbusmenu
      # # libdbusmenu-gtk2
      # # libdbusmenu-gtk3
      #
      # libsForQt5.applet-window-appmenu

      ncdu
      gcal
      # nwg-dock
      # nwg-drawer
      # nwg-displays
      # nwg-launchers
      # nwg-bar
      # nwg-panel

      #not available yet
      # hybridbar

      albert

      fzf
      libnotify
      checkra1n
      # darwin.cctools-port # is it needed tho? MARKED BROKEN NIXOS
      # wine
      # wine64
      # wine-wayland
      #winePackages.waylandFull
      wineWow64Packages.waylandFull
      #winePackages.stableFull
      #wine64Packages.stableFull
      wineasio
      winetricks
      cava
      lavat
      pfetch
      zoom-us
      spotify-unwrapped
      android-studio
      corefonts
      beeper
      sl
      obsidian
      ocl-icd
      rofi-wayland-unwrapped
      vscode
      bemenu
      #wofiPower
      #wofiWindowJump
      #dunst
      gnomeExtensions.dark-variant
      eww
      glpaper
      sassc
      glib
      lxappearance
      gtk-layer-shell
      i3status-rust
      imv
      gpm
      lavalauncher
      obs-studio-plugins.wlrobs
      obs-studio-plugins.obs-vkcapture
      swayr
      swayrbar
      #sway-unwrapped
      swaybg
      #swayidle
      #swaylock
      swaylock-effects
      #swww
      pinentry-bemenu
      waypipe
      #wayprompt
      wayvnc
      wbg
      wev
      #wf-recorder
      wl-clipboard
      wl-gammactl
      gammastep
      geoclue2
      wl-screenrec
      wlogout
      wlroots
      wlsunset
      wofi
      wshowkeys
      wtype
      clipman
      #etcher
      element-desktop
      blender
      brave
      firefox-esr
      spotify-unwrapped
      autotiling
      waydroid
      pcmanfm
      w3m
      docker
      home-manager
      android-tools
      xz
      element
      OVMF
      edk2
      busybox
      #LSP PACKAGES for NVIM 
      ##NOTWORKING?!!?!?!?!? FIXME
      #rnix-lsp
      # FIND MORE INFO: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
      nil
      # nodePackages_latest.typescript-language-server
      # nodePackages_latest.typescript
      # nodePackages.yaml-language-server
      # nodePackages_latest.dockerfile-language-server-nodejs
      jdt-language-server
      kotlin-language-server
      lua-language-server
      cmake-language-server
      arduino-language-server
      # nodePackages_latest.vim-language-server
      #python311Packages.python-lsp-server
      blueman
      jq
      flameshot
      fd
      ripgrep
      idevicerestore
      usbmuxd
      libusbmuxd
      libimobiledevice
      avahi
      sshfs
      pciutils
      socat
      lolcat
      pmbootstrap
      libusb1
      xarchiver
      gimp
      zip
      thefuck
      ffmpeg-full
      sway-contrib.grimshot
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
        rm /tmp/sway_gaps_state # remove the initial states for gaps.
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
