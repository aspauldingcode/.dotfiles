# ── Dendritic Wallpaper Daemon (macOS + Linux, 1:1) ─────────────────────
#
# Architecture (how r/unixporn does this, made declarative):
#   1. Build-time: flavours extracts base16 from each wallpaper (dark+light).
#   2. Runtime: daily timer / activation picks wallpaper by day-of-year.
#   3. Hot-reload: ~/colors.toml + IDE settings watchers pick up the palette.
#   4. Stylix: when themeFromImage, base16Scheme = selected wallpaper's scheme
#      (build-time). Daily cycle overlays the hot-reload layer without rebuild.
#
# gowall: optional. It *tints* images toward a named theme (opposite direction).
# We keep it for manual `gowall effects` / convert — not for daily unique themes.
# No web API: curated nixos-artwork + local ./wallpapers (reproducible).
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

      patchIde = pkgs.writeText "dendritic-wallpaper-patch-ide.py" (
        builtins.readFile ../../scripts/dendritic-wallpaper-patch-ide.py
      );

      wallpaperBin = pkgs.writeShellApplication {
        name = "dendritic-wallpaper";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.jq
          pkgs.python3
        ]
        ++ lib.optionals isDarwin [ pkgs.macos-wallpaper ]
        ++ lib.optionals (!isDarwin) [
          pkgs.swaybg
          pkgs.procps
        ];
        text = ''
          set -euo pipefail

          PACK=${lib.escapeShellArg pack}
          MANIFEST="$PACK/manifest.json"
          STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/dendritic"
          STATE_FILE="$STATE_DIR/wallpaper.json"
          COLORS_FILE="''${DENDRITIC_COLORS_FILE:-$HOME/colors.toml}"
          DEFAULT_VARIANT=${lib.escapeShellArg variant}
          SCALE=${lib.escapeShellArg cfg.scale}
          PATCH_IDE=${lib.escapeShellArg (toString patchIde)}

          mkdir -p "$STATE_DIR"

          resolve_variant() {
            if [ -n "''${DENDRITIC_THEME_VARIANT:-}" ]; then
              echo "$DENDRITIC_THEME_VARIANT"
              return
            fi
            if [ -r /var/lib/dendritic/appearance-variant ]; then
              tr -d '[:space:]' < /var/lib/dendritic/appearance-variant
              return
            fi
            echo "$DEFAULT_VARIANT"
          }

          wallpaper_count() {
            jq '.wallpapers | length' "$MANIFEST"
          }

          index_of_name() {
            local name="$1"
            jq -r --arg n "$name" '
              .wallpapers
              | to_entries
              | map(select(.value.name == $n))
              | .[0].key // empty
            ' "$MANIFEST"
          }

          pick_daily_index() {
            local count day
            count="$(wallpaper_count)"
            if [ "$count" -le 0 ]; then
              echo "dendritic-wallpaper: empty wallpaper pack" >&2
              exit 1
            fi
            day="$(date +%j)"
            # 1..366 → 0..count-1 (same calendar day → same wallpaper on all hosts)
            echo $(( (10#$day - 1) % count ))
          }

          entry_json() {
            local idx="$1"
            jq -c --argjson i "$idx" '.wallpapers[$i]' "$MANIFEST"
          }

          apply_palette() {
            local entry="$1"
            local variant="$2"
            local colors name
            colors="$(echo "$entry" | jq -r --arg v "$variant" '.colors[$v]')"
            name="$(echo "$entry" | jq -r '.name')"

            if [ ! -f "$colors" ]; then
              echo "dendritic-wallpaper: missing colors for $name ($variant)" >&2
              exit 1
            fi

            # Replace HM store symlink with a mutable file for hot-reload.
            rm -f "$COLORS_FILE"
            cp "$colors" "$COLORS_FILE"
            chmod u+w "$COLORS_FILE"
            python3 "$PATCH_IDE" "$colors"
          }

          set_os_wallpaper() {
            local image="$1"
            if [ "$(uname -s)" = "Darwin" ]; then
              wallpaper set "$image" --scale "$SCALE"
            else
              # All workspaces: swaybg covers the Wayland output (niri/sway).
              pkill -x swaybg 2>/dev/null || true
              sleep 0.2
              nohup swaybg -i "$image" -m "$SCALE" >/dev/null 2>&1 &
            fi
          }

          write_state() {
            local entry="$1"
            local variant="$2"
            local mode="$3"
            local idx="$4"
            jq -n \
              --argjson entry "$entry" \
              --arg variant "$variant" \
              --arg mode "$mode" \
              --argjson index "$idx" \
              --arg applied "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
              '{
                name: $entry.name,
                image: $entry.image,
                variant: $variant,
                mode: $mode,
                index: $index,
                applied: $applied
              }' > "$STATE_FILE"
          }

          apply_index() {
            local idx="$1"
            local mode="$2"
            local variant entry image
            variant="$(resolve_variant)"
            entry="$(entry_json "$idx")"
            image="$(echo "$entry" | jq -r '.image')"
            apply_palette "$entry" "$variant"
            set_os_wallpaper "$image"
            write_state "$entry" "$variant" "$mode" "$idx"
            echo "dendritic-wallpaper: applied $(echo "$entry" | jq -r .name) ($variant, $mode)"
          }

          cmd="''${1:-apply}"
          shift || true

          case "$cmd" in
            apply)
              target="''${1:-daily}"
              case "$target" in
                daily|"")
                  apply_index "$(pick_daily_index)" daily
                  ;;
                next)
                  count="$(wallpaper_count)"
                  cur=0
                  if [ -f "$STATE_FILE" ]; then
                    cur="$(jq -r '.index // 0' "$STATE_FILE")"
                  fi
                  apply_index "$(( (cur + 1) % count ))" next
                  ;;
                *)
                  idx="$(index_of_name "$target")"
                  if [ -z "$idx" ]; then
                    echo "dendritic-wallpaper: unknown wallpaper '$target'" >&2
                    echo "Known:" >&2
                    jq -r '.wallpapers[].name' "$MANIFEST" >&2
                    exit 1
                  fi
                  apply_index "$idx" named
                  ;;
              esac
              ;;
            list)
              jq -r '.wallpapers[] | "\(.name)\t\(.image)"' "$MANIFEST"
              ;;
            status)
              if [ -f "$STATE_FILE" ]; then
                jq . "$STATE_FILE"
              else
                echo '{"status":"unset"}'
              fi
              ;;
            pack)
              echo "$PACK"
              ;;
            *)
              echo "Usage: dendritic-wallpaper apply [daily|next|<name>] | list | status | pack" >&2
              exit 1
              ;;
          esac
        '';
      };
    in
    {
      options.dendritic.wallpaper = {
        enable = lib.mkEnableOption "Declarative cross-platform wallpaper + daily palette cycle";

        selected = lib.mkOption {
          type = lib.types.str;
          default = "mountain-sunset";
          description = ''
            Wallpaper used for Stylix build-time scheme injection (themeFromImage).
            Daily cycle still rotates the full pack at runtime.
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
            # Higher priority than den-aspects/styling.nix mkForce (50).
            stylix.image = lib.mkForce selectedImage;
            stylix.base16Scheme = lib.mkIf cfg.themeFromImage (lib.mkOverride 40 selectedScheme);

            # Seed colors.toml from selected wallpaper. `force` avoids HM backup
            # fights when the daily apply replaces the store symlink with a
            # mutable copy for neovim hot-reload.
            home.file."colors.toml" = lib.mkForce {
              source = "${selectedEntry}/colors-${variant}.toml";
              force = true;
            };

            home.packages = [
              wallpaperBin
              pkgs.flavours
            ]
            ++ lib.optionals cfg.gowall.enable [ pkgs.gowall ]
            ++ lib.optionals isDarwin [ pkgs.macos-wallpaper ]
            ++ lib.optionals (!isDarwin) [ pkgs.swaybg ];

            # Persist pack pointer for debugging / external tools.
            xdg.configFile."dendritic/wallpaper-pack".source = pack;

            home.activation.dendriticWallpaper = lib.mkIf cfg.cycle.onLogin (
              lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                echo "dendritic-wallpaper: applying daily wallpaper"
                $DRY_RUN_CMD ${lib.getExe wallpaperBin} apply daily
              ''
            );
          }

          (lib.mkIf (cfg.cycle.enable && isDarwin) {
            launchd.agents.dendritic-wallpaper-daily = {
              enable = true;
              config = {
                Label = "com.aspaulding.dendritic-wallpaper-daily";
                ProgramArguments = [
                  (lib.getExe wallpaperBin)
                  "apply"
                  "daily"
                ];
                # Local midnight-ish: StartCalendarInterval at 00:05.
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
                  DENDRITIC_THEME_VARIANT = variant;
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
                ExecStart = "${lib.getExe wallpaperBin} apply daily";
                Environment = [ "DENDRITIC_THEME_VARIANT=${variant}" ];
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

  # Host-level enable stubs (actual work is HM).
  flake.modules.darwin.dendritic =
    { lib, ... }:
    {
      options.dendritic.wallpaper.enable = lib.mkEnableOption "Wallpaper management";
    };
  flake.modules.nixos.dendritic =
    { lib, ... }:
    {
      options.dendritic.wallpaper.enable = lib.mkEnableOption "Wallpaper management";
    };
}
