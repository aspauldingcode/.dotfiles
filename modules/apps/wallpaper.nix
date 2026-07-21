# ── Dendritic Wallpaper (macOS + Linux, 1:1) ────────────────────────────
#
# Architecture:
#   1. Build-time: flavours → full base16 per wallpaper (dark+light) in the pack.
#      (gowall extract is only ~6 colors; not enough for Stylix — optional manual.)
#   2. Runtime: `dendritic-appearance wallpaper …` picks pack entry + copies its
#      colors.toml, then hot-applies IDE / tmux / Ghostty / tint (both OSes).
#   3. Stylix seed at rebuild: themeFromImage uses `selected` for store packages.
#   4. Auth: Linux = desktop 1:1; macOS Idle ≠ desktop.
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
      variant = config.dendritic.theme.variant;

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

      # Clean minimal rice wallpapers from nixos-artwork (no network API).
      artwork = pkgs.nixos-artwork.wallpapers;
      curatedDatabase = {
        nineish = artwork.nineish.gnomeFilePath;
        nineish-dark-gray = artwork.nineish-dark-gray.gnomeFilePath;
        nineish-solarized-dark = artwork.nineish-solarized-dark.gnomeFilePath;
        nineish-solarized-light = artwork.nineish-solarized-light.gnomeFilePath;
        simple-dark-gray = artwork.simple-dark-gray.gnomeFilePath;
        simple-light-gray = artwork.simple-light-gray.gnomeFilePath;
        mosaic-blue = artwork.mosaic-blue.gnomeFilePath;
        stripes = artwork.stripes.gnomeFilePath;
        gradient-grey = artwork.gradient-grey.gnomeFilePath;
        waterfall = artwork.waterfall.gnomeFilePath;
        moonscape = artwork.moonscape.gnomeFilePath;
        catppuccin-mocha = artwork.catppuccin-mocha.gnomeFilePath;
        catppuccin-latte = artwork.catppuccin-latte.gnomeFilePath;
        dracula = artwork.dracula.gnomeFilePath;
      };

      database = curatedDatabase // localDatabase // cfg.extraDatabase;

      pack = import ./_wallpaper-pack.nix {
        inherit pkgs lib;
        wallpapers = database;
        effects = cfg.effects;
      };

      selectedEntry = "${pack}/wallpapers/${cfg.selected}";
      selectedScheme = "${selectedEntry}/scheme-${variant}.yaml";
      selectedImage = "${selectedEntry}/wallpaper.png";

      # Binary owned by appearance.nix; wallpaper only supplies pack + timers.
      appearanceBin = lib.getExe (pkgs.callPackage ./dendritic-appearance/_package.nix { });
    in
    {
      options.dendritic.wallpaper = {
        enable = lib.mkEnableOption "Declarative cross-platform wallpaper + daily palette cycle (desktop + lock)";

        selected = lib.mkOption {
          type = lib.types.str;
          default = "moonscape";
          description = ''
            Wallpaper used for Stylix build-time scheme injection (themeFromImage).
            Daily cycle still rotates the full pack at runtime. Lockscreen picks a
            different pack entry via dendritic-appearance (not the desktop current).
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
          description = "Wallpaper scaling mode (macos-wallpaper / swaybg).";
        };

        themeFromImage = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            When true, Stylix base16Scheme is generated from `selected` via flavours
            (replacing the static theme-selection.nix scheme for themed packages).
          '';
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

        gowall = {
          enable = lib.mkEnableOption "Install gowall for manual tint/effects (not used by daily cycle)";
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

            # Build-time Stylix: wallpaper-derived scheme + image.
            stylix.image = lib.mkForce selectedImage;
            stylix.base16Scheme = lib.mkIf cfg.themeFromImage (lib.mkOverride 40 selectedScheme);

            home.file.".colors.toml" = lib.mkForce {
              source = "${selectedEntry}/colors-${variant}.toml";
              force = true;
            };

            home.packages = [
              pkgs.flavours
            ]
            ++ lib.optionals cfg.gowall.enable [ pkgs.gowall ]
            ++ lib.optionals isDarwin [ pkgs.macos-wallpaper ]
            ++ lib.optionals (!isDarwin) [ pkgs.swaybg ];

            xdg.configFile."dendritic/wallpaper-pack".source = pack;

            home.activation.dendriticWallpaper = lib.mkIf cfg.cycle.onLogin (
              lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                echo "dendritic-appearance: applying daily wallpaper"
                export DENDRITIC_HOME="${config.home.homeDirectory}"
                export DENDRITIC_WALLPAPER_PACK="${pack}"
                export DENDRITIC_WALLPAPER_SCALE="${cfg.scale}"
                ${lib.optionalString isDarwin ''
                  export DENDRITIC_MACOS_WALLPAPER_BIN="${pkgs.macos-wallpaper}/bin/wallpaper"
                  export PATH="${pkgs.macos-wallpaper}/bin:$PATH"
                ''}
                ${lib.optionalString (!isDarwin) ''
                  export PATH="${pkgs.swaybg}/bin:${pkgs.procps}/bin:$PATH"
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
                  DENDRITIC_MACOS_WALLPAPER_BIN = "${pkgs.macos-wallpaper}/bin/wallpaper";
                  PATH = "${pkgs.macos-wallpaper}/bin:/usr/bin:/bin";
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
                  "PATH=${pkgs.swaybg}/bin:${pkgs.procps}/bin"
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

  # Host-level: sync Stylix image+scheme (chrome tokens) from the pack.
  # Linux gtkgreet/gtklock use desktop-current wallpaper at runtime (auth-path).
  flake.modules.darwin.dendritic =
    { lib, ... }:
    {
      # Option mirror only — HM `dendritic.wallpaper.enable` owns pack, daily
      # desktop (macos-wallpaper), and lock (Idle Index.plist) on Darwin.
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
      variant = config.dendritic.theme.variant;

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

      artwork = pkgs.nixos-artwork.wallpapers;
      curatedDatabase = {
        nineish = artwork.nineish.gnomeFilePath;
        nineish-dark-gray = artwork.nineish-dark-gray.gnomeFilePath;
        nineish-solarized-dark = artwork.nineish-solarized-dark.gnomeFilePath;
        nineish-solarized-light = artwork.nineish-solarized-light.gnomeFilePath;
        simple-dark-gray = artwork.simple-dark-gray.gnomeFilePath;
        simple-light-gray = artwork.simple-light-gray.gnomeFilePath;
        mosaic-blue = artwork.mosaic-blue.gnomeFilePath;
        stripes = artwork.stripes.gnomeFilePath;
        gradient-grey = artwork.gradient-grey.gnomeFilePath;
        waterfall = artwork.waterfall.gnomeFilePath;
        moonscape = artwork.moonscape.gnomeFilePath;
        catppuccin-mocha = artwork.catppuccin-mocha.gnomeFilePath;
        catppuccin-latte = artwork.catppuccin-latte.gnomeFilePath;
        dracula = artwork.dracula.gnomeFilePath;
      };

      database = curatedDatabase // localDatabase // cfg.extraDatabase;

      pack = import ./_wallpaper-pack.nix {
        inherit pkgs lib;
        wallpapers = database;
        effects = cfg.effects;
      };

      selectedEntry = "${pack}/wallpapers/${cfg.selected}";
      selectedScheme = "${selectedEntry}/scheme-${variant}.yaml";
      selectedImage = "${selectedEntry}/wallpaper.png";
    in
    {
      options.dendritic.wallpaper = {
        enable = lib.mkEnableOption "Declarative wallpaper + Stylix sync (greetd/gtkgreet); lock via gtklock";

        selected = lib.mkOption {
          type = lib.types.str;
          default = "moonscape";
          description = "Wallpaper for system Stylix / gtkgreet (from wallpaper pack).";
        };

        extraDatabase = lib.mkOption {
          type = lib.types.attrsOf lib.types.path;
          default = { };
        };

        themeFromImage = lib.mkOption {
          type = lib.types.bool;
          default = true;
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

        # Same pack image + flavours scheme as HM → gtkgreet theming.
        stylix.image = lib.mkForce selectedImage;
        stylix.base16Scheme = lib.mkIf cfg.themeFromImage (lib.mkOverride 40 selectedScheme);
      };
    };
}
