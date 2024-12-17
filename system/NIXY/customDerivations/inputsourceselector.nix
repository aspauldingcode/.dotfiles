{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "InputSourceSelector";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "minoki";
    repo = "InputSourceSelector";
    rev = "master"; # Using master branch since no specific version tag exists
    hash = "sha256-PR7g1Q9G1H39fYXcVWbqSm0A0lJWAqYfU5OXJstLS+4=";
  };

  buildInputs = [
    pkgs.darwin.apple_sdk.frameworks.Carbon
    pkgs.darwin.apple_sdk.frameworks.Foundation
  ];

  nativeBuildInputs = [
    pkgs.darwin.apple_sdk.frameworks.CoreServices
  ];

  NIX_CFLAGS_COMPILE = "-I${pkgs.darwin.apple_sdk.frameworks.Carbon}/Library/Frameworks/Carbon.framework/Headers";

  buildPhase = ''
    $CC -o InputSourceSelector -Wall InputSourceSelector.m \
      -framework Carbon \
      -framework Foundation \
      -framework CoreServices
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp InputSourceSelector $out/bin/
  '';

  meta = {
    description = "A macOS command-line utility to select input source";
    homepage = "https://github.com/minoki/InputSourceSelector";
    license = pkgs.lib.licenses.mit;
    platforms = pkgs.lib.platforms.darwin;
  };
}
