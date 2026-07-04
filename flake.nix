{
  description = "Dendritic Nix Flake with flake-parts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    firefox-darwin.url = "github:bandithedoge/nixpkgs-firefox-darwin";

    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate-nix.url = "github:DeterminateSystems/determinate";

    stylix.url = "github:danth/stylix/release-26.05";

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Spike: aspect-oriented dendritic framework ───────────────────────
    # Scoped experiment: convert `modules/styling.nix` to a `den.aspects.*`
    # definition using den's built-in `os` custom class to collapse the
    # NixOS+Darwin Stylix duplication. Rest of the repo stays on vanilla
    # flake-parts dendritic.
    den.url = "github:denful/den";

    plugin-playground = {
      url = "github:aspauldingcode/playground/chore/installer-build-fixes";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-darwin-fork = {
      url = "github:aspauldingcode/nix-darwin/plugin-playground";
    };

  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      imports = [
        ./modules
        inputs.flake-parts.flakeModules.modules
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        {
          config,
          pkgs,
          ...
        }:
        {
          # ── treefmt: unified formatter (nix fmt) ─────────────────
          treefmt = {
            projectRootFile = "flake.nix";
            # Keep in sync with `treefmt.toml` — `treefmt-nix` builds its
            # own config from these Nix settings and ignores `treefmt.toml`,
            # so excludes only listed there would be silently bypassed by
            # the build-time `checks.<system>.treefmt` derivation. Most
            # critically: every `sops` re-encrypt rewrites the encrypted
            # envelope's metadata block (its formatting differs from
            # prettier's YAML output), so any formatter touching
            # `secrets/**` would break the next build after a secret edit.
            settings.global.excludes = [
              "subrepos/microvm.nix/**"
              "*.lock"
              "result"
              "secrets/**"
              "*.sops"
              "*.pem.sops"
              ".git/**"
              "*.patch"
              "*.xml"
              "*.xpi"
              "*.json"
              "flake_*.json"
            ];
            programs = {
              nixfmt.enable = true; # *.nix
              shfmt.enable = true; # *.sh / *.bash
              stylua.enable = true; # *.lua
              ruff.enable = true; # *.py
              prettier.enable = true; # *.{js,ts,json,css,html,md}
            };
            # swiftformat has no treefmt-nix module; keep as a passthrough
            settings.formatter.swiftformat = {
              command = "${pkgs.swiftformat}/bin/swiftformat";
              options = [ "--stdinpath" ];
              includes = [ "*.swift" ];
            };
          };

          # `nix fmt` delegates to treefmt
          formatter = config.treefmt.build.wrapper;

          # Development shell available via `nix develop`
          devShells.default = pkgs.mkShell {
            name = "dotfiles-devshell";
            buildInputs = with pkgs; [
              git
              config.treefmt.build.wrapper # treefmt + all formatters
              sops
              age
            ];
          };

          apps.install = {
            type = "app";
            program =
              let
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
                       TARGET_DIR="/etc/nixos/.dotfiles"
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
                       nh os switch "$TARGET_DIR" -H sliceanddice
                    fi

                    echo "Installation complete!"
                    exit 0
                  '';
                };
              in
              "${installScript}/bin/install-system";
          };

          apps.uninstall = {
            type = "app";
            program =
              let
                uninstallScript = pkgs.writeShellApplication {
                  name = "uninstall-system";
                  runtimeInputs = [
                    pkgs.dialog
                    pkgs.nix
                    pkgs.nh
                  ];
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
              in
              "${uninstallScript}/bin/uninstall-system";
          };
        };

    };
}
