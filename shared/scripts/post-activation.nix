{
  config,
  pkgs,
  inputs,
  user,
  lib,
  ...
}: let
  systemType = pkgs.stdenv.hostPlatform.system;
  isDarwin = pkgs.stdenv.isDarwin;
  InputSourceSelector = lib.mkIf isDarwin (pkgs.callPackage ../../hosts/darwin/NIXY/customDerivations/inputsourceselector.nix {});
  homebrewPath =
    if systemType == "aarch64-darwin"
    then "/opt/homebrew/bin"
    else if systemType == "x86_64-darwin"
    then "/usr/local/bin"
    else throw "Homebrew Unsupported architecture: ${systemType}";
in {
  system.activationScripts.postActivation = lib.mkIf isDarwin {
    text = ''
      # ===================================================================
      # Binary Quarantine Attribute Cleanup
      # Purpose: Clear quarantine flags from selected executables
      # Action:  Strip quarantine metadata from flagged binaries
      # ===================================================================

      echo "Fixing macOS binary quarantine attributes..."

      # Fix specific problematic binaries if they exist
      BINARIES=(
      )

      for binary in "''${BINARIES[@]}"; do
        if [ -f "$binary" ]; then
          echo "Removing quarantine attribute for $binary..."
          xattr -d com.apple.quarantine "$binary" 2>/dev/null || true
        fi
      done

      # ===================================================================
      # Input Source Selector
      # Purpose: Configure keyboard input source
      # Action:  Set to Unicode Hex Input mode for extended character support
      # ===================================================================

      echo -e "\033[33m=== Current enabled input sources ===\033[0m"
      echo "USER: ${user}"
      # Input source management is now handled by macOS system defaults

      # ===================================================================
      # Java Development Kit Symlink
      # Purpose: Configure system-wide JDK access
      # Action:  Create symlink to JDK in standard macOS Java location
      # ===================================================================

      # symlink (zulu) jdk23 to /Library/Java/JavaVirtualMachines/ # NEEDED for macOS!!
      ln -sf "${
        inputs.nixpkgs.legacyPackages.${systemType}.jdk23
      }/zulu-23.jdk" "/Library/Java/JavaVirtualMachines/"

      # ===================================================================
      # macOS Wallpaper Configuration
      # Purpose: Set system wallpaper with custom recoloring
      # Action:  Recolor and apply wallpaper based on color scheme
      # ===================================================================

      # create the wallpaper directory if it doesn't exist
      # mkdir -p /Users/Shared/Wallpaper/

      # echo "Recoloring Wallpapers to color scheme..."
      # gowall convert wallpaper_input -t /etc/gowall/theme.json

      # echo "Setting wallpaper..."
      # wallpaper "wallpaper_output"

      # ===================================================================
      # macOS Dark/Light Mode Configuration
      # Purpose: Set system appearance mode based on color scheme
      # Action:  Set dark mode based on nix-colors variant
      # ===================================================================

      echo "Setting macOS appearance mode..."
      # Note: Appearance mode is now handled by nix-colors and system defaults

      # ===================================================================
      # System Boot Arguments Configuration
      # Purpose: Enable preview ABI for yabai scripting and other tools
      # Action:  Set nvram boot arguments for arm64e preview ABI support
      # ===================================================================

      echo "Setting nvram boot-args preview abi for yabai scripting addition and glow/ammonia..."
      sudo nvram boot-args=-arm64e_preview_abi

      # ===================================================================
      # Glow Theme Permissions (NIXI-specific)
      # Purpose: Set proper permissions for Glow theme files
      # Action:  Make theme files accessible to system
      # ===================================================================
      # Glow theme permissions are now handled by the theme modules

      # ===================================================================
      # Xcode Configuration
      # Purpose: Set up Xcode command line tools
      # Action:  Configure xcode-select and accept license
      # ===================================================================

      echo "Setting Xcode for xcode-select..."
      sudo xcode-select -s /Applications/Xcode.app
      sudo xcodebuild -license accept
      xcodebuild -runFirstLaunch
    '';
  };
}
