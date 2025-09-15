# Configure included packages for NixOS.
{
  lib,
  pkgs,
  nixpkgs,
  ...
}: {
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

  environment.systemPackages = with pkgs; [
    # Removed: way-displays, regreet
    neovim
    fastfetch
    zellij
    gh
    geteduroam
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
    # Removed: wl-clipboard (Wayland-specific)
    yazi
    grim
    krita
    libreoffice-fresh
    # Removed: xdg-desktop-portal-wlr (Wayland-specific)
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
