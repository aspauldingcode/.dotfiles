# Modules Index - Centralized module management
{inputs, ...}: {
  flake.modules = {
    # Universal modules (can be used by both NixOS and nix-darwin)
    theme-toggle = ./theme-toggle.nix;

    # NixOS modules
    nixos = {
      # System-level modules
      default = ./nixos/default.nix;
    };

    # Darwin modules
    darwin = {
      # macOS-specific modules
      default = ./darwin/default.nix;
      plist-manager = ./darwin/plist-manager.nix;
    };

    # Home Manager modules
    home-manager = {
      # User-level modules
      default = ./home-manager/default.nix;
    };
  };
}
