# CI/CD Module - Continuous integration and deployment
_:
{
  perSystem =
    {
      self',
      pkgs,
      ...
    }:
    {
      packages = {
        # CI/CD scripts
        ci-check = pkgs.writeShellScriptBin "ci-check" ''
          set -euo pipefail
          echo "Running CI checks..."

          # Check flake
          nix flake check --no-build

          # Format check
          nix fmt

          # Build all systems (dry-run)
          nix build .#nixosConfigurations.NIXSTATION64.config.system.build.toplevel --dry-run
          nix build .#nixosConfigurations.NIXY2.config.system.build.toplevel --dry-run
          nix build .#darwinConfigurations.NIXY.system --dry-run
          nix build .#darwinConfigurations.NIXI.system --dry-run

          echo "All CI checks passed!"
        '';

        ci-deploy = pkgs.writeShellScriptBin "ci-deploy" ''
          set -euo pipefail
          echo "Running deployment..."

          # Deploy based on hostname
          case "$(hostname)" in
            "NIXSTATION64")
              sudo nixos-rebuild switch --flake .#NIXSTATION64
              ;;
            "NIXY2")
              sudo nixos-rebuild switch --flake .#NIXY2
              ;;
            "NIXY")
              darwin-rebuild switch --flake .#NIXY
              ;;
            "NIXI")
              darwin-rebuild switch --flake .#NIXI
              ;;
            *)
              echo "Unknown hostname: $(hostname)"
              exit 1
              ;;
          esac

          echo "Deployment completed!"
        '';
      };

      apps = {
        # CI check app
        ci-check = {
          type = "app";
          program = "${self'.packages.ci-check}/bin/ci-check";
          meta.description = "Run CI checks for the flake";
        };

        # CI deploy app
        ci-deploy = {
          type = "app";
          program = "${self'.packages.ci-deploy}/bin/ci-deploy";
          meta.description = "Deploy system configuration via CI";
        };
      };
    };
}
