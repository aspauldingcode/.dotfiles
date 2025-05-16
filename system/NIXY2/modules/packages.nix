# Configure included packages for NixOS.

{
  lib,
  pkgs,
  nixpkgs,
  ...
}:

{
  programs = {
    darling.enable = false; # install darling with setuid wrapper. ONLY AVAILABLE ON x86 FOR NOW!
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

  environment.systemPackages = with pkgs; [
    way-displays
    greetd.regreet
    neovim
    fastfetch
    zellij
    kdePackages.kdeconnect-kde
    universal-android-debloater
    clang
    sushi
    sqlite
    nix-search
    chatgpt-cli
    kdePackages.kleopatra
    uutils-coreutils
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
  ];
}
