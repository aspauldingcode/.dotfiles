{
  description = "Dendritic Nix Flake with flake-parts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixos-25.11";
    
    flake-parts.url = "github:hercules-ci/flake-parts";
    
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate-nix.url = "github:DeterminateSystems/determinate";

    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix";

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    microvm = {
      url = "path:./subrepos/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wawona = {
      url = "github:Wawona/Wawona/development";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      imports = [
        # In a fully dendritic pattern, we can import our top-level configuration modules.
        # However, for NixOS, Darwin, and Home Manager, we will define them in `flake` output
        # or use flake-parts modules if we're setting up the entire config matrix.
        ./modules
      ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # Formatter for `nix fmt`
        formatter = pkgs.nixfmt;

        # Development shell available via `nix develop`
        devShells.default = pkgs.mkShell {
          name = "dotfiles-devshell";
          buildInputs = with pkgs; [
            git
            nixfmt
            sops
            age
          ] ++ [
            inputs'.nixvim.packages.default
          ];
        };

        apps.install = {
          type = "app";
          program = let
            installScript = pkgs.writeShellApplication {
              name = "install-system";
              runtimeInputs = [ 
                pkgs.git 
                pkgs.nh 
                pkgs.nix 
              ];
              text = ''
                set -e
                
                REPO_URL="git@github.com:aspauldingcode/.dotfiles.git"

                # Determine the system config directory based on OS
                if [[ "$OSTYPE" == "darwin"* ]]; then
                   TARGET_DIR="/etc/nix-darwin/.dotfiles"
                else
                   TARGET_DIR="/etc/nixos"
                fi

                if [ ! -d "$TARGET_DIR" ]; then
                  echo "Cloning $REPO_URL to $TARGET_DIR..."
                  sudo git clone "$REPO_URL" "$TARGET_DIR"
                fi

                cd "$TARGET_DIR"

                # Ensure Applications directory exists and is writable by the current user
                if [ -d "$HOME/Applications" ]; then
                   sudo chown "$USER" "$HOME/Applications"
                   sudo chmod 755 "$HOME/Applications"
                else
                   mkdir -p "$HOME/Applications"
                fi

                if [[ "$OSTYPE" == "darwin"* ]]; then
                   # 1. Prime Touch ID for the very first switch
                   if [ ! -f /etc/pam.d/sudo_local ]; then
                      echo "Priming native Touch ID support..."
                      echo "auth       sufficient     pam_tid.so" | sudo tee /etc/pam.d/sudo_local > /dev/null
                   fi

                   # 2. Run the switch (this will trigger the maintenance module automatically)
                   nh darwin switch -H mba "$TARGET_DIR"
                else
                   nh os switch "$TARGET_DIR"
                fi

                echo "Installation complete!"
                exit 0
              '';
            };
          in "${installScript}/bin/install-system";
        };

        apps.uninstall = {
          type = "app";
          program = let
            uninstallScript = pkgs.writeShellApplication {
              name = "uninstall-system";
              runtimeInputs = [ pkgs.dialog pkgs.nix pkgs.nh pkgs.sudo ];
              text = ''
                set -e
                
                if ! dialog --title "Uninstall Dendritic Nix" \
                            --yesno "This will uninstall nix-darwin and reset the profile. Are you sure?" 10 60; then
                  clear
                  exit 0
                fi
                
                clear
                echo "Starting uninstallation..."
                
                if command -v darwin-uninstaller &> /dev/null; then
                  sudo darwin-uninstaller
                else
                  sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin#darwin-uninstaller
                fi
                
                sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old || true
                sudo rm -rf /nix/var/nix/profiles/system* || true
                sudo nix-collect-garbage -d
                
                echo "Uninstallation complete!"
              '';
            };
          in "${uninstallScript}/bin/uninstall-system";
        };
      };

      flake = {
        # NixOS, Darwin, and Home Manager configurations will be built dynamically
        # or defined in the flake-module.
      };
    };
}