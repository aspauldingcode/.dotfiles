{
  description = "Universal Flake by Alex - macOS and NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11"; # Set to the desired stable version
    unstable_nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs"; # Ensure home-manager follows the stable nixpkgs version
    };
    nix-colors.url = "github:misterio77/nix-colors";

    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs"; # Follows the stable nixpkgs version
    };

    nixvim = {
      url = "github:nix-community/nixvim";
    };

    mobile-nixos = {
      url = "github:NixOS/mobile-nixos";
      flake = false;
    };

    apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs"; # Follows the stable nixpkgs version
    };

    nur = {
      url = "github:nix-community/nur";
    };

    nix-std = {
      url = "github:chessai/nix-std";
    };

    nixtheplanet = {
      url = "github:matthewcroughan/nixtheplanet";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util = {
      url = "github:hraban/mac-app-util";
    };

    nixpkgs-firefox-darwin = {
      url = "github:bandithedoge/nixpkgs-firefox-darwin";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    
    # Homebrew taps
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-services = {
      url = "github:homebrew/homebrew-services";
      flake = false;
    };
    homebrew-koekeishiya = {
      url = "github:koekeishiya/homebrew-formulae";
      flake = false;
    };
    homebrew-felixkratz = {
      url = "github:FelixKratz/homebrew-formulae";
      flake = false;
    };
    homebrew-smudge = {
      url = "github:smudge/homebrew-smudge";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    nix-rosetta-builder = {
      url = "github:cpick/nix-rosetta-builder";
      inputs.nixpkgs.follows = "unstable_nixpkgs";
    };

    frida-nix = {
      url = "github:itstarsun/frida-nix";
    };
  };

  outputs = {
    self,
    nixpkgs,
    unstable_nixpkgs,
    nix-darwin,
    home-manager,
    nixvim,
    flake-parts,
    nix-colors,
    mobile-nixos,
    apple-silicon,
    nur,
    nix-std,
    nixtheplanet,
    agenix,
    mac-app-util,
    nixpkgs-firefox-darwin,
    spicetify-nix,
    nix-homebrew,
    homebrew-core,
    homebrew-bundle,
    homebrew-services,
    homebrew-koekeishiya,
    homebrew-felixkratz,
    homebrew-smudge,
    homebrew-cask,
    nix-rosetta-builder,
    frida-nix,
  }:
  let
    inherit (self) inputs;
    std = nix-std.lib;
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
        nur
        self
        std
        nixtheplanet
        spicetify-nix
        ;
    };
    commonExtraSpecialArgs = {
      inherit
        inputs
        nix-darwin
        nixvim
        flake-parts
        nix-colors
        apple-silicon
        nur
        self
        std
        nixtheplanet
        spicetify-nix
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
          overlays = [
            inputs.nur.overlays.default
            (final: _prev: {
              unstable = import unstable_nixpkgs {
                inherit (final) system config;
              };
            })
          ];
        };
        specialArgs = commonSpecialArgs; # // { extraPkgs = [ mobile-nixos ]; };
        modules = [
          ./system/NIXSTATION64/configuration-NIXSTATION64.nix
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
          agenix.nixosModules.default
        ];
      };
      NIXEDUP = nixpkgs.lib.nixosSystem {
        pkgs = nixpkgs.legacyPackages.aarch64-linux;
        specialArgs = commonSpecialArgs;
        modules = [ 
          ./system/NIXEDUP/configuration-NIXEDUP.nix 
          agenix.nixosModules.default
        ];
      };
      NIXY2 = nixpkgs.lib.nixosSystem {
        pkgs = import nixpkgs {
          system = "aarch64-linux";
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [ "electron-19.1.9" ];
          };
          overlays = [
            inputs.nur.overlays.default
            (final: _prev: {
              unstable = import unstable_nixpkgs {
                inherit (final) system config;
              };
            })
          ];
        };
        specialArgs = commonSpecialArgs; # // { extraPkgs = [ mobile-nixos ]; };
        modules = [
          ./system/NIXY2/configuration-NIXY2.nix
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
          agenix.nixosModules.default
        ];
      };
    };

    # Define Darwin (macOS) configurations
    darwinConfigurations = {
      NIXY = nix-darwin.lib.darwinSystem {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [
              #"python-2.7.18.7-env"
            ];
          };
          overlays = [
            inputs.nur.overlays.default
            inputs.nixpkgs-firefox-darwin.overlay
            inputs.frida-nix.overlays.default
            (final: _prev: {
              unstable = import unstable_nixpkgs {
                inherit (final) system config;
              };
            })
          ];
        };
        specialArgs = commonSpecialArgs;
        modules = [
          ./system/NIXY/darwin-configuration-NIXY.nix
          mac-app-util.darwinModules.default
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
              extraSpecialArgs = commonExtraSpecialArgs;
              backupFileExtension = "backup";
              sharedModules = [
                mac-app-util.homeManagerModules.default
                spicetify-nix.homeManagerModules.default
              ];
              users.alex.imports = [
                ./users/alex/NIXY/home-NIXY.nix
              ];
            };
          }
          agenix.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew

          # An existing Linux builder is needed to initially bootstrap `nix-rosetta-builder`.
          # If one isn't already available: comment out the `nix-rosetta-builder` module below,
          # uncomment this `linux-builder` module, and run `darwin-rebuild switch`:
          { nix.linux-builder.enable = true; }
          # Then: uncomment `nix-rosetta-builder`, remove `linux-builder`, and `darwin-rebuild switch`
          # a second time. Subsequently, `nix-rosetta-builder` can rebuild itself.
          # nix-rosetta-builder.darwinModules.default
        ];
      };
    };
  in
  {
    # Return all the configurations
    nixosConfigurations = nixosConfigurations;
    darwinConfigurations = darwinConfigurations;
    # FIXME: add nixvim here so I can build from any device without installing the dotfiles.
  };
}
