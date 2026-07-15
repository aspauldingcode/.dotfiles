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

    # Master-only: programs.mas (PR #1668). Keep main nix-darwin on 26.05;
    # import just modules/programs/mas.nix from this input.
    nix-darwin-unstable = {
      url = "github:nix-darwin/nix-darwin/master";
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

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate-nix.url = "github:DeterminateSystems/determinate";

    stylix.url = "github:danth/stylix/release-26.05";

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Asahi Linux out-of-tree kernel + firmware (not yet fully upstream).
    # Host mba-asahi imports apple-silicon-support → boot.kernelPackages = linux-asahi.
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

          apps.secrets-bootstrap = {
            type = "app";
            program =
              let
                script = pkgs.writeShellApplication {
                  name = "secrets-bootstrap";
                  runtimeInputs = with pkgs; [
                    coreutils
                    gh
                    python3
                    gnugrep
                    bash
                  ];
                  text = ''
                    set -euo pipefail
                    export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
                    exec bash ${./scripts/secrets-bootstrap.sh} "$@"
                  '';
                };
              in
              "${script}/bin/secrets-bootstrap";
          };

          apps.ssh-enroll = {
            type = "app";
            program =
              let
                script = pkgs.writeShellApplication {
                  name = "ssh-enroll";
                  runtimeInputs = with pkgs; [
                    coreutils
                    ssh-to-age
                    sops
                    age
                    python3
                    git
                    gnugrep
                    bash
                  ];
                  text = ''
                    set -euo pipefail
                    # Live checkout (writable); never bake flake source via toString (strips context).
                    export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
                    exec bash ${./scripts/ssh-enroll.sh} "$@"
                  '';
                };
              in
              "${script}/bin/ssh-enroll";
          };

          apps.ssh-rotate = {
            type = "app";
            program =
              let
                script = pkgs.writeShellApplication {
                  name = "ssh-rotate";
                  runtimeInputs = with pkgs; [
                    coreutils
                    ssh-to-age
                    sops
                    age
                    python3
                    git
                    gnugrep
                    bash
                  ];
                  text = ''
                    set -euo pipefail
                    # Live checkout (writable); never bake flake source via toString (strips context).
                    export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
                    exec bash ${./scripts/ssh-rotate.sh} "$@"
                  '';
                };
              in
              "${script}/bin/ssh-rotate";
          };

          apps.pass-genesis = {
            type = "app";
            program =
              let
                script = pkgs.writeShellApplication {
                  name = "pass-genesis";
                  runtimeInputs = with pkgs; [
                    coreutils
                    gnupg
                    (pass.withExtensions (exts: [ exts.pass-otp ]))
                    sops
                    openssl
                    git
                    python3
                    bash
                  ];
                  text = ''
                    set -euo pipefail
                    export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel)}"
                    exec bash ${./scripts/pass-genesis.sh} "$@"
                  '';
                };
              in
              "${script}/bin/pass-genesis";
          };

          apps.pass-rotate = {
            type = "app";
            program =
              let
                script = pkgs.writeShellApplication {
                  name = "pass-rotate";
                  runtimeInputs = with pkgs; [
                    coreutils
                    findutils
                    gawk
                    gnupg
                    (pass.withExtensions (exts: [ exts.pass-otp ]))
                    sops
                    openssl
                    git
                    python3
                    bash
                  ];
                  text = ''
                    set -euo pipefail
                    export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel)}"
                    exec bash ${./scripts/pass-rotate-gpg.sh} "$@"
                  '';
                };
              in
              "${script}/bin/pass-rotate";
          };

          apps.pass-rotate-cli-auth = {
            type = "app";
            program =
              let
                mint = pkgs.writeShellApplication {
                  name = "github-app-mint-token";
                  runtimeInputs = with pkgs; [
                    coreutils
                    curl
                    gnugrep
                    gnupg
                    git
                    python3
                    (pass.withExtensions (exts: [ exts.pass-otp ]))
                    bash
                  ];
                  text = ''
                    set -euo pipefail
                    export PASSWORD_STORE_DIR="''${PASSWORD_STORE_DIR:-$HOME/.password-store}"
                    exec bash ${./scripts/github-app-mint-token.sh} "$@"
                  '';
                };
                gcloudMint = pkgs.writeShellApplication {
                  name = "gcloud-mint-token";
                  runtimeInputs = with pkgs; [
                    coreutils
                    curl
                    gnugrep
                    gnupg
                    git
                    python3
                    (pass.withExtensions (exts: [ exts.pass-otp ]))
                    bash
                  ];
                  text = ''
                    set -euo pipefail
                    export PASSWORD_STORE_DIR="''${PASSWORD_STORE_DIR:-$HOME/.password-store}"
                    export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel)}"
                    export OAUTH_SERVER_PY=${./scripts/gcloud-oauth-server.py}
                    exec bash ${./scripts/gcloud-mint-token.sh} "$@"
                  '';
                };
                fhMint = pkgs.writeShellApplication {
                  name = "flakehub-mint-token";
                  runtimeInputs = with pkgs; [
                    coreutils
                    gnugrep
                    gnupg
                    (pass.withExtensions (exts: [ exts.pass-otp ]))
                    fh
                    bash
                  ];
                  text = ''
                    set -euo pipefail
                    export PASSWORD_STORE_DIR="''${PASSWORD_STORE_DIR:-$HOME/.password-store}"
                    export FLAKEHUB_ORG="''${FLAKEHUB_ORG:-aspauldingcode}"
                    exec bash ${./scripts/flakehub-mint-token.sh} "$@"
                  '';
                };
                script = pkgs.writeShellApplication {
                  name = "pass-rotate-cli-auth";
                  runtimeInputs = with pkgs; [
                    coreutils
                    curl
                    gnugrep
                    gnupg
                    git
                    python3
                    (pass.withExtensions (exts: [ exts.pass-otp ]))
                    fh
                    gh
                    bash
                    mint
                    gcloudMint
                    fhMint
                  ];
                  text = ''
                    set -euo pipefail
                    export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel)}"
                    export PASSWORD_STORE_DIR="''${PASSWORD_STORE_DIR:-$HOME/.password-store}"
                    export FLAKEHUB_ORG="''${FLAKEHUB_ORG:-aspauldingcode}"
                    export OAUTH_SERVER_PY=${./scripts/gcloud-oauth-server.py}
                    exec bash ${./scripts/pass-rotate-cli-auth.sh} "$@"
                  '';
                };
              in
              "${script}/bin/pass-rotate-cli-auth";
          };

          apps.pass-flakehub-bootstrap = {
            type = "app";
            program =
              let
                fhMint = pkgs.writeShellApplication {
                  name = "flakehub-mint-token";
                  runtimeInputs = with pkgs; [
                    coreutils
                    gnugrep
                    gnupg
                    (pass.withExtensions (exts: [ exts.pass-otp ]))
                    fh
                    bash
                  ];
                  text = ''
                    set -euo pipefail
                    export PASSWORD_STORE_DIR="''${PASSWORD_STORE_DIR:-$HOME/.password-store}"
                    export FLAKEHUB_ORG="''${FLAKEHUB_ORG:-aspauldingcode}"
                    exec bash ${./scripts/flakehub-mint-token.sh} "$@"
                  '';
                };
                script = pkgs.writeShellApplication {
                  name = "pass-flakehub-bootstrap";
                  runtimeInputs = with pkgs; [
                    coreutils
                    gnugrep
                    gnupg
                    git
                    (pass.withExtensions (exts: [ exts.pass-otp ]))
                    fh
                    bash
                    fhMint
                  ];
                  text = ''
                    set -euo pipefail
                    export PASSWORD_STORE_DIR="''${PASSWORD_STORE_DIR:-$HOME/.password-store}"
                    export FLAKEHUB_ORG="''${FLAKEHUB_ORG:-aspauldingcode}"
                    export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel)}"
                    exec bash ${./scripts/pass-flakehub-bootstrap.sh} "$@"
                  '';
                };
              in
              "${script}/bin/pass-flakehub-bootstrap";
          };

          apps.pass-wifi-bootstrap = {
            type = "app";
            program =
              let
                script = pkgs.writeShellApplication {
                  name = "pass-wifi-bootstrap";
                  runtimeInputs = with pkgs; [
                    coreutils
                    gnugrep
                    gnupg
                    git
                    (pass.withExtensions (exts: [ exts.pass-otp ]))
                    bash
                  ];
                  text = ''
                    set -euo pipefail
                    export PASSWORD_STORE_DIR="''${PASSWORD_STORE_DIR:-$HOME/.password-store}"
                    export WIFI_NETWORKS_JSON=${./home/wifi-networks.json}
                    exec bash ${./scripts/pass-wifi-bootstrap.sh} "$@"
                  '';
                };
              in
              "${script}/bin/pass-wifi-bootstrap";
          };

          apps.pass-gcloud-bootstrap = {
            type = "app";
            program =
              let
                mint = pkgs.writeShellApplication {
                  name = "gcloud-mint-token";
                  runtimeInputs = with pkgs; [
                    coreutils
                    curl
                    gnugrep
                    gnupg
                    git
                    python3
                    (pass.withExtensions (exts: [ exts.pass-otp ]))
                    bash
                  ];
                  text = ''
                    set -euo pipefail
                    export PASSWORD_STORE_DIR="''${PASSWORD_STORE_DIR:-$HOME/.password-store}"
                    export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel)}"
                    export OAUTH_SERVER_PY=${./scripts/gcloud-oauth-server.py}
                    exec bash ${./scripts/gcloud-mint-token.sh} "$@"
                  '';
                };
                script = pkgs.writeShellApplication {
                  name = "pass-gcloud-bootstrap";
                  runtimeInputs = with pkgs; [
                    coreutils
                    curl
                    gnupg
                    git
                    python3
                    (pass.withExtensions (exts: [ exts.pass-otp ]))
                    bash
                    mint
                  ];
                  text = ''
                    set -euo pipefail
                    export PASSWORD_STORE_DIR="''${PASSWORD_STORE_DIR:-$HOME/.password-store}"
                    export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel)}"
                    export OAUTH_SERVER_PY=${./scripts/gcloud-oauth-server.py}
                    exec bash ${./scripts/pass-gcloud-bootstrap.sh} "$@"
                  '';
                };
              in
              "${script}/bin/pass-gcloud-bootstrap";
          };

          apps.pass-github-app-bootstrap = {
            type = "app";
            program =
              let
                mint = pkgs.writeShellApplication {
                  name = "github-app-mint-token";
                  runtimeInputs = with pkgs; [
                    coreutils
                    curl
                    gnugrep
                    gnupg
                    git
                    python3
                    (pass.withExtensions (exts: [ exts.pass-otp ]))
                    bash
                  ];
                  text = ''
                    set -euo pipefail
                    export PASSWORD_STORE_DIR="''${PASSWORD_STORE_DIR:-$HOME/.password-store}"
                    exec bash ${./scripts/github-app-mint-token.sh} "$@"
                  '';
                };
                script = pkgs.writeShellApplication {
                  name = "pass-github-app-bootstrap";
                  runtimeInputs = with pkgs; [
                    coreutils
                    curl
                    gnupg
                    git
                    python3
                    (pass.withExtensions (exts: [ exts.pass-otp ]))
                    bash
                    mint
                  ];
                  text = ''
                    set -euo pipefail
                    export PASSWORD_STORE_DIR="''${PASSWORD_STORE_DIR:-$HOME/.password-store}"
                    export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel)}"
                    export MANIFEST_PATH=${./home/github-app-manifest.json}
                    export SERVER_PY=${./scripts/github-app-manifest-server.py}
                    exec bash ${./scripts/pass-github-app-bootstrap.sh} "$@"
                  '';
                };
              in
              "${script}/bin/pass-github-app-bootstrap";
          };

          apps.pass-provision = {
            type = "app";
            program =
              let
                script = pkgs.writeShellApplication {
                  name = "pass-provision";
                  runtimeInputs = with pkgs; [
                    coreutils
                    findutils
                    gawk
                    gnupg
                    (pass.withExtensions (exts: [ exts.pass-otp ]))
                    sops
                    openssl
                    git
                    gh
                    python3
                    nix
                    bash
                  ];
                  text = ''
                    set -euo pipefail
                    export DOTFILES_ROOT="''${DOTFILES_ROOT:-$(git rev-parse --show-toplevel)}"
                    exec bash ${./scripts/pass-provision.sh} "$@"
                  '';
                };
              in
              "${script}/bin/pass-provision";
          };
        };

    };
}
