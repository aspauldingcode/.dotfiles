# Configure included packages for NixOS.

{
  lib,
  pkgs,
  nixpkgs,
  ...
}:

{
  programs.darling.enable = true; # install darling with setuid wrapper

  environment.systemPackages = with pkgs; [
    neovim
    zellij
    libsForQt5.qt5.qtbase
    libsForQt5.qt5.qtsvg
    libsForQt5.qt5.qtquickcontrols2
    libsForQt5.kdialog
    libsForQt5.qt5.qtgraphicaleffects
    libsForQt5.dolphin
    libsForQt5.qt5ct
    # libsForQt5.breeze-qt5
    # libsForQt5.breeze-gtk
    # libsForQt5.breeze-icons
    # libsForQt5.breeze-plymouth
    # libsForQt5.breeze-grublouvre

    #macOS THEME
    whitesur-kde
    whitesur-gtk-theme
    whitesur-icon-theme
    # whitesur-cursors

    ranger
    wl-clipboard
    neofetch
    ueberzugpp # replacement for depricated inline terminal image previewer
    yazi
    grim
    krita
    libreoffice-fresh
    xdg-desktop-portal-wlr
    gtkdialog
    pcmanfm
    wofi-emoji
    htop
    fim
    gparted
    killall
    tree
    zsh
    curl
    lazygit
    wget
    git
    pstree
    zoxide
    dnsmasq
    udftools
    element
    appimage-run
    tree-sitter
    jdk20
    python311
    nodejs
    ncurses6
    flex
    bison
    gnumake
    gcc
    openssl
    dtc
    gnome-themes-extra
    cargo
    nodePackages_latest.npm
    perl
    hexedit
    virt-manager
    uxplay

    #rebuild #sudo nixos-rebuild switch --show-trace --option eval-cache false --flake .#NIXSTATION64
    (pkgs.writeShellScriptBin "rebuild" ''
      # NIXSTATION64(x86_64-linux)
      cd ~/.dotfiles
      sudo nixos-rebuild switch --show-trace --flake .#NIXSTATION64 
      #home-manager switch --flake .#alex@NIXSTATION64
      echo "Done. Running 'fix-wm'..."
      fix-wm
      echo "Completed."
      date +"%r"
    '')

    #update
    (pkgs.writeShellScriptBin "update" ''
      cd ~/.dotfiles
      git fetch
      git pull
      git merge origin/main
        # Prompt the user for a commit message
        echo "Enter a commit message:"
        read commit_message
        git add .
        git commit -m "$commit_message"
        git push origin main
    '')
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
  ];
}
