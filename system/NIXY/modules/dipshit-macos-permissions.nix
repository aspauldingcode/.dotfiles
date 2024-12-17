{ config, lib, pkgs, ... }:

# this doesn't even work. tf man.
let
  InputSourceSelector = pkgs.callPackage ../customDerivations/inputsourceselector.nix {};
in
{
  system.activationScripts.postActivation.text = ''
    # Fix binary quarantine attributes
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
    # Get the actual logged in user
    REAL_USER=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')
    echo -e "\033[33m=== Current enabled input sources ===\033[0m"
    echo "USER: $REAL_USER"
    sudo -u "$REAL_USER" ${InputSourceSelector}/bin/InputSourceSelector list-enabled

    echo -e "\033[33m\n=== Enabling Unicode Hex Input ===\033[0m"
    sudo -u "$REAL_USER" ${InputSourceSelector}/bin/InputSourceSelector enable "com.apple.keylayout.UnicodeHexInput"

    echo -e "\033[33m\n=== Disabling all other input sources ===\033[0m"
    # Get all enabled input sources and disable them except Unicode Hex Input
    sudo -u "$REAL_USER" ${InputSourceSelector}/bin/InputSourceSelector list-enabled | while read -r line; do
        input_id=$(echo "$line" | cut -d" " -f1)
        if [ "$input_id" != "com.apple.keylayout.UnicodeHexInput" ]; then
            echo -e "\033[33mDisabling: $line\033[0m"
            sudo -u "$REAL_USER" ${InputSourceSelector}/bin/InputSourceSelector disable "$input_id"
        fi
    done

    echo -e "\033[33m\n=== Final enabled input sources ===\033[0m"
    sudo -u "$USER" ${InputSourceSelector}/bin/InputSourceSelector list-enabled
  '';
}
