{pkgs}:
pkgs.stdenv.mkDerivation {
  name = "InputSourceSelector";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "minoki";
    repo = "InputSourceSelector";
    rev = "master"; # Using master branch since no specific version tag exists
    hash = "sha256-TD9RksjyUrUNufmH+rMTlS1HrOf6alLMVNRcEe9aGIg=";
  };

  buildInputs = [
    pkgs.apple-sdk_11
  ];

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
