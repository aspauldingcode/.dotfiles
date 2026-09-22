{ pkgs }:

# Wawona agent-device fork (vphone). Flake pure eval cannot `src = /Users/...`,
# so wrap the local checkout at runtime. Rebuild after pulls:
#   cd ~/Wawona/agent-device && nix shell nixpkgs#pnpm -c pnpm build
let
  version = "0.18.3-wawona.1";
  # String path (not a Nix path type) so flakes stay pure; resolved when the wrapper runs.
  localCheckout = "/Users/8amps/Wawona/agent-device";
  wawonaRoot = "/Users/8amps/Wawona/Wawona";
in
pkgs.writeShellApplication {
  name = "agent-device";
  runtimeInputs = [
    pkgs.nodejs_24
    pkgs.sshpass
    pkgs.openssh
  ];
  text = ''
    set -euo pipefail
    ROOT="${localCheckout}"
    if [[ ! -f "$ROOT/bin/agent-device.mjs" ]]; then
      echo "agent-device fork missing at $ROOT" >&2
      exit 1
    fi
    if [[ ! -f "$ROOT/dist/src/cli.js" ]]; then
      echo "agent-device dist/ missing. Run: cd $ROOT && nix shell nixpkgs#pnpm -c pnpm build" >&2
      exit 1
    fi
    export WAWONA_ROOT="''${WAWONA_ROOT:-${wawonaRoot}}"
    export SSH_ASKPASS_REQUIRE="''${SSH_ASKPASS_REQUIRE:-never}"
    unset SSH_ASKPASS DISPLAY || true
    exec node "$ROOT/bin/agent-device.mjs" "$@"
  '';

  meta = with pkgs.lib; {
    description = "Wawona fork of agent-device with vphone (jailbroken research VM) automation";
    homepage = "https://github.com/Wawona/agent-device";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "agent-device";
    # Carry version for nix-info / readers.
    inherit version;
  };
}
