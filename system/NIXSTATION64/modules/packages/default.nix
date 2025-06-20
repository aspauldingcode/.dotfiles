# Configure included packages for NixOS.

{
  lib,
  pkgs,
  nixpkgs,
  ...
}:

{
  programs = {
    darling.enable = true; # install darling with setuid wrapper
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
        thunar-dropbox-plugin
        thunar-media-tags-plugin
      ];
    };
    xfconf.enable = true;
  };

  services = {
    gvfs.enable = true; # Mount, trash, and other functionalities
    tumbler.enable = true; # Thumbnail support for images
  };

  environment.systemPackages = with pkgs; [
    way-displays
    libdrm
    ddcutil
    edid-decode
    read-edid
    greetd.regreet
    neovim
    zellij
    kdePackages.kdeconnect-kde
    universal-android-debloater
    clang
    libsForQt5.qt5.qtbase
    libsForQt5.qt5.qtsvg
    libsForQt5.qt5.qtquickcontrols2
    libsForQt5.kdialog
    libsForQt5.qt5.qtgraphicaleffects
    libsForQt5.dolphin
    libsForQt5.qt5ct
    sushi
    nautilus
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

    #needed for nixos mobile?sqlite

    npth # Required for NixOS Mobile! The New GNU Portable Threads Library
    sqlite
    gnutls
    libusb1
    networkmanagerapplet
    edl
    payload-dumper-go
    ranger
    wl-clipboard
    neofetch
    # uef rzugpp # replacement for depricated inline terminal image previewer
    yazi
    grim
    krita
    libreoffice-fresh
    xdg-desktop-portal-wlr
    geoclue2
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
    nixfmt-rfc-style
    pstree
    zoxide
    dnsmasq
    udftools
    fzf
    element
    appimage-run
    tree-sitter
    python311
    # nodejs
    ncurses6
    flex
    light
    bison
    gnumake
    gcc
    openssl
    dtc
    gnome-themes-extra
    cargo
    # nodePackages_latest.npm
    perl
    hexedit
    virt-manager
    uxplay

    # (pkgs.symlinkJoin {
    #   name = "beeper-wayland";
    #   paths = [ pkgs.beeper ];
    #   buildInputs = [ pkgs.makeWrapper pkgs.wmctrl ];
    #   postBuild = ''
    #     wrapProgram $out/bin/beeper \
    #       --set ELECTRON_ARGS "--enable-features=UseOzonePlatform --platform=wayland"

    #     # Remove window buttons using wmctrl
    #     postProcess () {
    #       wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz
    #       wmctrl -r :ACTIVE: -e 0,0,0,0,0
    #     }

    #     # Directly run the application and modify window post-launch
    #     $out/bin/beeper &
    #     postProcess
    #   '';
    # })

    # (pkgs.symlinkJoin {
    #   name = "vscode-wayland";
    #   paths = [ pkgs.vscode ];
    #   buildInputs = [ pkgs.makeWrapper pkgs.wmctrl ];
    #   postBuild = ''
    #     wrapProgram $out/bin/code \
    #       --set ELECTRON_ARGS "--enable-features=UseOzonePlatform --platform=wayland"

    #     # Remove window buttons using wmctrl
    #     postProcess () {
    #       wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz
    #       wmctrl -r :ACTIVE: -e 0,0,0,0,0
    #     }

    #     # Directly run the application and modify window post-launch
    #     $out/bin/code &
    #     postProcess
    #   '';
    # })

    # (pkgs.symlinkJoin {
    #   name = "code-cursor-wayland";
    #   paths = [ pkgs.code-cursor ];
    #   buildInputs = [ pkgs.makeWrapper pkgs.wmctrl ];
    #   postBuild = ''
    #     wrapProgram $out/bin/code-cursor \
    #       --set ELECTRON_ARGS "--enable-features=UseOzonePlatform --platform=wayland"

    #     # Remove window buttons using wmctrl
    #     postProcess () {
    #       wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz
    #       wmctrl -r :ACTIVE: -e 0,0,0,0,0
    #     }

    #     # Directly run the application and modify window post-launch
    #     $out/bin/code-cursor &
    #     postProcess
    #   '';
    # })
  ];
}
