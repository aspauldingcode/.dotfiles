
{ stdenv, fetchFromGitHub }:
{
  stdenv.mkDerivation rec {
    pname = "sddm-theme-dialog";
    version = "53f81e3";
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/sddm/themes
      cp -aR $src $out/share/sddm/themes/sddm-theme-dialog
    '';
    src = fetchFromGitHub {
      owner = "joshuakraemer";
      repo = "sddm-theme-dialog";
      rev = "53f81e322f715d3f8e3f41c38eb3774b1be4c19b";
      sha256 = "qoLSRnQOvH3rAH+G1eRrcf9ZB6WlSRIZjYZBOTkew/0=";
    };
  };
}


