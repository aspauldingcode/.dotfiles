# NixOS Configurations Module
{ inputs, ... }:
{
  flake.nixosConfigurations = {
    # x86_64 Linux (stable) - Desktop workstation
    NIXSTATION64 = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = inputs.self.commonConfigs.specialArgs // {
        inherit (inputs) apple-silicon mobile-nixos;
      };
      modules = inputs.self.commonModules.nixos ++ [
        ../hosts/nixos/NIXSTATION64
        {
          home-manager = inputs.self.commonConfigs.homeManagerNixOS // {
            users.alex = import ../users/alex/NIXSTATION64;
          };
        }
      ];
    };

    # aarch64 Linux (Apple Silicon) - VM/Development system
    NIXY2 = inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = inputs.self.commonConfigs.specialArgs // {
        inherit (inputs) apple-silicon mobile-nixos;
      };
      modules = inputs.self.commonModules.nixos ++ [
        ../hosts/nixos/NIXY2
        inputs.apple-silicon.nixosModules.apple-silicon-support
        {
          home-manager = inputs.self.commonConfigs.homeManagerNixOS // {
            users.alex = import ../users/alex/NIXY2;
          };
        }
      ];
    };

    # aarch64 Linux (mobile) - OnePlus 6T with Mobile NixOS
    NIXEDUP = inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = {
        inherit inputs;
        inherit (inputs) mobile-nixos;
        user = "alex";
      };
      modules = [
        ../hosts/nixos/NIXEDUP
        inputs.sops-nix.nixosModules.sops
        {
          # Use centralized overlays
          nixpkgs.overlays = [ inputs.self.overlays.default ];
          nixpkgs.config = {
            allowUnfree = true;
            permittedInsecurePackages = [
              "electron-19.1.9"
              "electron-33.4.11"
              "olm-3.2.16"
            ];
          };
        }
      ];
    };
  };
}
