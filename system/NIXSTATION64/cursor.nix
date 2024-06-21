{ pkgs, lib, ... }:

let
  pname = "cursor";
  version = "0.35.0";
  name = "${pname}-${version}";

  src = pkgs.fetchurl {
    url = "https://downloader.cursor.sh/linux/appImage/x64";
    sha256 = "sha256-Fsy9OVP4vryLHNtcPJf0vQvCuu4NEPDTN2rgXO3Znwo=";
  };

  appimageContents = pkgs.appimageTools.extractType2 { inherit name src; };
in
pkgs.appimageTools.wrapType2 rec {
  inherit name src;

  extraInstallCommands = ''
    mv $out/bin/${name} $out/bin/${pname}
    install -m 444 -D ${appimageContents}/cursor.desktop $out/share/applications/${pname}.desktop

    install -m 444 -D ${appimageContents}/${pname}.png $out/share/icons/hicolor/512x512/apps/${pname}.png

    substituteInPlace $out/share/applications/${pname}.desktop \
    	--replace 'Exec=AppRun --no-sandbox %U' 'Exec=${pname} %U'
  '';

  meta = with lib; {
    description = "The AI Code Editor; built to make you extraordinarily productive, Cursor is the best way to code with AI.";
    homepage = "https://www.cursor.com/";
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
  };
}