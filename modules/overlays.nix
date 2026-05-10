{ config, lib, ... }:

{
  flake.overlays.default = final: prev: {
    beeper = if prev.stdenv.isDarwin then 
      let
        pname = "beeper";
        version = "4.2.770";
        
        src = if prev.stdenv.hostPlatform.system == "aarch64-darwin" then
          prev.fetchurl {
            url = "https://beeper-desktop.download.beeper.com/builds/Beeper-${version}-arm64-mac.zip";
            hash = "sha256-zQPhAp0H3/NN2Ccr85qEbK+4sFG5iCMWJx0TcAfqpXQ=";
          }
        else if prev.stdenv.hostPlatform.system == "x86_64-darwin" then
          prev.fetchurl {
            url = "https://beeper-desktop.download.beeper.com/builds/Beeper-${version}-mac.zip";
            hash = "sha256-BVkOWiccjckJOw2ZyW4KIUWMLFEaGJEMmOSysTl3K38=";
          }
        else throw "Unsupported macOS architecture for Beeper";
        
      in prev.stdenvNoCC.mkDerivation {
        inherit pname version src;
        
        nativeBuildInputs = [ prev.unzip prev.makeWrapper ];
        
        sourceRoot = ".";
        
        installPhase = ''
          runHook preInstall
          
          mkdir -p $out/Applications
          cp -r "Beeper Desktop.app" $out/Applications/
          
          mkdir -p $out/bin
          makeWrapper "$out/Applications/Beeper Desktop.app/Contents/MacOS/Beeper Desktop" $out/bin/beeper
          
          runHook postInstall
        '';

        meta = prev.beeper.meta // {
          platforms = prev.lib.platforms.linux ++ prev.lib.platforms.darwin;
        };
      }
    else 
      prev.beeper; # use original on linux

    # ── Wallpaper Tools ──────────────────────────────────────────
    # Sindre Sorhus's wallpaper CLI for macOS (compiled from upstream)
    macos-wallpaper = if prev.stdenv.isDarwin then 
      let
        # We manually provide the dependency resolution to bypass network limitations
        # and we use only swift-argument-parser because we patch out SQLite.
        generated = prev.swiftpm2nix.helpers ./macos-wallpaper-deps;
      in
      prev.stdenv.mkDerivation rec {
        pname = "macos-wallpaper";
        version = "2.3.4";
        
        src = prev.fetchFromGitHub {
          owner = "sindresorhus";
          repo = "macos-wallpaper";
          rev = "v${version}";
          hash = "sha256-n4+NdfphU3Z4Gt9Cjv/wNgdnQbEjTJixicPTqTKIuMQ=";
        };
        
        nativeBuildInputs = [ prev.swift prev.swiftpm ];
        buildInputs = [ prev.apple-sdk ];
        
        postPatch = ''
          # Patch Package.swift to remove SQLite and set swift-tools-version to 5.10
          cat > Package.swift <<'EOF'
// swift-tools-version:5.10
import PackageDescription

let package = Package(
	name: "Wallpaper",
	platforms: [
		.macOS(.v10_13)
	],
	products: [
		.executable(
			name: "wallpaper",
			targets: ["WallpaperCLI"]
		),
		.library(
			name: "Wallpaper",
			targets: ["Wallpaper"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
	],
	targets: [
		.executableTarget(
			name: "WallpaperCLI",
			dependencies: [
				"Wallpaper",
				.product(name: "ArgumentParser", package: "swift-argument-parser")
			]
		),
		.target(
			name: "Wallpaper",
			dependencies: []
		)
	]
)
EOF
          sed -i '/import SQLite/d' Sources/wallpaper/Wallpaper.swift
          sed -i '/typealias Expression/d' Sources/wallpaper/Wallpaper.swift
          sed -i '/private static func getFromDirectory/,/^\t}/c\
\tprivate static func getFromDirectory(_ url: URL) throws -> URL {\n\t\treturn url\n\t}' Sources/wallpaper/Wallpaper.swift
          sed -i 's/@retroactive //g' Sources/WallpaperCLI/Utilities.swift || true
          sed -i 's/@retroactive //g' Sources/WallpaperCLI/Wallpaper.swift || true
        '';
        
        configurePhase = generated.configure;
        
        buildPhase = ''
          export HOME=$TMPDIR
          swift build --configuration release
        '';
        
        installPhase = ''
          binPath="$(swiftpmBinPath)"
          mkdir -p $out/bin
          cp $binPath/wallpaper $out/bin/
        '';
      }
    else null;
  };
}
