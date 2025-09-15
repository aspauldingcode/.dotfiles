# NIXY2 NixOS Configuration  
# aarch64 Linux (Apple Silicon) VM/Development System
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
    ../../../shared/base/nixos-base.nix
    ../hardware-configuration
    ../modules
  ];

  # System-specific overrides using passed hostname
  networking.hostName = hostname;
  
  # Apple Silicon specific kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Mobile hotspot sharing configuration
  networking = {
    nat = {
      enable = true;
      internalInterfaces = ["ve-+"];
      externalInterface = "eth0";
      forwardPorts = [
        {
          sourcePort = 80;
          destination = "192.168.100.10:80";
          proto = "tcp";
        }
      ];
    };
    firewall = {
      allowedTCPPorts = [80 443 22];
      allowedUDPPorts = [53];
    };
  };

  # Mobile hotspot iptables rules
  systemd.services.mobile-hotspot = {
    description = "Mobile Hotspot Configuration";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    script = ''
      # Enable IP forwarding
      echo 1 > /proc/sys/net/ipv4/ip_forward
      
      # Configure iptables for mobile hotspot
      ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
      ${pkgs.iptables}/bin/iptables -A FORWARD -i usb0 -o eth0 -j ACCEPT
    '';
  };

  # System-specific programs
  programs.light.enable = true;

  # System-specific environment variables
  environment.sessionVariables = {
    FLAKE = "/home/${user}/.dotfiles";
    NIXOS_OZONE_WL = "1";
  };

  # System-specific packages for ARM64/Apple Silicon
  environment.systemPackages = with pkgs; [
    # ARM64-specific or development packages
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
    yazi
    grim
    krita
    libreoffice-fresh
    uxplay
  ];

  # Console configuration
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
    useXkbConfig = true;
  };

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
}