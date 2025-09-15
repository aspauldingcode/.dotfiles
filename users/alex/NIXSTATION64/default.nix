# Alex's Home Manager Configuration for NIXSTATION64
# x86_64 Linux Desktop Workstation
{
  inputs,
  pkgs,
  lib,
  user,
  nix-colors,
  ...
}: let
  # Define username once for this user configuration
  username = "alex";
in {
  imports = [
    ../../../shared/base/alex-base.nix
    ./modules
    ./home
    ./scripts
  ];

  # Pass username to all imported modules
  _module.args = {
    inherit username;
  };

  # System-specific overrides
  home.sessionVariables = {
    FLAKE = "/home/${user}/.dotfiles";
  };

  # Additional packages for this workstation
  home.packages = with pkgs; [
    # Desktop-specific packages
    vscode
    gimp
    krita
    libreoffice-fresh
    element-desktop
    
    # Development tools specific to desktop
    arduino-language-server
    cmake-language-server
    jdt-language-server
    kotlin-language-server
    lua-language-server
    
    # System utilities for desktop
    avahi
    debootstrap
    libnotify
    busybox
    docker
    fd
    gcal
    home-manager
    lsof
    ncdu
    nmap
    pciutils
    ripgrep
    socat
    sshfs
    tigervnc
    usbmuxd
    xarchiver
    
    # Media and graphics
    obs-studio
    obs-studio-plugins.obs-vkcapture
    spotify-unwrapped
    
    # Desktop environment tools
    albert
    bemenu
    clipman
    imv
    lavalauncher
    lxappearance
    pcmanfm
    pinentry-bemenu
    
    # Gaming and emulation
    android-studio
    element
    element-desktop
    firefox
    steam
    
    # Development and debugging
    gdb
    strace
    valgrind
    
    # File management
    ranger
    yazi
    
    # System monitoring
    htop
    btop
    neofetch
    fastfetch
  ];
}