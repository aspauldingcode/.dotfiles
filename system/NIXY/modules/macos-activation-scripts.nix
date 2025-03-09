{
  config,
  lib,
  pkgs,
  inputs,
  user,
  ...
}:

let
  InputSourceSelector = pkgs.callPackage ../customDerivations/inputsourceselector.nix { };
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
      ./../../../users/alex/extraConfig/wallpapers/nix-colors-wallpaper-darwin.png
    else
      ./../../../users/alex/extraConfig/wallpapers/nix-colors-wallpaper.png;
  wallpaper_output = "/Users/Shared/Wallpaper/wallpaper-nix-colors.png";
  wallpaper_recolor_script = ./../../../users/alex/extraConfig/recolor_base16_inputs_efficient.py;
  m = "${pkgs.m-cli}/bin/m";
  orb = "${homebrewPath}/orb";
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
      "${pkgs.spotify}/Applications/Spotify.app/Contents/MacOS/Spotify"
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
    echo "USER: alex"
    sudo -u "alex" ${InputSourceSelector}/bin/InputSourceSelector list-enabled

    echo -e "\033[33m\n=== Enabling Unicode Hex Input ===\033[0m"
    sudo -u "alex" ${InputSourceSelector}/bin/InputSourceSelector enable "com.apple.keylayout.UnicodeHexInput"

    echo -e "\033[33m\n=== Disabling all other input sources ===\033[0m"
    # Get all enabled input sources and disable them except Unicode Hex Input
    sudo -u "alex" ${InputSourceSelector}/bin/InputSourceSelector list-enabled | while read -r line; do
        input_id=$(echo "$line" | cut -d" " -f1)
        if [ "$input_id" != "com.apple.keylayout.UnicodeHexInput" ]; then
            echo -e "\033[33mDisabling: $line\033[0m"
            sudo -u "alex" ${InputSourceSelector}/bin/InputSourceSelector disable "$input_id"
        fi
    done

    echo -e "\033[33m\n=== Final enabled input sources ===\033[0m"
    sudo -u "alex" ${InputSourceSelector}/bin/InputSourceSelector list-enabled

    # ===================================================================
    # Java Development Kit Symlink
    # Purpose: Configure system-wide JDK access
    # Action:  Create symlink to JDK in standard macOS Java location
    # ===================================================================

    # symlink (zulu) jdk23 to /Library/Java/JavaVirtualMachines/ # NEEDED for macOS!!
    ln -sf "${inputs.nixpkgs.legacyPackages.aarch64-darwin.jdk23}/zulu-23.jdk" "/Library/Java/JavaVirtualMachines/"

    # ===================================================================
    # macOS Wallpaper Configuration
    # Purpose: Set system wallpaper with custom recoloring
    # Action:  Recolor and apply wallpaper based on color scheme
    # ===================================================================

    # create the wallpaper directory if it doesn't exist
    mkdir -p /Users/Shared/Wallpaper/

    echo "Recoloring Wallpapers to ${config.colorscheme.slug} color scheme..."
    ${
      pkgs.python3.withPackages (ps: [
        ps.pillow
        ps.numpy
        ps.tqdm
      ])
    }/bin/python3 ${wallpaper_recolor_script} ${wallpaper_input} ${wallpaper_output} ${config.colorScheme.variant} "#${palette.base00},#${palette.base01},#${palette.base02},#${palette.base03},#${palette.base04},#${palette.base05},#${palette.base06},#${palette.base07},#${palette.base08},#${palette.base09},#${palette.base0A},#${palette.base0B},#${palette.base0C},#${palette.base0D},#${palette.base0E},#${palette.base0F}"

    echo "Setting ${config.colorscheme.variant} wallpaper..."
    ${m} wallpaper "${wallpaper_output}"

    # ===================================================================
    # macOS Dark/Light Mode Configuration
    # Purpose: Set system appearance mode based on color scheme
    # Action:  Toggle between dark and light mode
    # ===================================================================

    echo "Setting ${config.colorscheme.variant}mode for the system..."
    toggle-darkmode ${config.colorscheme.variant}

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
    sudo dscl . create /Users/${user} Picture "${./../../../users/alex/face.heic}"
  '';
}
