{ pkgs }:

# Vercel CLI native binary from GitHub releases (not in nixpkgs).
# Underscore prefix: not a flake-parts module (imported by modules/apps/vercel.nix).
# Wrapper injects pass-backed VERCEL_TOKEN / auth.json.
let
  version = "56.3.2";
  system = pkgs.stdenv.hostPlatform.system;
  spec =
    {
      aarch64-darwin = {
        pname = "vercel-darwin-arm64";
        hash = "sha256-1xjphYFzjlDsjI1RfegtD32mUknOAkBsxengEu64gIc=";
      };
      x86_64-darwin = {
        pname = "vercel-darwin-x64";
        hash = "sha256-Zx7CCehZ71C+rl/YVdCytwGC6cUcLm2jTL38f+LwNxI=";
      };
      aarch64-linux = {
        pname = "vercel-linux-arm64";
        hash = "sha256-l0XR0zuX2C2yOI49yoCabLCX6zPk5NmWewPTlzQSQV8=";
      };
      x86_64-linux = {
        pname = "vercel-linux-x64";
        hash = "sha256-FJM8aispoi72Je2enfDp2R7jUytdkNM6DaMcTx+KuiE=";
      };
    }
    .${system} or (throw "vercel: unsupported system ${system}");
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "vercel";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/vercel/vercel/releases/download/vercel%40${version}/${spec.pname}";
    inherit (spec) hash;
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    install -m755 "$src" "$out/bin/vercel"
    ln -s vercel "$out/bin/vc"
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Vercel CLI (native binary)";
    homepage = "https://vercel.com/docs/cli";
    license = licenses.asl20;
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
    mainProgram = "vercel";
  };
}
