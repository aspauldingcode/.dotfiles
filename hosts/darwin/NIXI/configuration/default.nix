# NIXI Darwin Configuration  
# x86_64 Darwin (Intel) macOS System
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
    ../../../shared/base/darwin-base.nix
    ../modules
  ];

  # System-specific networking using passed hostname
  networking = {
    computerName = hostname;
    hostName = hostname;
    localHostName = hostname;
  };

  # System-specific nixpkgs configuration
  nixpkgs.hostPlatform = "x86_64-darwin";
}