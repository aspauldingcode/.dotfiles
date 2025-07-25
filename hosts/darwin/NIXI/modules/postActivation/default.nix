{
  config,
  pkgs,
  inputs,
  user,
  ...
}:
let
  InputSourceSelector = pkgs.callPackage ../../customDerivations/inputsourceselector.nix { };
  systemType = pkgs.stdenv.hostPlatform.system;
  homebrewPath =
    if systemType == "aarch64-darwin" then
      "/opt/homebrew/bin"
    else if systemType == "x86_64-darwin" then
      "/usr/local/bin"
    else
      throw "Homebrew Unsupported architecture: ${systemType}";
  inherit (config.colorScheme) palette;
  wallpaper_input =
    if pkgs.stdenv.isDarwin then
      ./../../../../../users/${user}/extraConfig/wallpapers/nix-colors-wallpaper-darwin.png
    else
      ./../../../../../users/${user}/extraConfig/wallpapers/nix-colors-wallpaper.png;
  wallpaper_output =
    if pkgs.stdenv.isDarwin then
      "/var/root/Pictures/gowall/nix-colors-wallpaper-darwin.png"
    else
      "/var/root/Pictures/gowall/nix-colors-wallpaper.png";
  gowall = "${pkgs.unstable.gowall}/bin/gowall";
in
{
  system.activationScripts.postActivation.text = ''

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
    sudo -u "${user}" ${InputSourceSelector}/bin/InputSourceSelector list-enabled

    echo -e "\033[33m\n=== Enabling Unicode Hex Input ===\033[0m"
    sudo -u "${user}" ${InputSourceSelector}/bin/InputSourceSelector enable "com.apple.keylayout.UnicodeHexInput"

    echo -e "\033[33m\n=== Disabling all other input sources ===\033[0m"
    # Get all enabled input sources and disable them except Unicode Hex Input
    sudo -u "${user}" ${InputSourceSelector}/bin/InputSourceSelector list-enabled | while read -r line; do
        input_id=$(echo "$line" | cut -d" " -f1)
        if [ "$input_id" != "com.apple.keylayout.UnicodeHexInput" ]; then
            echo -e "\033[33mDisabling: $line\033[0m"
            sudo -u "${user}" ${InputSourceSelector}/bin/InputSourceSelector disable "$input_id"
        fi
    done

    echo -e "\033[33m\n=== Final enabled input sources ===\033[0m"
    sudo -u "${user}" ${InputSourceSelector}/bin/InputSourceSelector list-enabled

    # ===================================================================
    # Java Development Kit Symlink
    # Purpose: Configure system-wide JDK access
    # Action:  Create symlink to JDK in standard macOS Java location
    # ===================================================================

    # symlink (zulu) jdk23 to /Library/Java/JavaVirtualMachines/ # NEEDED for macOS!!
    ln -sf "${inputs.nixpkgs.legacyPackages.${systemType}.jdk23}/zulu-23.jdk" "/Library/Java/JavaVirtualMachines/"

    # ===================================================================
    # macOS Wallpaper Configuration
    # Purpose: Set system wallpaper with custom recoloring
    # Action:  Recolor and apply wallpaper based on color scheme
    # ===================================================================

    # create the wallpaper directory if it doesn't exist
    # mkdir -p /Users/Shared/Wallpaper/

    # echo "Recoloring Wallpapers to ''${config.colorScheme.slug} color scheme..."
     # ''${gowall} convert ''${wallpaper_input} -t /etc/gowall/theme.json

     # echo "Setting ''${config.colorScheme.variant} wallpaper..."
     # wallpaper "''${wallpaper_output}"

    # ===================================================================
    # macOS Dark/Light Mode Configuration
    # Purpose: Set system appearance mode based on color scheme
    # Action:  Toggle between dark and light mode
    # ===================================================================

    echo "Setting ${config.colorScheme.variant}mode for the system..."
    # toggle-darkmode ${config.colorScheme.variant}

    # ===================================================================
    # System Boot Arguments Configuration
    # Purpose: Enable preview ABI for yabai scripting and other tools
    # Action:  Set nvram boot arguments for arm64e preview ABI support
    # ===================================================================

    echo "Setting nvram boot-args preview abi for yabai scripting addition and glow/ammonia..."
    sudo nvram boot-args=-arm64e_preview_abi

    echo "Setting profile picture..."
    sudo dscl . delete /Users/${user} jpegphoto
    sudo dscl . delete /Users/${user} Picture
    sudo dscl . create /Users/${user} Picture "${./../../../../../users/${user}/face.heic}"

    echo "Setting permissions for ${config.colorScheme.slug}-${config.colorScheme.variant} Glow Theme..."
    sudo chmod -R 777 /Library/GlowThemes/${config.colorScheme.slug}-${config.colorScheme.variant}/
    sudo chmod -R 777 /Library/GlowThemes/${config.colorScheme.slug}-${config.colorScheme.variant}/settings.plist

    echo "Setting Xcode for xcode-select..."
    sudo xcode-select -s /Applications/Xcode.app
    sudo xcodebuild -license accept
    xcodebuild -runFirstLaunch
  '';
}
