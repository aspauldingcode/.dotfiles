# Packages Module
{inputs, ...}: {
  perSystem = {
    config,
    self',
    inputs',
    pkgs,
    system,
    ...
  }: {
    packages = {
      # Custom packages can be defined here
      default = pkgs.writeShellScriptBin "dotfiles-info" ''
        echo "Alex's Universal Dotfiles"
        echo "========================="
        echo "Systems supported:"
        echo "  - macOS (aarch64-darwin): NIXY"
        echo "  - NixOS x86_64: NIXSTATION64"
        echo "  - NixOS aarch64: NIXY2"
        echo "  - Mobile NixOS: NIXEDUP (OnePlus 6T)"
        echo ""
        echo "Available configurations:"
        nix flake show
      '';

      # Dialog-based secrets manager for sops-nix
      secrets-manager = pkgs.callPackage ../packages/secrets-manager.nix {};

      # Mobile NixOS installer helper
      mobile-installer = pkgs.writeShellScriptBin "mobile-installer" ''
        set -e
        echo "Mobile NixOS Installer for OnePlus 6T"
        echo "====================================="
        echo ""
        echo "Prerequisites:"
        echo "1. Device in fastboot mode"
        echo "2. Bootloader unlocked"
        echo "3. USB debugging enabled"
        echo ""
        echo "Building Mobile NixOS image..."
        nix build .#nixosConfigurations.NIXEDUP.config.system.build.android-bootimg
        echo ""
        echo "Flash with: fastboot flash boot result/boot.img"
        echo "Then: fastboot reboot"
      '';

      # README updater script
      update-readme = pkgs.writeShellScriptBin "update-readme" ''
        echo "Updating README.md with current system information..."
        # Add logic to update README with current flake outputs
        echo "README update completed!"
      '';
    };

    # Separate apps section for nixible to avoid evaluation during package builds
    apps = {
      # Nixible CLI for 8AMPS iPhone configuration
      "8AMPS" = let
        # Import nixible lib from non-flake input (GitLab source)
        nixible_lib = (import "${inputs.nixible}") {
          inherit pkgs;
          lib = pkgs.lib;
        };
        nixible_cli = nixible_lib.mkNixibleCli ../playbooks/remote-device-setup.nix;
      in {
        type = "app";
        program = "${nixible_cli}/bin/nixible";
      };
    };
  };
}
