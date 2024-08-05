{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "cDock";
  src = pkgs.fetchzip {
    name = "cDock";
    url = "https://github.com/jslegendre/appcast/archive/c594417/MacForge-1.2.2-3.zip";
    sha256 = "sha256-m2EsqOi1mWo8FctW1Ri/981Ry4noh23lJX0W4VQ+lOc=";
  };

  dontUnpack = false;
  dontConfigure = true;
  dontBuild = true;

  installPhase =
    let
      unzip = "/usr/bin/unzip";
    in
    ''
      mkdir -p $out/Applications
      ${unzip} "$src"/'Beta/cDock/cDock.5.3.3.zip' -d $out/temp
      cp -r "$out/temp"/'cDock.app' $out/Applications/
    '';
}