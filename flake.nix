{
  description = "Universal Flake by Alex - macOS and NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05"; # Set to the desired stable version
    unstable_nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs"; # Ensure home-manager follows the stable nixpkgs version
    };
    nix-colors.url = "github:misterio77/nix-colors";

    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs"; # Follows the stable nixpkgs version
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      #inputs.nixpkgs.follows = "unstable_nixpkgs"; # Follows the unstable nixpkgs version
      inputs.nixpkgs.follows = "nixpkgs"; # follow stable channel.
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
  };

  outputs =
    {
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
              inputs.nur.overlay
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
          ];
        };
        NIXEDUP = nixpkgs.lib.nixosSystem {
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
          specialArgs = commonSpecialArgs;
          modules = [ ./system/NIXEDUP/configuration-NIXEDUP.nix ];
        };
        NIXY2 = nixpkgs.lib.nixosSystem {
          pkgs = import nixpkgs {
            system = "aarch64-linux";
            config = {
              allowUnfree = true;
              permittedInsecurePackages = [ "electron-19.1.9" ];
            };
            overlays = [
              inputs.nur.overlay
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
              inputs.nur.overlay
              (final: _prev: {
                unstable = import unstable_nixpkgs {
                  inherit (final) system config;
                };
              })
              (final: prev: {
                start_programs_correctly =
                  let
                    systemType = prev.pkgs.stdenv.hostPlatform.system;
                    homebrewPath =
                      if systemType == "aarch64-darwin" then
                        "/opt/homebrew/bin"
                      else if systemType == "x86_64-darwin" then
                        "/usr/local/bin"
                      else
                        throw "Homebrew Unsupported architecture: ${systemType}";
                    jq = "${prev.pkgs.jq}/bin/jq";
                    yabai = "${homebrewPath}/yabai";
                    sketchybar = "${homebrewPath}/sketchybar";
                    borders = "${homebrewPath}/borders";
                    skhd = "${homebrewPath}/skhd";
                  in
                  prev.writeShellScriptBin "start_programs_correctly" ''
                    #!/bin/bash

                    # Step 1: Query all available windows
                    windows=$(${yabai} -m query --windows)

                    # Step 2: Kill all open windows.
                    for window in $(echo "$windows" | ${jq} -r '.[].id'); do
                      ${yabai} -m window "$window" --close
                    done

                    # Step 3: Run MacForge in Hidden Mode
                    open -a MacForge --hide
                  '';

                brightness = prev.writeShellScriptBin "brightness" ''
                  #!/bin/sh

                  # Function to press the brightness up key
                  brightness_up() {
                    osascript -e 'tell application "System Events" to key code 144'
                  }

                  # Function to press the brightness down key
                  brightness_down() {
                    osascript -e 'tell application "System Events" to key code 145'
                  }

                  # Adjust brightness based on the provided number of times
                  brightness() {
                    local times=$1

                    if [[ $times -gt 0 ]]; then
                      for ((i = 0; i < times; i++)); do
                        brightness_up
                      done
                    elif [[ $times -lt 0 ]]; then
                      for ((i = 0; i < -times; i++)); do
                        brightness_down
                      done
                    fi
                  }

                  # Only run the brightness function if the script is executed directly
                  if [[ "''${BASH_SOURCE[0]}" == "''${0}" ]]; then
                    if [[ $# -ne 1 ]]; then
                      echo "Usage: $0 <number>"
                      exit 1
                    fi
                    brightness "$1"
                  fi
                '';
              })
            ];
          };
          specialArgs = commonSpecialArgs;
          modules = [
            ./system/NIXY/darwin-configuration-NIXY.nix
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
