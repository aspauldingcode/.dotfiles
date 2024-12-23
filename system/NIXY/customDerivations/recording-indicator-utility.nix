{ lib, stdenv, fetchurl, unzip, ... }:

stdenv.mkDerivation {
  pname = "RecordingIndicatorUtility";
  version = "2.0";

  src = fetchurl {
    url = "https://github.com/cormiertyshawn895/RecordingIndicatorUtility/releases/download/2.0/RecordingIndicatorUtility.2.0.zip";
    sha256 = "sha256-KqYsgloj+fNqNtN7WYR6O0j8PahSnOcoo6AdNTiEt0U=";
  };

  nativeBuildInputs = [ unzip ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/Applications"
    unzip "$src" -d "$out/temp"
    cp -r "$out/temp/Recording Indicator Utility 2.0/Recording Indicator Utility.app" "$out/Applications/"
    rm -rf "$out/temp"
  '';

  meta = with lib; {
    description = "Tool for managing recording indicators on macOS";
    license = licenses.mit;
    platforms = platforms.darwin;
    homepage = "https://github.com/cormiertyshawn895/RecordingIndicatorUtility";
  };
}
