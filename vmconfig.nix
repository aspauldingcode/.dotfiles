{ config, pkgs, lib, ... }:

{
  # Basic system settings
  system.stateVersion = "23.11";

  # VM-specific settings
  virtualisation = {
    diskSize = lib.mkForce 4096; # Force our disk size setting
    memorySize = 2048; # RAM in MiB (2GB)
  };

  # Enable SSH
  services.openssh.enable = true;

  # Create a root user with password "nixos"
  users.users.root.initialPassword = "nixos";

  # Create a regular user
  users.users.demo = {
    isNormalUser = true;
    initialPassword = "demo";
    extraGroups = [ "wheel" ]; # Enable sudo
  };

  # Basic packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
  ];

  # Enable networking
  networking = {
    hostName = "nixos-vm";
    networkmanager.enable = true;
  };

  # Enable basic system services
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
}