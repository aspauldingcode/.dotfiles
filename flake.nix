{
  description = "Universal Flake by Alex - macOS and NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05"; # Set to the desired stable version
    unstable_nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # Use nixos-specific branch
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs"; # Ensure home-manager follows the stable nixpkgs version
    };
    nix-colors.url = "github:misterio77/nix-colors";

    nix-darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-25.05"; # Match nixpkgs version
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
      inputs.nixpkgs.follows = "unstable_nixpkgs"; # Follows the unstable nixpkgs version
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

    mac-app-util = {
      url = "github:hraban/mac-app-util";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # Homebrew taps
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
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
    # homebrew-kde = {
    #   url = "github:kde-mac/kde";
    #   flake = false;
    # };
    nix-rosetta-builder = {
      url = "github:cpick/nix-rosetta-builder";
      inputs.nixpkgs.follows = "unstable_nixpkgs";
    };
    frida-nix = {
      url = "github:itstarsun/frida-nix";
    };

    # Add sops-nix input
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
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
      nixtheplanet,
      mac-app-util,
      spicetify-nix,
      nix-homebrew,
      homebrew-core,
      homebrew-koekeishiya,
      homebrew-felixkratz,
      homebrew-smudge,
      homebrew-cask,
      nix-rosetta-builder,
      frida-nix,
      sops-nix,
    }@inputs:
    let
      user = "alex";
      inherit (self) inputs;
      std = nix-std.lib;

      # Import sops configuration from external file
      sopsConfigs = import ./sops-nix/sopsConfig.nix { inherit nixpkgs user; };
      inherit (sopsConfigs)
        commonSopsConfigBase
        nixosSopsConfig
        hmSopsConfig
        commonSopsConfig
        ;

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
          user
          commonSopsConfig
          nixosSopsConfig
          hmSopsConfig
          ;
      };
      commonExtraSpecialArgs = commonSpecialArgs;

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
            ./system/NIXSTATION64
            ./shared/scripts
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${user} = import ./users/${user}/NIXSTATION64;
                extraSpecialArgs = commonExtraSpecialArgs;
                backupFileExtension = "backup";
                sharedModules = [
                  sops-nix.homeManagerModules.sops
                  { imports = [ hmSopsConfig ]; }
                ];
              };
            }
            sops-nix.nixosModules.sops
            { imports = [ nixosSopsConfig ]; }
          ];
        };
        NIXEDUP = nixpkgs.lib.nixosSystem {
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
          specialArgs = commonSpecialArgs;
          modules = [
            ./system/NIXEDUP/configuration-NIXEDUP.nix
            ./shared/scripts
            sops-nix.nixosModules.sops
            { imports = [ nixosSopsConfig ]; }
          ];
        };
        NIXY2 = unstable_nixpkgs.lib.nixosSystem {
          pkgs = import unstable_nixpkgs {
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
            ./system/NIXY2
            ./shared/scripts
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${user} = import ./users/${user}/NIXY2;
                extraSpecialArgs = commonExtraSpecialArgs;
                backupFileExtension = "backup";
                sharedModules = [
                  sops-nix.homeManagerModules.sops
                  { imports = [ hmSopsConfig ]; }
                ];
              };
            }
            sops-nix.nixosModules.sops
            { imports = [ nixosSopsConfig ]; }
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
              inputs.frida-nix.overlays.default
              (final: _prev: {
                unstable = import unstable_nixpkgs {
                  inherit (final) system config;
                };
              })
              (final: prev: {
                nodejs = prev.nodejs_22;
                nodejs-slim = prev.nodejs-slim_22;

                nodejs_20 = prev.nodejs_22;
                nodejs-slim_20 = prev.nodejs-slim_22;
              })
            ];
          };
          specialArgs = commonSpecialArgs;
          modules = [
            ./system/NIXY
            ./shared/scripts
            mac-app-util.darwinModules.default
            home-manager.darwinModules.home-manager
            sops-nix.darwinModules.sops
            nix-homebrew.darwinModules.nix-homebrew
            spicetify-nix.darwinModules.default
            { imports = [ nixosSopsConfig ]; }
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = commonExtraSpecialArgs;
                backupFileExtension = "backup";
                sharedModules = [
                  mac-app-util.homeManagerModules.default
                  sops-nix.homeManagerModules.sops
                  { imports = [ hmSopsConfig ]; }
                  spicetify-nix.homeManagerModules.default
                ];
                users.${user} = {
                  imports = [
                    ./users/${user}/NIXY
                  ];
                  home = {
                    username = "${user}";
                    homeDirectory = nixpkgs.lib.mkForce "/Users/${user}";
                  };
                };
              };
            }
            # An existing Linux builder is needed to initially bootstrap nix-rosetta-builder.
            # If one isn't already available: comment out the nix-rosetta-builder module below,
            # uncomment this linux-builder module, and run darwin-rebuild switch:
            # { nix.linux-builder.enable = true; }
            # Then: uncomment nix-rosetta-builder, remove linux-builder, and darwin-rebuild switch
            # a second time. Subsequently, nix-rosetta-builder can rebuild itself.
            # nix-rosetta-builder.darwinModules.default
          ];
        };
      };
    in
    {
      # Return all the configurations
      nixosConfigurations = nixosConfigurations;
      darwinConfigurations = darwinConfigurations;

      # Define apps that can be run with 'nix run'
      apps = eachSystem (pkgs: {
        default = {
          type = "app";
          meta.description = "System configuration installer [TUI] - sets up dotfiles, and all prerequisites";
          program = toString (
            pkgs.writeShellScript "sync-age-key" ''
              export PATH="${pkgs.git}/bin:${pkgs.gh}/bin:${pkgs.ncurses}/bin:${pkgs.dialog}/bin:${pkgs.darwin.cctools}/bin:$PATH"

              if [[ "$(uname)" == "Darwin" ]]; then
                sip_status=$(${pkgs.bash}/bin/bash -c "csrutil status" 2>/dev/null)

                if [[ -z "$sip_status" ]]; then
                  dialog --title "❌ SIP Check Failed" --msgbox "Could not determine SIP status.

                  Make sure you're running this on macOS, and try again." 10 60
                  exit 2
                fi

                if echo "$sip_status" | grep -q "enabled"; then
                  dialog --title "❌ SIP is Enabled" --msgbox "System Integrity Protection (SIP) is currently ENABLED.

                  You MUST disable SIP to proceed.

                  🚫 How to Disable SIP:

                  1. Reboot into Recovery Mode:
                    - Intel: Hold ⌘ + R
                    - Apple Silicon: Hold Power → Options

                  2. Open Terminal from Utilities.

                  3. Run:
                    csrutil disable

                  4. Reboot." 20 70
                  exit 3
                fi

                dialog --title "✅ SIP Status" --infobox "$sip_status

                  Proceeding..." 10 60
                sleep 3
                ${toString ./.}/sops-nix/sync-age-key.sh

                # Ask the user first if they want to install dotfiles
                dialog --title "Install dotfiles?" --yesno "Do you want to install the aspauldingcode .dotfiles configuration?" 10 60

                response=$?
                if [ $response -ne 0 ]; then
                  dialog --title "Skipped" --msgbox "Dotfiles installation skipped." 5 40
                  exit 0
                fi

                # Step 1: Explain Full Disk Access requirement
                dialog --title "📂 Terminal Needs Full Disk Access" --msgbox "Before installing, you MUST grant Full Disk Access to Terminal.

                Why? The installer may read sensitive configuration files (like keychains, SSH configs, etc).

                You will now be prompted to grant access and taken to the correct System Settings screen.

                After enabling access, return to this window and press OK." 20 70

                # Step 2: Trigger protected access to prompt the system
                touch /tmp/fda-check.txt 2>/dev/null
                cat ~/Library/Application\ Support/com.apple.TCC/TCC.db >/dev/null 2>&1 || true

                # Step 3: Open the Full Disk Access settings pane
                open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"

                # Step 4: Confirm access was granted
                dialog --title "📂 Grant Full Disk Access" --yesno "Once you've enabled Full Disk Access for Terminal, press 'Yes' to continue installation.

                If you're unsure, follow these steps:
                1. In the opened System Settings pane, find 'Full Disk Access'
                2. Enable:
                  /Applications/Utilities/Terminal.app
                3. Then return here." 15 70

                response=$?
                if [ $response -ne 0 ]; then
                  dialog --title "❌ Installation Aborted" --msgbox "You chose not to continue. Full Disk Access is required for installation." 7 60
                  exit 4
                fi

                # Step 5: Ensure Xcode CLI tools are installed before proceeding
                while ! xcode-select -p >/dev/null 2>&1; do
                  dialog --title "🛠️ Installing Xcode CLI Tools" --msgbox "Xcode Command Line Tools are not installed.

                A system prompt will appear. Click 'Install' to continue.

                After installation finishes, return here and press OK." 15 60

                  # Trigger the installer (harmless if already open)
                  xcode-select --install 2>/dev/null || true

                  # Bring the installer window to the front
                  open -a "Install Command Line Developer Tools" 2>/dev/null || true

                  dialog --title "🕒 Still Installing..." --yesno "Have you finished installing the Xcode Command Line Tools?

                This is required before continuing.

                Would you like to check again?" 12 60

                  response=$?
                  if [ "$response" -ne 0 ]; then
                    dialog --title "❌ Required" --msgbox "You must install the Xcode CLI tools to continue." 7 50
                  fi
                done

                # Confirm success
                dialog --title "✅ Xcode CLI Tools" --msgbox "Xcode Command Line Tools are installed. Continuing..." 7 50

                # Step 6: Accept Xcode license (required for many tools to run)
                sudo xcodebuild -license accept

                # Step 7: Clone Dotfiles optionally
                dialog --title "Clone Dotfiles" --yesno "Would you like to clone the aspauldingcode dotfiles repository to ~/.dotfiles?" 10 60

                response=$?
                if [ $response -eq 0 ]; then
                  dialog --title "📥 Cloning..." --infobox "Cloning dotfiles into ~/.dotfiles..." 5 50
                  sleep 1
                  git clone git@github.com:aspauldingcode/.dotfiles.git ~/.dotfiles/

                  if [ $? -eq 0 ]; then
                    dialog --title "✅ Success" --msgbox "Dotfiles cloned successfully to ~/.dotfiles." 6 50
                  else
                    dialog --title "❌ Failed" --msgbox "Failed to clone the dotfiles repository.

                Make sure your SSH key is set up and you have access to the repo." 10 60
                  fi
                else
                  dialog --title "Skipped" --msgbox "Skipping dotfiles clone." 6 40
                fi


                # Step 8: Proceed with dotfiles installation
                echo "Installing dotfiles..."
                sleep 1

                sudo nix run github:LnL7/nix-darwin -- switch --show-trace --flake github:aspauldingcode/.dotfiles#NIXY

                if [ -d "$HOME/.dotfiles" ]; then
                  zsh -c "rebuild"
                fi

                zsh
              fi
            ''
          );
        };
      });

      # FIXME: add nixvim here so I can build from any device without installing the dotfiles.
      devShells =
        nixpkgs.lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-linux"
            "x86_64-darwin"
            "aarch64-darwin"
          ]
          (
            system:
            let
              pkgs = nixpkgs.legacyPackages.${system};
              isDarwin = pkgs.stdenv.isDarwin;

              defaultShell = pkgs.mkShell {
                buildInputs =
                  with pkgs;
                  [
                    bat
                  ]
                  ++ (
                    if isDarwin then
                      [
                        dialog
                        ncurses
                      ]
                    else
                      [ ]
                  );

                shellHook = ''
                  echo -e "\033[0;34mHow's it going fam?\033[0m"
                  echo "This devshell will eventually be nixvim config."
                '';
              };
            in
            {
              default = defaultShell;
            }
          );
    };
}
