{ pkgs }:

let
  # Wawona fork (vphone + Mode B tipa). Rebuild local tree first:
  #   cd ~/Wawona/agent-device && nix shell nixpkgs#pnpm -c pnpm build
  version = "0.18.3-wawona.1";
  srcRoot = /Users/8amps/Wawona/agent-device;

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

  # Local checkout with prebuilt dist/ (rslib). Avoid shipping node_modules.
  src = pkgs.lib.cleanSourceWith {
    src = srcRoot;
    filter =
      path: type:
      let
        base = baseNameOf path;
      in
      !(
        base == "node_modules"
        || base == ".git"
        || base == ".tmp"
        || base == "coverage"
        || base == "test"
      );
  };

  nativeBuildInputs = [ pkgs.makeWrapper ];
  buildInputs = [ pkgs.nodejs_24 ];

  # Fail closed if the fork was not built.
  preConfigure = ''
    test -f dist/src/cli.js || {
      echo "agent-device dist/ missing. Run: cd ${toString srcRoot} && nix shell nixpkgs#pnpm -c pnpm build" >&2
      exit 1
    }
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/agent-device" "$out/bin"
    cp -R dist bin package.json server.json "$out/lib/agent-device/" 2>/dev/null || \
      cp -R dist bin package.json "$out/lib/agent-device/"

    mkdir -p "$out/lib/agent-device/node_modules"
    ln -s ${yamlNpm}/lib/node_modules/yaml "$out/lib/agent-device/node_modules/yaml"

    makeWrapper ${pkgs.nodejs_24}/bin/node "$out/bin/agent-device" \
      --add-flags "$out/lib/agent-device/bin/agent-device.mjs" \
      --prefix NODE_PATH : "$out/lib/agent-device/node_modules" \
      --prefix PATH : "${pkgs.lib.makeBinPath [ pkgs.sshpass ]}" \
      --set-default WAWONA_ROOT /Users/8amps/Wawona/Wawona

    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Wawona fork of agent-device with vphone (jailbroken research VM) automation";
    homepage = "https://github.com/Wawona/agent-device";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "agent-device";
  };
}
