# Home Manager Configurations Module
{inputs, ...}: {
  # Standalone Home Manager configurations (optional)
  flake.homeConfigurations = {
    # Standalone configuration for systems without NixOS/nix-darwin
    "alex@generic" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "electron-19.1.9"
            "electron-33.4.11"
            "olm-3.2.16"
          ];
        };
        overlays = [
          inputs.self.overlays.default
        ];
      };
      extraSpecialArgs = {
        inherit inputs;
        user = "alex";
      };
      modules = [
        ../users/alex/generic
        inputs.sops-nix.homeManagerModules.sops
      ];
    };
  };
}
