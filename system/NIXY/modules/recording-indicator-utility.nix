{ pkgs, lib, ... }:

let
  recordingIndicatorUtility = pkgs.stdenv.mkDerivation {
    pname = "RecordingIndicatorUtility";
    version = "2.0";  # Version directly specified here

    src = pkgs.fetchurl {
      url = "https://github.com/cormiertyshawn895/RecordingIndicatorUtility/releases/download/2.0/RecordingIndicatorUtility.2.0.zip";  # Direct version in the URL
      sha256 = "sha256-KqYsgloj+fNqNtN7WYR6O0j8PahSnOcoo6AdNTiEt0U=";  # Replace with the actual SHA256 hash
    };

    nativeBuildInputs = [ pkgs.unzip ];

    installPhase = ''
      mkdir -p $out/Applications
      unzip $src -d $out/Applications
    '';

    meta = with lib; {
      description = "Tool for managing recording indicators on macOS";
      license = lib.licenses.mit;
      platforms = lib.platforms.darwin;
      homepage = "https://github.com/cormiertyshawn895/RecordingIndicatorUtility";
    };
  };
in
{
  environment.systemPackages = [ recordingIndicatorUtility ];
}

# add defaults config
/*
# First, search for the domain
defaults domains | tr ',' '\n' | grep -i "recordingindicatorutility"

# Then, read the specific domain
defaults read  com.mac.RecordingIndicatorUtility

# Example output
{
    AcknowledgedSystemOverrideAlert = 1;
}

*/