{
  lib,
  stdenv,
  swift,
  swiftpm,
  apple-sdk,
  src,
  generated,
}:

let
  # Path flakes can still leak a local Swift 6 `.build/` into the sandbox.
  cleanSrc = lib.cleanSourceWith {
    src = lib.cleanSource src;
    filter =
      path: _type:
      let
        p = toString path;
      in
      !(lib.hasInfix "/.build" p) && !(lib.hasInfix "/.swiftpm" p);
  };
in
stdenv.mkDerivation {
  pname = "macos-wallpaper-daemon-rse";
  version = "0.2.0";
  src = cleanSrc;

  nativeBuildInputs = [
    swift
    swiftpm
  ];
  buildInputs = [ apple-sdk ];

  # Vendored by `swiftpm2nix` after `swift package resolve` (Swift 5.10).
  configurePhase = generated.configure;

  preBuild = ''
    export HOME=$TMPDIR
  '';

  doCheck = false;
  dontUseSwiftpmCheck = true;

  installPhase = ''
    runHook preInstall
    binPath="$(swiftpmBinPath)"
    mkdir -p $out/bin $out/lib $out/include
    cp -L "$binPath/libWallpaperKit.dylib" $out/lib/libWallpaperKit.dylib
    cp -L "$binPath/macos-wallpaperd" $out/bin/macos-wallpaperd
    chmod +x $out/bin/macos-wallpaperd
    cp include/wallpaperkit.h $out/include/
    runHook postInstall
  '';

  meta = {
    description = "Native macOS wallpaper apply (all Spaces + Your Photos catalog)";
    homepage = "https://github.com/aspauldingcode/macos-wallpaper-daemon-rse";
    platforms = lib.platforms.darwin;
    mainProgram = "macos-wallpaperd";
  };
}
