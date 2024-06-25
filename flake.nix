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
      inputs.nixpkgs.follows = "unstable_nixpkgs"; # Follows the unstable nixpkgs version
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
          nur
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
          nur
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
            overlays = [ inputs.nur.overlay ];
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
            overlays = [ inputs.nur.overlay ];
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
              inputs.nur.overlay
              #install i3/sway autotiling on macos for i3 xquartz!
              (final: prev: {
                autotiling =
                  if prev.system == "aarch64-darwin" then
                    prev.pkgs.autotiling.overrideAttrs (oldAttrs: {
                      unsupportedSystems = false; # Changed to false for unsupported
                    })
                  else
                    prev.pkgs.autotiling;
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

                    # Step 2: Kill all windows using their PIDs and collect app names
                    appnames=()
                    echo "$windows" | ${jq} -c '.[]' | while read -r window; do
                      pid=$(echo "$window" | ${jq} '.pid')
                      app=$(echo "$window" | ${jq} -r '.app')
                      appnames+=("$app")
                      if [ -n "$pid" ]; then
                        kill -9 "$pid"
                      fi
                    done

                    # Ensure all processes are killed
                    sleep 2
                    echo "$windows" | ${jq} -c '.[]' | while read -r window; do
                      pid=$(echo "$window" | ${jq} '.pid')
                      if kill -0 "$pid" 2>/dev/null; then
                        echo "Failed to kill process $pid. Retrying..."
                        kill -9 "$pid"
                      fi
                    done

                    # Step 3: Query windows again to ensure there are no windows
                    if [[ $(${yabai} -m query --windows | ${jq} 'length') -ne 0 ]]; then
                      echo "Some windows are still open."
                      exit 1
                    fi

                    # Function to log debug messages
                    log_debug() {
                      echo "[DEBUG] $1"
                    }

                    # Step 4: Open MacForge if not already running
                    if ! pgrep -x "MacForge" > /dev/null; then
                      open -a MacForge -j
                      log_debug "MacForge application opened hidden, hopefully."
                    fi

                    # Step 5: Wait for MacForge to open by checking with a loop
                    timeout=30
                    while [ $timeout -gt 0 ]; do
                      macforge_window=$(${yabai} -m query --windows | ${jq} 'map(select(.app == "MacForge")) | .[0]')
                      macforge_id=$(echo "$macforge_window" | ${jq} -r '.id')
                      if [ -n "$macforge_id" ] && [ "$macforge_id" != "null" ]; then
                        log_debug "MacForge window found with ID: $macforge_id"
                        break
                      fi
                      log_debug "Waiting for MacForge window to appear..."
                      sleep 1
                      ((timeout--))
                    done

                    if [ $timeout -le 0 ]; then
                      log_debug "MacForge window did not appear after 30 seconds. Attempting to kill and relaunch."
                      pkill -x "MacForge"
                      open -a MacForge -j
                      log_debug "MacForge relaunched."
                    fi

                    # Step 6: Clear any existing scratchpad assignments
                    existing_scratchpads=$(${yabai} -m query --windows | ${jq} 'map(select(.scratchpad != "")) | .[].id')
                    for id in $existing_scratchpads; do
                      ${yabai} -m window "$id" --scratchpad
                      log_debug "Cleared scratchpad assignment for window ID: $id"
                    done

                    # Step 7: Use Yabai to send MacForge to scratchpad
                    macforge_id=$(${yabai} -m query --windows | ${jq} 'map(select(.app == "MacForge")) | .[0].id')
                    if [ -n "$macforge_id" ] && [ "$macforge_id" != "null" ]; then
                      ${yabai} -m window "$macforge_id" --scratchpad _1
                      log_debug "Assigned MacForge window ID: $macforge_id to scratchpad."
                    else
                      echo "Failed to find MacForge window."
                      exit 1
                    fi

                    # Step 8: Toggle scratchpad to hide/reveal MacForge
                    ${yabai} -m window --toggle _1
                    log_debug "Toggled scratchpad to hide MacForge window."
                    echo "MacForge is now hidden."

                    # Step 9: Reopen apps by name, opening each instance even if duplicated
                    for app in "''${appnames[@]}"; do
                      if [ "$app" != "MacForge" ]; then
                        open -na "$app" --args
                        log_debug "Opened new instance of $app."
                      fi
                    done

                    echo "programs started already (since boot with launchAgent or user cli)." > "/tmp/programs_started_state"
                  '';
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
