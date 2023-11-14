{ lib
, qtbase
, qtsvg
, qtgraphicaleffects
, qtquickcontrols2
, wrapQtAppsHook
, stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation
rec {
  pname = "tokyo-night-sddm";
  version = "1..0";
  dontBuild = true;
  src = fetchFromGitHub {
    owner = "rototrash";
    repo = "tokyo-night-sddm";
    rev = "320c8e74ade1e94f640708eee0b9a75a395697c6";
    sha256 = "sha256-JRVVzyefqR2L3UrEK2iWyhUKfPMUNUnfRZmwdz05wL0=";
  };
  nativeBuildInputs = [
    wrapQtAppsHook
  ];

  propagatedUserEnvPkgs = [
    qtbase
    qtsvg
    qtgraphicaleffects
    qtquickcontrols2
  ];


  installPhase = ''
    mkdir -p $out/share/sddm/themes
    cp -aR $src $out/share/sddm/themes/tokyo-night-sddm
  '';

}

#
#
# { stdenv, fetchFromGitHub }:
#
# {
#   stdenv.mkDerivation rec {
#     pname = "sddm-theme-dialog";
#     version = "53f81e3";
#     dontBuild = true;
#     installPhase = ''
#       mkdir -p $out/share/sddm/themes
#       cp -aR $src $out/share/sddm/themes/sddm-theme-dialog
#     '';
#     src = fetchFromGitHub {
#       owner = "joshuakraemer";
#       repo = "sddm-theme-dialog";
#       rev = "53f81e322f715d3f8e3f41c38eb3774b1be4c19b";
#       sha256 = "qoLSRnQOvH3rAH+G1eRrcf9ZB6WlSRIZjYZBOTkew/0=";
#     };
#   };
# }
