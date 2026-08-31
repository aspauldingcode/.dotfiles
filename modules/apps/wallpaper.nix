# ── Dendritic Wallpaper (macOS + Linux, 1:1) ────────────────────────────
#
# Architecture:
#   1. Build-time pack: scenic light/dark wallpaper pairs + official base16
#      families (colors.toml + lutgen palette names). No flavours extraction.
#   2. Runtime: `dendritic-appearance wallpaper …` picks today's family + pair
#      from day-of-year, uses host appearance for light vs dark, copies
#      colors.toml, lutgen-recolors the photo, hot-applies IDE / Ghostty / tint.
#   3. Stylix rebuild seed stays theme-selection.nix (gtk store packages).
#   4. Auth: Linux = desktop 1:1; macOS Idle = next pair, same polarity.
#
{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.wallpaper;
      isDarwin = pkgs.stdenv.isDarwin;

      catalog = import ./_wallpaper-catalog.nix { inherit pkgs; };

      localWallpapersDir = ../../wallpapers;
      localFiles =
        if builtins.pathExists localWallpapersDir then builtins.readDir localWallpapersDir else { };
      isImage =
        name:
        lib.any (ext: lib.hasSuffix ext name) [
          ".png"
          ".jpg"
          ".jpeg"
          ".webp"
        ];
      localImages = lib.filterAttrs (name: type: type == "regular" && isImage name) localFiles;
      localDatabase = lib.mapAttrs' (name: _: {
        name = lib.removeSuffix ".webp" (
          lib.removeSuffix ".jpeg" (lib.removeSuffix ".jpg" (lib.removeSuffix ".png" name))
        );
        value = localWallpapersDir + "/${name}";
      }) localImages;

      externalWallpapersDir = ../../external-wallpapers;
      externalFiles =
        if builtins.pathExists externalWallpapersDir then builtins.readDir externalWallpapersDir else { };
      externalImages = lib.filterAttrs (name: type: type == "regular" && isImage name) externalFiles;
      externalDatabase = lib.mapAttrs' (name: _: {
        name = lib.removeSuffix ".webp" (
          lib.removeSuffix ".jpeg" (lib.removeSuffix ".jpg" (lib.removeSuffix ".png" name))
        );
        value = externalWallpapersDir + "/${name}";
      }) externalImages;

      database = catalog.images // localDatabase // externalDatabase // cfg.extraDatabase;

      pack = import ./_wallpaper-pack.nix {
        inherit pkgs lib;
        wallpapers = database;
        inherit (catalog) themes pairs;
        effects = cfg.effects;
      };

      selectedEntry = "${pack}/wallpapers/${cfg.selected}";
      selectedImage = "${selectedEntry}/wallpaper.png";

      appearanceBin = lib.getExe (pkgs.callPackage ./dendritic-appearance/_package.nix { });
      applyPath = lib.makeBinPath (
        [
          pkgs.lutgen
          pkgs.gowall
          pkgs.imagemagick
        ]
        ++ lib.optionals isDarwin [ pkgs.macos-wallpaper-daemon-rse ]
        ++ lib.optionals (!isDarwin) [
          pkgs.swaybg
          pkgs.procps
        ]
      );
    in
    {
      options.dendritic.wallpaper = {
        enable = lib.mkEnableOption "Declarative cross-platform wallpaper + daily palette cycle (desktop + lock)";

        selected = lib.mkOption {
          type = lib.types.str;
          default = "alpine-dark";
          description = ''
            Wallpaper used as Stylix.image at rebuild (greeter seed). Daily cycle
            still rotates pairs + theme families at runtime via dendritic-appearance.
          '';
        };

        extraDatabase = lib.mkOption {
          type = lib.types.attrsOf lib.types.path;
          default = { };
          description = "Additional name → image path entries merged into the pack.";
        };

        scale = lib.mkOption {
          type = lib.types.enum [
            "fill"
            "fit"
            "stretch"
            "center"
          ];
          default = "fill";
          description = "Wallpaper scaling mode (WallpaperKit Fill Screen / swaybg).";
        };

        cycle = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable daily wallpaper + palette cycling (launchd / systemd timer).";
          };
          onLogin = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Apply today's wallpaper on login / HM activation.";
          };
        };

        effects = {
          enable = lib.mkEnableOption "Build-time vignette (subtle rice polish)";
          vignette = lib.mkOption {
            type = lib.types.str;
            default = "0x40";
            description = "ImageMagick -vignette geometry.";
          };
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            assertions = [
              {
                assertion = database ? ${cfg.selected};
                message = "dendritic.wallpaper.selected '${cfg.selected}' not in wallpaper database";
              }
            ];

            stylix.image = lib.mkForce selectedImage;

            home.packages = [
              pkgs.lutgen
              pkgs.gowall
            ]
            ++ lib.optionals isDarwin [ pkgs.macos-wallpaper-daemon-rse ]
            ++ lib.optionals (!isDarwin) [ pkgs.swaybg ];

            xdg.configFile."dendritic/wallpaper-pack".source = pack;

            home.activation.dendriticWallpaper = lib.mkIf cfg.cycle.onLogin (
              lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                echo "dendritic-appearance: applying daily wallpaper"
                export DENDRITIC_HOME="${config.home.homeDirectory}"
                export DENDRITIC_WALLPAPER_PACK="${pack}"
                export DENDRITIC_WALLPAPER_SCALE="${cfg.scale}"
                export DENDRITIC_LUTGEN_BIN="${pkgs.lutgen}/bin/lutgen"
                export DENDRITIC_GOWALL_BIN="${pkgs.gowall}/bin/gowall"
                export PATH="${applyPath}:$PATH"
                ${lib.optionalString isDarwin ''
                  export DENDRITIC_WALLPAPERKIT_LIB="${pkgs.macos-wallpaper-daemon-rse}/lib/libWallpaperKit.dylib"
                  export DENDRITIC_MACOS_WALLPAPERD_BIN="${pkgs.macos-wallpaper-daemon-rse}/bin/macos-wallpaperd"
                ''}
                $DRY_RUN_CMD ${appearanceBin} wallpaper daily
              ''
            );
          }

          (lib.mkIf (cfg.cycle.enable && isDarwin) {
            launchd.agents.dendritic-wallpaper-daily = {
              enable = true;
              config = {
                Label = "com.aspauldingcode.dendritic-wallpaper-daily";
                ProgramArguments = [
                  appearanceBin
                  "wallpaper"
                  "daily"
                ];
                StartCalendarInterval = [
                  {
                    Hour = 0;
                    Minute = 5;
                  }
                ];
                RunAtLoad = true;
                StandardOutPath = "${config.home.homeDirectory}/.local/state/dendritic/wallpaper-daily.log";
                StandardErrorPath = "${config.home.homeDirectory}/.local/state/dendritic/wallpaper-daily.err.log";
                EnvironmentVariables = {
                  HOME = config.home.homeDirectory;
                  DENDRITIC_HOME = config.home.homeDirectory;
                  DENDRITIC_WALLPAPER_PACK = toString pack;
                  DENDRITIC_WALLPAPER_SCALE = cfg.scale;
                  DENDRITIC_LUTGEN_BIN = "${pkgs.lutgen}/bin/lutgen";
                  DENDRITIC_GOWALL_BIN = "${pkgs.gowall}/bin/gowall";
                  DENDRITIC_WALLPAPERKIT_LIB = "${pkgs.macos-wallpaper-daemon-rse}/lib/libWallpaperKit.dylib";
                  DENDRITIC_MACOS_WALLPAPERD_BIN = "${pkgs.macos-wallpaper-daemon-rse}/bin/macos-wallpaperd";
                  PATH = "${applyPath}:/usr/bin:/bin";
                };
              };
            };
          })

          (lib.mkIf (cfg.cycle.enable && !isDarwin) {
            systemd.user.services.dendritic-wallpaper-daily = {
              Unit = {
                Description = "Dendritic daily wallpaper + base16 palette";
                After = [ "graphical-session.target" ];
              };
              Service = {
                Type = "oneshot";
                ExecStart = "${appearanceBin} wallpaper daily";
                Environment = [
                  "DENDRITIC_HOME=${config.home.homeDirectory}"
                  "DENDRITIC_WALLPAPER_PACK=${toString pack}"
                  "DENDRITIC_WALLPAPER_SCALE=${cfg.scale}"
                  "DENDRITIC_LUTGEN_BIN=${pkgs.lutgen}/bin/lutgen"
                  "DENDRITIC_GOWALL_BIN=${pkgs.gowall}/bin/gowall"
                  "PATH=${applyPath}"
                ];
              };
            };
            systemd.user.timers.dendritic-wallpaper-daily = {
              Unit.Description = "Dendritic daily wallpaper timer";
              Timer = {
                OnCalendar = "*-*-* 00:05:00";
                Persistent = true;
                Unit = "dendritic-wallpaper-daily.service";
              };
              Install.WantedBy = [ "timers.target" ];
            };
          })
        ]
      );
    };

  flake.modules.darwin.dendritic =
    { lib, ... }:
    {
      options.dendritic.wallpaper.enable = lib.mkEnableOption "Wallpaper management (desktop + lock)";
    };
  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.wallpaper;
      catalog = import ./_wallpaper-catalog.nix { inherit pkgs; };

      localWallpapersDir = ../../wallpapers;
      localFiles =
        if builtins.pathExists localWallpapersDir then builtins.readDir localWallpapersDir else { };
      isImage =
        name:
        lib.any (ext: lib.hasSuffix ext name) [
          ".png"
          ".jpg"
          ".jpeg"
          ".webp"
        ];
      localImages = lib.filterAttrs (name: type: type == "regular" && isImage name) localFiles;
      localDatabase = lib.mapAttrs' (name: _: {
        name = lib.removeSuffix ".webp" (
          lib.removeSuffix ".jpeg" (lib.removeSuffix ".jpg" (lib.removeSuffix ".png" name))
        );
        value = localWallpapersDir + "/${name}";
      }) localImages;

      externalWallpapersDir = ../../external-wallpapers;
      externalFiles =
        if builtins.pathExists externalWallpapersDir then builtins.readDir externalWallpapersDir else { };
      externalImages = lib.filterAttrs (name: type: type == "regular" && isImage name) externalFiles;
      externalDatabase = lib.mapAttrs' (name: _: {
        name = lib.removeSuffix ".webp" (
          lib.removeSuffix ".jpeg" (lib.removeSuffix ".jpg" (lib.removeSuffix ".png" name))
        );
        value = externalWallpapersDir + "/${name}";
      }) externalImages;

      database = catalog.images // localDatabase // externalDatabase // cfg.extraDatabase;

      pack = import ./_wallpaper-pack.nix {
        inherit pkgs lib;
        wallpapers = database;
        inherit (catalog) themes pairs;
        effects = cfg.effects;
      };

      selectedEntry = "${pack}/wallpapers/${cfg.selected}";
      selectedImage = "${selectedEntry}/wallpaper.png";
    in
    {
      options.dendritic.wallpaper = {
        enable = lib.mkEnableOption "Declarative wallpaper + Stylix sync (greetd/gtkgreet); lock via gtklock";

        selected = lib.mkOption {
          type = lib.types.str;
          default = "alpine-dark";
          description = "Wallpaper for system Stylix / gtkgreet (from wallpaper pack).";
        };

        extraDatabase = lib.mkOption {
          type = lib.types.attrsOf lib.types.path;
          default = { };
        };

        effects = {
          enable = lib.mkEnableOption "Build-time vignette";
          vignette = lib.mkOption {
            type = lib.types.str;
            default = "0x40";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = database ? ${cfg.selected};
            message = "dendritic.wallpaper.selected '${cfg.selected}' not in wallpaper database";
          }
        ];

        stylix.image = lib.mkForce selectedImage;
      };
    };
}
