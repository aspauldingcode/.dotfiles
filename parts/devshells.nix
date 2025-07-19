# Development Shells Module
{ inputs, ... }:
{
  perSystem =
    {
      config,
      self',
      inputs',
      pkgs,
      system,
      ...
    }:
    {
      devShells = {
        default = pkgs.mkShell {
          name = "dotfiles-dev";

          packages =
            with pkgs;
            [
              # Nix development tools
              nixpkgs-fmt
              statix
              deadnix
              alejandra
              nil
              nix-tree
              nix-diff

              # General development tools
              bat
              tree
              git
              jq
              yq

              # Mobile development (for Mobile NixOS)
              android-tools # includes fastboot

              # System tools
              htop
              neofetch
            ]
            ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
              # macOS specific tools
              m-cli
              mas
              terminal-notifier
            ];

          shellHook = ''
            echo "🚀 Welcome to the dotfiles development environment!"
            echo "Available tools:"
            echo "  - nixpkgs-fmt: Format Nix files"
            echo "  - statix: Lint Nix files"
            echo "  - deadnix: Find dead Nix code"
            echo "  - alejandra: Alternative Nix formatter"
            echo "  - nix flake check: Validate flake"
            echo ""
            echo "Mobile NixOS tools:"
            echo "  - fastboot: Flash mobile devices"
            echo "  - android-tools: Android development tools"
            echo ""
          '';
        };

        # Secrets management development shell
        secrets = pkgs.mkShell {
          name = "secrets-dev";

          packages = with pkgs; [
            # Core secrets management tools
            sops
            age
            dialog
            yq-go
            jq

            # Development and debugging tools
            bat
            tree
            git
            gnused
            gnugrep
            gawk
            coreutils
            findutils

            # Custom secrets manager
            self'.packages.secrets-manager
          ];

          shellHook = ''
            echo "🔐 Secrets Management Development Environment"
            echo "============================================="
            echo ""
            echo "Available tools:"
            echo "  - secrets-manager: Dialog-based secrets UI"
            echo "  - sops: Encrypt/decrypt secrets"
            echo "  - age: Key management"
            echo "  - dialog: Terminal UI framework"
            echo ""
            echo "Quick start:"
            echo "  secrets-manager          # Launch dialog UI"
            echo "  sops secrets/dev/secrets.yaml  # Edit secrets directly"
            echo ""
            echo "Environment variables:"
            echo "  DOTFILES_DIR=''${DOTFILES_DIR:-$(pwd)}"
            echo ""
          '';

          # Set environment variables for secrets management
          DOTFILES_DIR = "${placeholder "out"}";
        };
      };
    };
}
