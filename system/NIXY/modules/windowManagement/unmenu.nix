{
  config,
  lib,
  pkgs,
  std,
  ...
}:

let
  unmenu = pkgs.stdenv.mkDerivation rec {
    pname = "unmenu";
    version = "0.2";

    src = pkgs.fetchurl {
      url = "https://github.com/unmanbearpig/unmenu/releases/download/v${version}/unmenu.app.zip";
      sha256 = "sha256-c4fe1g9XBTXR6KtJn5njy28q4SyUM/r5hGV3Nd1ztdY=";
    };

    nativeBuildInputs = [ pkgs.unzip ];

    installPhase = ''
      mkdir -p $out/Applications
      unzip -q $src -d $out/Applications
      mkdir -p $out/bin
      ln -s $out/Applications/unmenu.app/Contents/MacOS/unmenu $out/bin/unmenu
    '';

    meta = with lib; {
      description = "A macOS app for quick application launching, forked from dmenu-mac";
      longDescription = ''
        unmenu is a fork of dmenu-mac, enhancing its functionality and addressing certain issues.
        It uses the Accessibility API for handling hotkeys and implements a superior fuzzy matching algorithm.
        Users can customize search directories, filter out applications, and integrate scripts and aliases.
      '';
      homepage = "https://github.com/unmanbearpig/unmenu";
      platforms = platforms.darwin;
      license = licenses.mit;
      maintainers = with maintainers; [ unmanbearpig ];
    };
  };
in
{
  options.programs.unmenu = {
    enable = lib.mkEnableOption "unmenu";
  };
}
