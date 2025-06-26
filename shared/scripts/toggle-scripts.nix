{
  pkgs,
  inputs,
  config,
  lib,
  user,
  ...
}:

# window management toggle scripts - template outlines
{
  environment.systemPackages =
    with pkgs;
    [
      # toggle-microphone
      (pkgs.writeShellScriptBin "toggle-microphone" ''
        # TODO: Implement microphone status check
        echo "toggle-microphone: Not implemented"
      '')

      # toggle-gaps
      (pkgs.writeShellScriptBin "toggle-gaps" ''
        # TODO: Implement window gaps toggle
        echo "toggle-gaps: Not implemented"
      '')

      # toggle-dock
      (pkgs.writeShellScriptBin "toggle-dock" ''
        ${lib.optionalString pkgs.stdenv.isDarwin ''
          # Toggle dock auto-hide on macOS
          current_state=$(defaults read com.apple.dock autohide 2>/dev/null || echo "0")
          if [[ "$current_state" == "1" ]]; then
            defaults write com.apple.dock autohide -bool false
            echo "Dock: Now always visible"
          else
            defaults write com.apple.dock autohide -bool true
            echo "Dock: Now auto-hiding"
          fi
          killall Dock
        ''}
        ${lib.optionalString (!pkgs.stdenv.isDarwin) ''
          echo "toggle-dock: Only supported on macOS"
        ''}
      '')

      # toggle-menubar
      (pkgs.writeShellScriptBin "toggle-menubar" ''
        ${lib.optionalString pkgs.stdenv.isDarwin ''
          # Toggle menubar auto-hide on macOS
          current_state=$(defaults read NSGlobalDomain _HIHideMenuBar 2>/dev/null || echo "false")
          if [[ "$current_state" == "true" ]] || [[ "$current_state" == "1" ]]; then
            defaults write NSGlobalDomain _HIHideMenuBar -bool false
            echo "Menu Bar: Now always visible"
          else
            defaults write NSGlobalDomain _HIHideMenuBar -bool true
            echo "Menu Bar: Now auto-hiding"
          fi
          # Restart SystemUIServer to apply changes immediately
          killall SystemUIServer
        ''}
        ${lib.optionalString (!pkgs.stdenv.isDarwin) ''
          echo "toggle-menubar: Only supported on macOS"
        ''}
      '')

      # toggle-float
      (pkgs.writeShellScriptBin "toggle-float" ''
        # TODO: Implement window float toggle
        echo "toggle-float: Not implemented"
      '')

      # toggle-darkmode
      (pkgs.writeShellScriptBin "toggle-darkmode" ''
        ${lib.optionalString pkgs.stdenv.isDarwin ''
          # Toggle dark mode on macOS using AppleScript
          osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to not dark mode'

          # Get current dark mode state and display message
          current_state=$(osascript -e 'tell application "System Events" to tell appearance preferences to return dark mode')
          if [[ "$current_state" == "true" ]]; then
            echo "Dark Mode: Enabled"
          else
            echo "Dark Mode: Disabled"
          fi
        ''}
        ${lib.optionalString (!pkgs.stdenv.isDarwin) ''
          echo "toggle-darkmode: Only supported on macOS"
        ''}
      '')

      # toggle-zoom-fullscreen
      (pkgs.writeShellScriptBin "toggle-zoom-fullscreen" ''
        # TODO: Implement zoom fullscreen toggle
        echo "toggle-zoom-fullscreen: Not implemented"
      '')

      # toggle-instant-fullscreen
      (pkgs.writeShellScriptBin "toggle-instant-fullscreen" ''
        # TODO: Implement instant fullscreen toggle
        echo "toggle-instant-fullscreen: Not implemented"
      '')

      # toggle-cursor-theme
      (pkgs.writeShellScriptBin "toggle-cursor-theme" ''
        # TODO: Implement cursor theme toggle
        echo "toggle-cursor-theme: Not implemented"
      '')

      # toggle-nightlight
      (pkgs.writeShellScriptBin "toggle-nightlight" ''
        ${lib.optionalString pkgs.stdenv.isDarwin ''
          # Toggle Night Shift on macOS using nightlight CLI tool
          if command -v nightlight >/dev/null 2>&1; then
            # Use the built-in toggle command
            nightlight toggle

            # Check the new status after toggling
            sleep 0.5  # Brief pause to ensure the toggle takes effect
            status_output=$(nightlight status 2>/dev/null)

            if [[ "$status_output" == "on" ]]; then
              echo "Night Shift: Enabled"
            elif [[ "$status_output" == "off" ]]; then
              echo "Night Shift: Disabled"
            else
              echo "Night Shift: Toggled (status: $status_output)"
            fi
          else
            echo "nightlight CLI tool not found. Install with: brew install nightlight"
          fi
        ''}
        ${lib.optionalString (!pkgs.stdenv.isDarwin) ''
          echo "toggle-nightlight: Only supported on macOS"
        ''}
      '')
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      # Include nightlight package on Darwin systems
      pkgs.nightlight
    ];
}
