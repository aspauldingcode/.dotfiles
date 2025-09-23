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
            # macOS-specific tools for Firefox hot-reload
          ]
          ++ optionals pkgs.stdenv.isLinux [
            # Linux-specific tools
          ];

        text = ''
          set -euo pipefail

          # Parse arguments
          target_variant=""
          if [[ $# -gt 0 ]]; then
            case "$1" in
              light|dark)
                target_variant="$1"
                echo "🎯 Forcing theme to: $target_variant"
                ;;
              *)
                echo "Usage: toggle-theme [light|dark]"
                echo "  light - Force light theme"
                echo "  dark  - Force dark theme"
                echo "  (no args) - Toggle between themes"
                exit 1
                ;;
            esac
          fi

          # Get current macOS theme state
          hostname=$(scutil --get LocalHostName 2>/dev/null || hostname)
          macos_dark_mode=$(osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode' 2>/dev/null || echo "true")

          if [[ "$macos_dark_mode" == "true" ]]; then
            current_variant="dark"
          else
            current_variant="light"
          fi

          echo "Current theme variant: $current_variant"

          # Determine what to switch to
          if [[ -n "$target_variant" ]]; then
            # Force specific variant
            if [[ "$target_variant" == "$current_variant" ]]; then
              echo "ℹ️  Already using $target_variant theme, rebuilding anyway..."
            fi
            switch_to="$target_variant"
          else
            # Toggle mode
            if [[ "$current_variant" == "dark" ]]; then
              switch_to="light"
            else
              switch_to="dark"
            fi
          fi

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

            if [[ "$switch_to" == "light" ]]; then
              # Switch to light theme
              echo "Switching to light theme..."
              sudo darwin-rebuild switch --flake ~/.dotfiles#"$hostname"-light

              # Set macOS to light mode
              echo "Setting macOS to light mode..."
              osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false' 2>/dev/null || true

              echo "✓ Switched to light theme"
            else
              # Switch to dark theme
              echo "Switching to dark theme..."
              sudo darwin-rebuild switch --flake ~/.dotfiles#"$hostname"

              # Set macOS to dark mode
              echo "Setting macOS to dark mode..."
              osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' 2>/dev/null || true

              echo "✓ Switched to dark theme"
            fi

            # Hot-reload Firefox userChrome.css without restarting
            if pgrep -f "Firefox.app" >/dev/null; then
              echo "🔄 Hot-reloading Firefox userChrome.css..."

              # Create the JavaScript reload command
              js_reload_cmd='(function(){try{const ss=Components.classes["@mozilla.org/content/style-sheet-service;1"].getService(Components.interfaces.nsIStyleSheetService);const io=Components.classes["@mozilla.org/network/io-service;1"].getService(Components.interfaces.nsIIOService);const ds=Components.classes["@mozilla.org/file/directory_service;1"].getService(Components.interfaces.nsIProperties);const chromepath=ds.get("UChrm",Components.interfaces.nsIFile);chromepath.append("userChrome.css");const chromefile=io.newFileURI(chromepath);if(ss.sheetRegistered(chromefile,ss.USER_SHEET)){ss.unregisterSheet(chromefile,ss.USER_SHEET);}ss.loadAndRegisterSheet(chromefile,ss.USER_SHEET);console.log("✅ userChrome.css reloaded");return "Success!";}catch(e){console.error("❌ Error:",e);return "Failed: "+e.message;}})()'

              # Use AppleScript to send the reload command to Firefox Browser Console
              osascript -e "
                tell application \"Firefox\" to activate
                delay 0.3
                tell application \"System Events\"
                  key code 38 using {command down, shift down}  -- Cmd+Shift+J to open Browser Console
                  delay 0.8
                  keystroke \"$js_reload_cmd\"
                  delay 0.2
                  key code 36  -- Enter key
                  delay 0.5
                  key code 38 using {command down, shift down}  -- Cmd+Shift+J to close Browser Console
                end tell
              " 2>/dev/null && echo "✅ Firefox userChrome.css hot-reloaded" || echo "⚠️  Firefox hot-reload failed, userChrome.css will apply on next restart"
            else
              echo "ℹ️  Firefox not running, userChrome.css changes will apply when Firefox starts"
            fi
          ''}

          ${optionalString pkgs.stdenv.isLinux ''
            # NixOS system specialisation switching
            echo "Switching theme on NixOS..."

            # Get current system generation
            current_system=$(readlink /run/current-system)

            if [[ "$switch_to" == "light" ]]; then
              # Switch to light specialisation
              echo "Switching to light theme..."
              if [[ -d "$current_system/specialisation/light-theme" ]]; then
                sudo "$current_system"/specialisation/light-theme/bin/switch-to-configuration switch
                echo "✓ Switched to light theme"
              else
                echo "❌ Light theme specialisation not found"
                exit 1
              fi
            else
              # Switch back to base system (dark theme)
              echo "Switching to dark theme..."
              base_system=$(echo "$current_system" | sed 's|/specialisation/light-theme||')
              sudo "$base_system"/bin/switch-to-configuration switch
              echo "✓ Switched to dark theme"
            fi

            # Hot-reload Firefox userChrome.css without restarting
            if pgrep -f firefox >/dev/null; then
              echo "🔄 Firefox detected. For userChrome.css hot-reload:"
              echo "   1. Open Firefox Browser Console with Ctrl+Shift+J"
              echo "   2. Paste and run this command:"
              echo "   (function(){try{const ss=Components.classes['@mozilla.org/content/style-sheet-service;1'].getService(Components.interfaces.nsIStyleSheetService);const io=Components.classes['@mozilla.org/network/io-service;1'].getService(Components.interfaces.nsIIOService);const ds=Components.classes['@mozilla.org/file/directory_service;1'].getService(Components.interfaces.nsIProperties);const chromepath=ds.get('UChrm',Components.interfaces.nsIFile);chromepath.append('userChrome.css');const chromefile=io.newFileURI(chromepath);if(ss.sheetRegistered(chromefile,ss.USER_SHEET)){ss.unregisterSheet(chromefile,ss.USER_SHEET);}ss.loadAndRegisterSheet(chromefile,ss.USER_SHEET);console.log('✅ userChrome.css reloaded');return 'Success!';}catch(e){console.error('❌ Error:',e);return 'Failed: '+e.message;}})()"
              echo ""
              echo "💡 Tip: Bookmark this command in Firefox for quick access!"
            else
              echo "ℹ️  Firefox not running, userChrome.css changes will apply when Firefox starts"
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
