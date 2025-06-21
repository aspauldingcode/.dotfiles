# Configure included packages for NixOS.

{
  lib,
  pkgs,
  nixpkgs,
  ...
}:

{
  programs = {
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
    greetd.regreet
    neovim
    fastfetch
    zellij
    gh
    kdePackages.kdeconnect-kde
    universal-android-debloater
    clang
    sushi
    sqlite
    libusb1
    networkmanagerapplet
    wl-clipboard
    yazi
    grim
    krita
    libreoffice-fresh
    xdg-desktop-portal-wlr
    killall
    tree
    curl
    wget
    git
    cargo
    hexedit
    uxplay

    # Additional useful packages
    libdrm
    ddcutil
    edid-decode
    read-edid
    ranger
    neofetch
    htop
    fim
    gparted
    zsh
    lazygit
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
    ncurses6
    flex
    light
    bison
    gnumake
    gcc
    openssl
    dtc
    gnome-themes-extra
    perl
    virt-manager
  ];
}
