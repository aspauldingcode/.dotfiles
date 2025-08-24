# Overlays Module - Centralized overlay management
{ inputs, ... }:
{
  # Define overlays at the flake level for reuse across all systems
  flake.overlays = {
    # Main overlay combining all custom overlays
    default = inputs.nixpkgs.lib.composeManyExtensions [
      # Community overlays
      inputs.nur.overlays.default

      # Unstable packages overlay
      (final: _prev: {
        unstable = import inputs.nixpkgs-unstable {
          inherit (final) system;
          config = final.config;
        };
      })

      # Custom overlays
      (import ../overlays { inherit inputs; })
    ];
  };

  # Configure nixpkgs consistently across all systems
  perSystem =
    {
      pkgs,
      system,
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowBroken = true;
          permittedInsecurePackages = [
            "electron-19.1.9"
            "electron-33.4.11"
            "olm-3.2.16"
          ];
          # Security: only allow specific unfree packages
          allowUnfreePredicate =
            pkg:
            builtins.elem (inputs.nixpkgs.lib.getName pkg) [
              "vscode"
              "spotify"
              "zoom"
              "slack"
              "chrome"
              "firefox"
              "cursor"
              "1password"
              "1password-cli"
            ];
        };
        overlays = [ inputs.self.overlays.default ];
      };
    };
}
