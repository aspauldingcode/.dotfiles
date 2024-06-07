{
  description = "Universal Flake by Alex - macOS and NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    nix-colors.url = "github:misterio77/nix-colors";

    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mobile-nixos = {
      url = "github:NixOS/mobile-nixos";
      flake = false;
    };

    apple-silicon = {
	url = "github:tpwrules/nixos-apple-silicon";
	inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nixvim,
      flake-parts,
      nix-colors,
      mobile-nixos,
      apple-silicon,
    }:
    let
      inherit (self) inputs;
      # Define common specialArgs for nixosConfigurations and homeConfigurations
      commonSpecialArgs = {
        inherit
          inputs
          nix-darwin
          nixvim
          home-manager
          flake-parts
          nix-colors
	  apple-silicon
          self
          ;
      };
      commonExtraSpecialArgs = {
        inherit
          inputs
          nix-darwin
          nixvim
          flake-parts
          nix-colors
          self
          ;
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      eachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # Define NixOS configurations
      nixosConfigurations = {
        NIXSTATION64 = nixpkgs.lib.nixosSystem {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config = {
              allowUnfree = true;
              permittedInsecurePackages = [ "electron-19.1.9" ];
            };
          };
          specialArgs = commonSpecialArgs; # // { extraPkgs = [ mobile-nixos ]; };
          modules = [
            ./system/NIXSTATION64/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.alex = import ./users/alex/NIXSTATION64/home-NIXSTATION64.nix;
                # Optionally, use home-manager.extraSpecialArgs to pass
                # arguments to home.nix
                extraSpecialArgs = commonExtraSpecialArgs;
                backupFileExtension = "backup";
              };
            }
          ];
        };
        NIXEDUP = nixpkgs.lib.nixosSystem {
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
          specialArgs = commonSpecialArgs;
          modules = [ ./system/NIXEDUP/configuration.nix ];
        };
	NIXY2 = nixpkgs.lib.nixosSystem {
          pkgs = import nixpkgs {
            system = "aarch64-linux";
            config = {
              allowUnfree = true;
              permittedInsecurePackages = [ "electron-19.1.9" ];
            };
          };
          specialArgs = commonSpecialArgs; # // { extraPkgs = [ mobile-nixos ]; };
          modules = [
            ./system/NIXY2/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.alex = import ./users/alex/NIXY2/home-NIXY2.nix;
                # Optionally, use home-manager.extraSpecialArgs to pass
                # arguments to home.nix
                extraSpecialArgs = commonExtraSpecialArgs;
                backupFileExtension = "backup";
              };
            }
          ];
        };
      };

      # Define Darwin (macOS) configurations
      darwinConfigurations = {
        NIXY = nix-darwin.lib.darwinSystem {
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            config.allowUnfree = true;
            overlays = [
              #install i3/sway autotiling on macos for i3 xquartz!
              (final: prev: {
                autotiling =
                  if prev.system == "aarch64-darwin" then
                    prev.pkgs.autotiling.overrideAttrs (
                      oldAttrs: {
                        unsupportedSystems = false; # Changed to false for unsupported
                      }
                    )
                  else
                    prev.pkgs.autotiling;
              })
            ];
          };
          specialArgs = commonSpecialArgs;
          modules = [
            ./system/NIXY/darwin-configuration.nix
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.alex = import ./users/alex/NIXY/home-NIXY.nix;
                # Optionally, use home-manager.extraSpecialArgs to pass
                # arguments to home.nix
                extraSpecialArgs = commonExtraSpecialArgs;
                backupFileExtension = "backup";
              };
            }
          ];
        };
      };
    in
    {
      # Return all the configurations
      nixosConfigurations = nixosConfigurations;
      darwinConfigurations = darwinConfigurations;
    };
}
