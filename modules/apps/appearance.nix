# dendritic-appearance — pure-Rust light/dark state machine (macOS + NixOS).
#
# Invariant: host appearance and global theme layers never desync.
# launchd/systemd run `dendritic-appearance supervise` (no bash sync scripts).
{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.appearance;
      isDarwin = pkgs.stdenv.isDarwin;
      packPath = config.xdg.configFile."dendritic/wallpaper-pack".source or null;
      scale = config.dendritic.wallpaper.scale or "fill";
      raw = pkgs.callPackage ./dendritic-appearance/_package.nix { };
      pathBins = [
        pkgs.coreutils
      ]
      ++ lib.optionals isDarwin [ pkgs.macos-wallpaper ]
      ++ lib.optionals (!isDarwin) [
        pkgs.swaybg
        pkgs.procps
      ];
      appearancePkg = pkgs.symlinkJoin {
        name = "dendritic-appearance";
        paths = [ raw ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild =
          let
            wrapArgs = [
              "--prefix"
              "PATH"
              ":"
              (lib.makeBinPath pathBins)
              "--set-default"
              "DENDRITIC_WALLPAPER_SCALE"
              scale
            ]
            ++ lib.optionals (packPath != null) [
              "--set-default"
              "DENDRITIC_WALLPAPER_PACK"
              (toString packPath)
            ]
            ++ lib.optionals isDarwin [
              "--set-default"
              "DENDRITIC_MACOS_WALLPAPER_BIN"
              "${pkgs.macos-wallpaper}/bin/wallpaper"
            ];
          in
          ''
            wrapProgram $out/bin/dendritic-appearance ${lib.escapeShellArgs wrapArgs}
          '';
        meta = raw.meta;
      };
      appearanceBin = lib.getExe appearancePkg;
    in
    {
      options.dendritic.appearance = {
        enable = lib.mkEnableOption "Rust appearance state machine" // {
          default = config.dendritic.wallpaper.enable or false;
          defaultText = lib.literalExpression "config.dendritic.wallpaper.enable";
        };
        pollIntervalSec = lib.mkOption {
          type = lib.types.ints.positive;
          default = 2;
          description = "Supervisor poll interval for desync detection.";
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            home.packages = [ appearancePkg ];
            home.sessionVariables = {
              DENDRITIC_WALLPAPER_PACK = lib.mkIf (packPath != null) (toString packPath);
              DENDRITIC_WALLPAPER_SCALE = scale;
            };

            # Login reconcile — catch desync before the long-running supervisor attaches.
            home.activation.dendriticAppearanceReconcile =
              lib.hm.dag.entryAfter
                (
                  [ "writeBoundary" ]
                  ++ lib.optional (config.dendritic.wallpaper.enable or false) "dendriticWallpaper"
                )
                ''
                  echo "dendritic-appearance: reconcile"
                  export DENDRITIC_HOME="${config.home.homeDirectory}"
                  ${lib.optionalString (packPath != null) ''
                    export DENDRITIC_WALLPAPER_PACK="${packPath}"
                  ''}
                  $DRY_RUN_CMD ${appearanceBin} reconcile || true
                '';
          }

          (lib.mkIf isDarwin {
            launchd.agents.dendritic-appearance = {
              enable = true;
              config = {
                Label = "com.aspauldingcode.dendritic-appearance";
                ProgramArguments = [
                  appearanceBin
                  "supervise"
                  (toString cfg.pollIntervalSec)
                ];
                RunAtLoad = true;
                KeepAlive = true;
                # Also wake on macOS appearance preference flips.
                WatchPaths = [
                  "${config.home.homeDirectory}/Library/Preferences/.GlobalPreferences.plist"
                ];
                EnvironmentVariables = {
                  HOME = config.home.homeDirectory;
                  DENDRITIC_HOME = config.home.homeDirectory;
                  DENDRITIC_USER = config.home.username;
                  DENDRITIC_WALLPAPER_SCALE = scale;
                }
                // lib.optionalAttrs (packPath != null) {
                  DENDRITIC_WALLPAPER_PACK = toString packPath;
                }
                // lib.optionalAttrs isDarwin {
                  DENDRITIC_MACOS_WALLPAPER_BIN = "${pkgs.macos-wallpaper}/bin/wallpaper";
                };
                StandardOutPath = "${config.home.homeDirectory}/.local/state/dendritic/appearance-supervise.log";
                StandardErrorPath = "${config.home.homeDirectory}/.local/state/dendritic/appearance-supervise.err.log";
              };
            };
          })

          (lib.mkIf (!isDarwin) {
            systemd.user.services.dendritic-appearance = {
              Unit = {
                Description = "Dendritic appearance state machine (no desync)";
                After = [ "graphical-session.target" ];
                PartOf = [ "graphical-session.target" ];
              };
              Service = {
                ExecStart = "${appearanceBin} supervise ${toString cfg.pollIntervalSec}";
                Restart = "always";
                RestartSec = "2";
                Environment = [
                  "DENDRITIC_HOME=${config.home.homeDirectory}"
                  "DENDRITIC_USER=${config.home.username}"
                  "DENDRITIC_WALLPAPER_SCALE=${scale}"
                ]
                ++ lib.optionals (packPath != null) [
                  "DENDRITIC_WALLPAPER_PACK=${toString packPath}"
                ];
              };
              Install.WantedBy = [ "graphical-session.target" ];
            };
          })
        ]
      );
    };

  # Darwin system: prebuild cache only (nix-build). Sync runtime is pure Rust.
  flake.modules.darwin.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      user = config.system.primaryUser;
      host = config.networking.hostName;
      appearancePkg = pkgs.callPackage ./dendritic-appearance/_package.nix { };
    in
    {
      config = lib.mkIf (config.home-manager.users ? ${user}) {
        environment.systemPackages = [ appearancePkg ];

        environment.etc."dendritic-appearance-watch.sh".source =
          pkgs.writeShellScript "dendritic-appearance-watch" ''
            # Minimal launchd shim only: asuser + env (plist cannot express this).
            uid="$(${pkgs.coreutils}/bin/id -u ${user})"
            exec /bin/launchctl asuser "$uid" /usr/bin/sudo -u ${user} \
              /usr/bin/env HOME="/Users/${user}" DENDRITIC_HOME="/Users/${user}" DENDRITIC_USER="${user}" \
              ${lib.getExe appearancePkg} reconcile
          '';

        launchd.daemons.dendritic-appearance-watch = {
          serviceConfig = {
            Label = "com.aspauldingcode.dendritic-appearance-watch";
            ProgramArguments = [
              "/bin/sh"
              "/etc/dendritic-appearance-watch.sh"
            ];
            RunAtLoad = true;
            WatchPaths = [ "/Users/${user}/Library/Preferences/.GlobalPreferences.plist" ];
            StandardOutPath = "/var/log/dendritic-appearance-sync.log";
            StandardErrorPath = "/var/log/dendritic-appearance-sync.err.log";
          };
        };

        system.activationScripts.postActivation.text = lib.mkAfter ''
          mkdir -p /var/lib/dendritic
          state_dir="/var/lib/dendritic"
          skip_prebuild=0
          if [ -f "$state_dir/fast-activate" ]; then
            skip_prebuild=1
          fi

          if [ "$skip_prebuild" -eq 0 ]; then
            # Prebuild light+dark profiles for activation-only toggles.
            src_real="/private/etc/nix-darwin/.dotfiles"
            src_mirror="/private/var/lib/dendritic/flake-source"
            nix_bin="${pkgs.nix}/bin/nix"
            dark_attr="path:$src_mirror#darwinConfigurations.${host}-dark.config.system.build.toplevel"
            light_attr="path:$src_mirror#darwinConfigurations.${host}.config.system.build.toplevel"
            mkdir -p "$src_mirror"
            if /usr/bin/rsync -a --delete --delete-excluded \
              --exclude=".git/" --exclude=".cache/" --exclude=".cursor/" \
              --exclude="result" \
              "$src_real/" "$src_mirror/" \
              && dark_out="$("$nix_bin" build --no-link --print-out-paths "$dark_attr")" \
              && light_out="$("$nix_bin" build --no-link --print-out-paths "$light_attr")"
            then
              printf '%s\n' "$dark_out" > "$state_dir/prebuilt-dark-path"
              printf '%s\n' "$light_out" > "$state_dir/prebuilt-light-path"
              chmod 644 "$state_dir/prebuilt-dark-path" "$state_dir/prebuilt-light-path"
            else
              echo "warning: appearance prebuild failed; keeping previous cache" >&2
            fi

            # Drop legacy labels from older generations.
            for legacy in \
              org.nixos.dendritic-appearance-watch \
              com.aspaulding.dendritic-appearance-watch
            do
              /bin/launchctl bootout "system/$legacy" >/dev/null 2>&1 || true
            done
            /bin/launchctl kickstart -k system/com.aspauldingcode.dendritic-appearance-watch >/dev/null 2>&1 || true
            /bin/launchctl asuser "$(${pkgs.coreutils}/bin/id -u ${user})" /usr/bin/sudo -u ${user} \
              /usr/bin/env HOME="/Users/${user}" DENDRITIC_HOME="/Users/${user}" DENDRITIC_USER="${user}" \
              ${lib.getExe appearancePkg} reconcile \
              >>/var/log/dendritic-appearance-sync.log 2>&1 || true
          fi
        '';
      };
    };

  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      appearancePkg = pkgs.callPackage ./dendritic-appearance/_package.nix { };
    in
    {
      config = lib.mkIf (config.dendritic.apps.niri.enable or false) {
        environment.systemPackages = [ appearancePkg ];
      };
    };
}
