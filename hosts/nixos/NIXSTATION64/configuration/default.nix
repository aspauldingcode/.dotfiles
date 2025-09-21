# NIXSTATION64 NixOS Configuration
# x86_64 Linux Desktop Workstation
{
  inputs,
  lib,
  config,
  pkgs,
  user,
  hostname,
  ...
}: {
  imports = [
    ../../../../shared/base/nixos-base.nix
    ../hardware-configuration
    ../modules
  ];

  # System-specific overrides using passed hostname
  networking.hostName = hostname;
  networking.domain = "local";

  # Hardware-specific configuration
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "amdgpu.si_support=0"
    "ipv6.disable=1"
    "nvidia-drm.modeset=1"
  ];

  hardware = {
    amdgpu.initrd.enable = true;
    graphics.extraPackages = with pkgs; [
      rocmPackages.clr.icd
      amdvlk
    ];
  };

  # Additional user for this system
  users.users.susu = {
    isNormalUser = true;
    description = "Su Su Oo";
    extraGroups = ["networkmanager"];
  };

  # System-specific virtualization
  virtualisation = {
    docker.enable = true;
    libvirtd.enable = true;
    waydroid.enable = true;
    # lxd.enable = true; # LXD has been removed from NixOS, consider using Incus instead
  };

  # Additional groups for main user
  users.users.${user}.extraGroups = ["kvm" "libvirtd"];

  # System-specific activation scripts
  system.activationScripts.script.text = ''
    # Set user profile pictures
    mkdir -p /var/lib/AccountsService/icons
    cp /home/alex/.dotfiles/users/alex/face.png /var/lib/AccountsService/icons/alex || true
    cp /home/susu/.dotfiles/users/susu/face.png /var/lib/AccountsService/icons/susu || true
  '';

  # Console configuration for TTY

  # System-specific environment variables
  environment.sessionVariables = {
    FLAKE = "/home/${user}/.dotfiles";
    NIXOS_OZONE_WL = "1";
  };

  # Additional system packages specific to this workstation
  environment.systemPackages = with pkgs; [
    # Desktop-specific packages
    kdePackages.kdeconnect-kde
    universal-android-debloater
    clang
    sushi
    sqlite
    libusb1
    networkmanagerapplet
    yazi
    grim
    krita
    libreoffice-fresh

    # Development tools
    cargo
    hexedit
    uxplay
    libdrm
    ddcutil
    edid-decode
    read-edid
    ranger
    neofetch
    fim
    gparted
    dnsmasq
    udftools
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
  ];

  # Programs specific to this system
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

  # Services specific to this system
  services = {
    gvfs.enable = true;
    tumbler.enable = true;
  };

  # System-specific sysctl settings
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 1048576;
    "fs.inotify.max_user_instances" = 1024;
    "fs.inotify.max_queued_events" = 32768;
  };

  # Systemd-specific settings
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "10s";
  };

  # System-specific tmpfiles rules
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    "d /tmp 1777 root root 10d"
    "w /proc/sys/fs/inotify/max_user_watches - - - - 65536"
  ];
}
