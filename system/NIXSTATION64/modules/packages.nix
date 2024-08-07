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
    gnome.sushi
    gnome.nautilus
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
    ueberzugpp # replacement for depricated inline terminal image previewer
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
    pstree
    zoxide
    dnsmasq
    udftools
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

    (pkgs.callPackage ./cursor.nix { }) # FIXME: broken atm.
  ];
}
