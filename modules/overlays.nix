{
  inputs,
  ...
}:

{
  flake.overlays.default =
    final: prev:
    let
      unstable = import inputs.nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    in
    {
      code-cursor = unstable.code-cursor;
      antigravity = unstable.antigravity;
      spotify = unstable.spotify;
      vesktop = unstable.vesktop;
      firefox = unstable.firefox;

      # ── vimPlugins.blink-cmp: patch upstream "No fuzzy matching
      # library found!" false-positive on Nix ─────────────────────
      #
      # blink.cmp 1.8.0 (and current `main` as of 2026-05) ships a
      # `lua/blink/cmp/fuzzy/download/git.lua` whose `get_tag` and
      # `get_sha` functions are missing a `return` statement after
      # the early-exit `resolve()` call:
      #
      #   local repo_dir = vim.fs.root(files.root_dir, '.git')
      #   if not repo_dir then resolve() end   -- <- missing `return`
      #   vim.system({ ..., vim.fs.joinpath(repo_dir, '.git'), ... })
      #
      # On every other distribution the plugin lives somewhere
      # inside the user's `~/.config/nvim/lazy/...` tree, which is
      # almost always rooted under a `.git` somewhere up the chain,
      # so `vim.fs.root(...)` returns non-nil and the missing-return
      # is irrelevant. On Nix the plugin lives in
      # `/nix/store/...-vimplugin-blink.cmp/`, which has no `.git`
      # ancestor — `vim.fs.root(...)` returns nil, control falls
      # through to `vim.fs.joinpath(nil, '.git')`, that throws,
      # the async chain falls back to the Lua matcher despite the
      # perfectly-functional prebuilt Rust .dylib that nixpkgs
      # already symlinked into the plugin's `target/release/`. The
      # `[blink.cmp] No fuzzy matching library found! …` message
      # gets pushed onto `vim.api.nvim_echo`'s queue, drained on
      # the next `UIEnter` event, and surfaces on every interactive
      # nvim startup — a Nix-only false positive that no amount of
      # `fuzzy.implementation` / `prebuilt_binaries.download` knob
      # twiddling can suppress, because the warning fires inside
      # the success path's first `:map` BEFORE the implementation
      # config gets consulted.
      #
      # The fix is a 2-line `return` after each `resolve()`. We
      # apply it via `substituteInPlace` in `postPatch`; both
      # call sites have identical surrounding text so a single
      # `--replace-fail` invocation patches them both. If a future
      # upstream release fixes this itself, our `--replace-fail`
      # will hard-fail at build time and we'll know to drop this
      # override.
      vimPlugins = prev.vimPlugins // {
        blink-cmp = prev.vimPlugins.blink-cmp.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace lua/blink/cmp/fuzzy/download/git.lua \
              --replace-fail \
                'if not repo_dir then resolve() end' \
                'if not repo_dir then resolve(); return end'
          '';
        });
      };

      beeper =
        if prev.stdenv.isDarwin then
          let
            pname = "beeper";
            version = "4.2.770";

            src =
              if prev.stdenv.hostPlatform.system == "aarch64-darwin" then
                prev.fetchurl {
                  url = "https://beeper-desktop.download.beeper.com/builds/Beeper-${version}-arm64-mac.zip";
                  hash = "sha256-zQPhAp0H3/NN2Ccr85qEbK+4sFG5iCMWJx0TcAfqpXQ=";
                }
              else if prev.stdenv.hostPlatform.system == "x86_64-darwin" then
                prev.fetchurl {
                  url = "https://beeper-desktop.download.beeper.com/builds/Beeper-${version}-mac.zip";
                  hash = "sha256-BVkOWiccjckJOw2ZyW4KIUWMLFEaGJEMmOSysTl3K38=";
                }
              else
                throw "Unsupported macOS architecture for Beeper";
          in
          prev.stdenvNoCC.mkDerivation {
            inherit pname version src;

            nativeBuildInputs = [
              prev.unzip
              prev.makeWrapper
            ];

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
          unstable.beeper;

      # ── Wallpaper Tools ──────────────────────────────────────────
      # Sindre Sorhus's wallpaper CLI for macOS (compiled from upstream)
      macos-wallpaper =
        if prev.stdenv.isDarwin then
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

            nativeBuildInputs = [
              prev.swift
              prev.swiftpm
            ];
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
        else
          null;
    };
}
