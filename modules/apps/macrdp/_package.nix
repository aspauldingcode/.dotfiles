{
  lib,
  stdenvNoCC,
}:

# Prebuilt aarch64-darwin binary from `cargo build --release -p macrdp-server`
# (x6nux/macrdp @ 6be70bb). Source builds need Xcode `swift` for screencapturekit
# and fail inside nix builders even with sandbox=false.
#
# Rebuild: see modules/apps/macrdp/README.md
stdenvNoCC.mkDerivation {
  pname = "macrdp-server";
  version = "0.1.0-prebuilt-6be70bb";

  src = ./macrdp-server;

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 $src $out/bin/macrdp-server
    runHook postInstall
  '';

  meta = {
    description = "Native macOS RDP server (macrdp) — prebuilt";
    homepage = "https://github.com/x6nux/macrdp";
    license = lib.licenses.gpl3Only;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "macrdp-server";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
