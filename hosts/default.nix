# Hosts Index - Centralized host configuration management
{ inputs, ... }:
{
  flake.hosts = {
    # NixOS hosts
    nixos = {
      NIXSTATION64 = ./nixos/NIXSTATION64;
      NIXY2 = ./nixos/NIXY2;
      NIXEDUP = ./nixos/NIXEDUP;
    };

    # Darwin hosts
    darwin = {
      NIXY = ./darwin/NIXY;
      NIXI = ./darwin/NIXI;
    };

    # Shared configuration
    extraConfig = ./extraConfig;
  };
}
