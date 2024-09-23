{ config, lib, pkgs, std, ... }:

let
  cfg = config.programs.unmenu;

  unmenuSrc = pkgs.fetchFromGitHub {
    owner = "unmanbearpig";
    repo = "unmenu";
    rev = "master";
    sha256 = "sha256-bjXSeeBEmoZWQOyPWFvKJ5LFeLdx8KHqMixZD6ieX8M=";
  };

  fuzzylib = pkgs.rustPlatform.buildRustPackage {
    pname = "fuzzylib";
    version = "0.2.0";
    src = "${unmenuSrc}/fuzzylib";
    cargoLock = {
      lockFile = "${unmenuSrc}/fuzzylib/Cargo.lock";
    };

    nativeBuildInputs = [
      pkgs.darwin.cctools
      pkgs.darwin.apple_sdk.frameworks.CoreServices
    ];

    buildInputs = [
      pkgs.darwin.apple_sdk.frameworks.AppKit
      pkgs.darwin.apple_sdk.frameworks.Foundation
      pkgs.cc-tool
      pkgs.cargo
    ];

    buildPhase = ''
      export MACOSX_DEPLOYMENT_TARGET=11.0
      export NIX_CFLAGS_COMPILE="-isystem ${pkgs.darwin.apple_sdk.frameworks.AppKit}/Library/Frameworks/AppKit.framework/Headers -isystem ${pkgs.darwin.apple_sdk.frameworks.CoreServices}/Library/Frameworks/CoreServices.framework/Headers"
      # export SDKROOT="${pkgs.darwin.apple_sdk.goddammitsdk}"
      cargo build --release
    '';

    RUST_BACKTRACE = "full";
    CARGO_PROFILE_RELEASE_BUILD_OVERRIDE_DEBUG = "true";

    buildNoDefaultFeatures = true;
    buildFeatures = ["nix-build"];
  };

  unmenu = pkgs.stdenv.mkDerivation {
    pname = "unmenu";
    version = "0.2.0";

    src = unmenuSrc;

    nativeBuildInputs = [
      pkgs.xcbuild
    ];

    buildInputs = [
      pkgs.darwin.apple_sdk.frameworks.Cocoa
      fuzzylib
    ];

    buildPhase = ''
      cd mac-app
      xcodebuild -scheme unmenu -configuration Release
    '';

    installPhase = ''
      mkdir -p $out/Applications
      cp -r build/Release/unmenu.app $out/Applications/
    '';

    meta = with lib; {
      description = "A simple application launcher for macOS";
      homepage = "https://github.com/unmanbearpig/unmenu";
      license = licenses.mit;
      platforms = platforms.darwin;
    };
  };
in
{
  options.programs.unmenu = {
    enable = lib.mkEnableOption "unmenu";

    package = lib.mkOption {
      type = lib.types.package;
      default = unmenu;
      description = "The unmenu package to use";
    };

    qwertyHotkey = lib.mkOption {
      type = lib.types.str;
      default = "ctrl-cmd-space";
      description = "The hotkey to activate unmenu";
    };

    findApps = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to find and include applications";
    };

    findExecutables = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to find and include executables";
    };

    dirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/System/Applications/"
        "/Applications/"
        "/System/Applications/Utilities/"
        "/System/Library/CoreServices/"
        "~/.unmenu-bin"
      ];
      description = "Directories to search for applications and executables";
    };

    ignoreNames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "unmenu.app"
        ".Karabiner-VirtualHIDDevice-Manager.app"
        # Add additional application names to ignore as needed
      ];
      description = "List of application names to ignore";
    };

    ignorePatterns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "^Install.*"
        ".*Installer\\.app$"
        "\\.bundle$"
      ];
      description = "List of patterns to ignore when searching for applications";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    environment.etc."unmenu/config.toml".text = std.serde.toTOML {
      hotkey.qwerty_hotkey = cfg.qwertyHotkey;
      find_apps = cfg.findApps;
      find_executables = cfg.findExecutables;
      dirs = cfg.dirs;
      ignore_names = cfg.ignoreNames;
      ignore_patterns = cfg.ignorePatterns;
    };
  };
}