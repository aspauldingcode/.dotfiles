{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "Mousecape";
  src = pkgs.fetchurl {
    url = "https://github.com/alexzielenski/Mousecape/releases/download/1813/Mousecape_1813.zip";
    sha256 = "sha256-lp7HFGr1J+iQCUWVDplF8rFcTrGf+DX4baYzLsUi/9I=";
  };

  buildInputs = [ pkgs.unzip ];

  unpackPhase = ''
    unzip $src -d $out
    mkdir -p $out/Applications
    cp -r $out/Mousecape.app $out/Applications/
  '';
  dontConfigure = true;
  dontBuild = true;

  installPhase =
    ''
      mkdir -p $out/Applications
      cp -r $out/Mousecape.app $out/Applications/
    '';
}