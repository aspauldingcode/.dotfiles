{ pkgs }:

let
  version = "0.18.3";

  yamlNpm = pkgs.stdenvNoCC.mkDerivation {
    pname = "yaml-npm";
    version = "2.9.0";
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/yaml/-/yaml-2.9.0.tgz";
      hash = "sha256-AI+iBMsbpwDgJyugRau/Cab/5jRW6BRrqXysbCrR75E=";
    };
    sourceRoot = "package";
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/node_modules/yaml"
      cp -r . "$out/lib/node_modules/yaml/"
      runHook postInstall
    '';
  };
in
pkgs.stdenvNoCC.mkDerivation {
  inherit version;
  pname = "agent-device";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/agent-device/-/agent-device-${version}.tgz";
    hash = "sha256-AWi9g9ax8+0JA9GWhr4aSxaVsLuuVVKV5fD82aqB5AU=";
  };

  nativeBuildInputs = [ pkgs.makeWrapper ];
  buildInputs = [ pkgs.nodejs_24 ];

  sourceRoot = "package";

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/agent-device" "$out/bin"
    cp -r . "$out/lib/agent-device/"

    mkdir -p "$out/lib/agent-device/node_modules"
    ln -s ${yamlNpm}/lib/node_modules/yaml "$out/lib/agent-device/node_modules/yaml"

    makeWrapper ${pkgs.nodejs_24}/bin/node "$out/bin/agent-device" \
      --add-flags "$out/lib/agent-device/bin/agent-device.mjs" \
      --prefix NODE_PATH : "$out/lib/agent-device/node_modules"

    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Agent-native CLI for AI app automation across iOS, Android, tvOS, macOS, and web";
    homepage = "https://github.com/callstack/agent-device";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "agent-device";
  };
}
