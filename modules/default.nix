# Modules Index - Centralized module management
{inputs, ...}: {
  flake.modules = {
    # NixOS modules
    nixos = {
      # System-level modules
      default = ./nixos/default.nix;
    };

    # Darwin modules
    darwin = {
      # macOS-specific modules
      default = ./darwin/default.nix;
    };

    # Home Manager modules
    home-manager = {
      # User-level modules
      default = ./home-manager/default.nix;
    };
  };
}
