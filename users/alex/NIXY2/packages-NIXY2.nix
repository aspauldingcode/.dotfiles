{ pkgs, ... }:

# NIXY2-specific packages
{
  imports = [ ];
  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [ "electron-19.1.9" "openjdk-19-ga" ];
      allowUnfreePredicate = (_: true);
      allowUnsupportedSystem = false;
      allowBroken = false;
    };
  };

  home = {
    packages = with pkgs; [
      #wget
      #ncdu
      #gcal
      fzf
      libnotify
      #checkra1n
      cava
      lavat
      pfetch
      android-tools
      neovim
      #zoom-us
      corefonts
      #sl
      #obsidian
      bemenu
      #gnomeExtensions.dark-variant
      wl-clipboard
      wtype
      #element-desktop
      #brave
      #firefox
      #transmission-gtk
      cowsay
      autotiling
      busybox
      #nil
      #blueman
      #jq
      #fd
      #ripgrep
      #idevicerestore
      #usbmuxd
      #libusbmuxd
      #libimobiledevice
      #avahi
      #sshfs
      #pciutils
      #socat
      #lolcat
      #libusb1
      #zip
      thefuck
      sway-contrib.grimshot
      #(python311.withPackages (
      #  ps: with ps; [
      #    toml
      #    python-lsp-server
      #    pyls-isort
       #   flake8
        #  evdev
         # pynput
          # pygame
        #  matplotlib
        #  libei
        #  keyboard
        #  sympy
        #  numpy
        #  i3ipc
  #      ]
 #     ))
    #  (prismlauncher.override {
   #     jdks = [
  #        jdk8
 #         jdk17
          #jdk19
#	  jdk21
          # Minecraft requires jdk21 SOON!
     #   ];
      #})
      #fix-wm
      (pkgs.writeShellScriptBin "fix-wm" ''
        pkill waybar && sway reload
        sleep 4       #FIX waybar cava init issue:
        nohup ffplay ~/.dotfiles/users/alex/NIXSTATION64/waybar/silence.wav -t 4 -nodisp -autoexit > /dev/null 2>&1 &
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

    ];
  };
}
