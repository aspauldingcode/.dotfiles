# Universal Theme Toggle Module
# Can be used by both NixOS and nix-darwin systems
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.services.theme-toggle = {
    enable = mkEnableOption "theme toggle functionality";

    package = mkOption {
      type = types.package;
      description = "The theme toggle package to use";
      default = pkgs.writeShellApplication {
        name = "toggle-theme";
        runtimeInputs =
          with pkgs;
          [
            coreutils
            ripgrep
          ]
          ++ optionals pkgs.stdenv.isDarwin [
            # macOS-specific tools
          ]
          ++ optionals pkgs.stdenv.isLinux [
            # Linux-specific tools
          ];

        text = ''
          set -euo pipefail

          # Get current macOS theme state
          hostname=$(scutil --get LocalHostName 2>/dev/null || hostname)
          macos_dark_mode=$(osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode' 2>/dev/null || echo "true")

          if [[ "$macos_dark_mode" == "true" ]]; then
            current_variant="dark"
          else
            current_variant="light"
          fi

          echo "Current theme variant: $current_variant"

          ${optionalString pkgs.stdenv.isDarwin ''
            # macOS nix-darwin specialisation switching
            echo "Toggling theme specialisation on macOS..."

            # Get current system generation
            current_system=$(readlink /run/current-system 2>/dev/null || echo "")

            if [[ -z "$current_system" ]]; then
              echo "❌ Could not find current system generation"
              exit 1
            fi

            # Get hostname for flake configuration
            hostname=$(scutil --get LocalHostName 2>/dev/null || hostname)

            if [[ "$current_variant" == "dark" ]]; then
              # Switch to light theme
              echo "Switching from dark to light theme..."
              sudo darwin-rebuild switch --flake ~/.dotfiles#"$hostname"-light
              
              # Set macOS to light mode
              echo "Setting macOS to light mode..."
              osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false' 2>/dev/null || true
              
              echo "✓ Switched to light theme"
            else
              # Switch to dark theme
              echo "Switching from light to dark theme..."
              sudo darwin-rebuild switch --flake ~/.dotfiles#"$hostname"
              
              # Set macOS to dark mode
              echo "Setting macOS to dark mode..."
              osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' 2>/dev/null || true
              
              echo "✓ Switched to dark theme"
            fi
          ''}

          ${optionalString pkgs.stdenv.isLinux ''
            # NixOS system specialisation switching
            echo "Toggling theme specialisation on NixOS..."

            # Get current system generation
            current_system=$(readlink /run/current-system)

            if [[ "$current_variant" == "dark" ]]; then
              # Switch to light specialisation
              echo "Switching from dark to light theme..."
              if [[ -d "$current_system/specialisation/light-theme" ]]; then
                sudo "$current_system"/specialisation/light-theme/bin/switch-to-configuration switch
                echo "✓ Switched to light theme"
              else
                echo "❌ Light theme specialisation not found"
                exit 1
              fi
            else
              # Switch back to base system (dark theme)
              echo "Switching from light to dark theme..."
              base_system=$(echo "$current_system" | sed 's|/specialisation/light-theme||')
              sudo "$base_system"/bin/switch-to-configuration switch
              echo "✓ Switched to dark theme"
            fi
          ''}
        '';
      };
    };
  };

  config = mkIf config.services.theme-toggle.enable {
    # Add the toggle-theme script to system packages
    environment.systemPackages = [ config.services.theme-toggle.package ];
  };
}
