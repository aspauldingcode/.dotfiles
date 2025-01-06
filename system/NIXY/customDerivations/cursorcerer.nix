{
  config,
  pkgs,
  stdenv,
  fetchurl,
  unzip,
}:

# installs cursorcerer.
stdenv.mkDerivation {
  pname = "cursorcerer";
  version = "3.5";

  src = fetchurl {
    url = "https://www.doomlaser.com/downloads/Cursorcerer.zip";
    sha256 = "sha256-JzlxiWAEX+AcVe1AyUiufmRjCx/fmzWwbHqB+UVWJJc="; # Replace with actual sha256 hash of the zip file
  };

  nativeBuildInputs = [ unzip ];

  unpackPhase = ''
    mkdir -p $out/temp
    unzip $src -d $out/temp
  '';

  installPhase = ''
    mkdir -p $out/
    cp -r $out/temp/Cursorcerer.prefPane $out/
    rm -r $out/temp/
  '';

  meta = {
    homepage = "https://doomlaser.com/cursorcerer-hide-your-cursor-at-will/";
    description = "A tool to hide the Mac's cursor at any time using a global hotkey, with features to autohide an idle cursor and reactivate it on movement.";
  };

  system.activationScripts = {
    extraActivation.text = ''
      # Fixes cursorcerer symlink!
      ln -sf "${pkgs.cursorcerer}/Library/PreferencePanes/Cursorcerer.prefPane" "/Library/PreferencePanes/Cursorcerer.prefPane"
    '';
  };
}
