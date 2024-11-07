{ config, lib, pkgs, ... }:

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
  '';
}
