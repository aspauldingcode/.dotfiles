# Always-on nix-android converge agent (mba launchd + sliceanddice systemd).
# Shared module; phone-side adb lease prevents duplicate apply across hosts.
{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      inputs,
      ...
    }:
    let
      cfg = config.dendritic.androidConverge;
      dendriticBin = lib.getExe (pkgs.callPackage ../../crates/dendritic/_package.nix { });
      system = pkgs.stdenv.hostPlatform.system;
      defaultDotfiles =
        if pkgs.stdenv.isDarwin then "/etc/nix-darwin/.dotfiles" else "/etc/nixos/.dotfiles";
      flakeAttr = if pkgs.stdenv.isDarwin then "oneplus6t-darwin" else "oneplus6t-linux";
      hasControllerPkgs = builtins.elem system [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      androidRebuild = if hasControllerPkgs then inputs.self.packages.${system}.android-rebuild else null;
      adbWireless = if hasControllerPkgs then inputs.self.packages.${system}.adb-wireless else null;
      fleetCfg = config.dendritic.fleet or { };
      convergeScript = pkgs.writeShellScriptBin "android-converge" ''
        export PATH="${
          lib.makeBinPath [
            pkgs.coreutils
            pkgs.gnused
            pkgs.gnugrep
            pkgs.android-tools
            pkgs.python3
            pkgs.gh
            pkgs.jq
          ]
        }:$PATH"
        export ANDROID_CONVERGE_HOST_ID=${lib.escapeShellArg cfg.hostId}
        export ANDROID_CONVERGE_FLAKE=${lib.escapeShellArg "${cfg.dotfilesRoot}#${cfg.flakeAttr}"}
        export ANDROID_CONVERGE_DEVICE=${lib.escapeShellArg cfg.device}
        export ANDROID_CONVERGE_BIN=${lib.escapeShellArg "${androidRebuild}/bin/android-rebuild"}
        export ANDROID_CONVERGE_ADB_WIRELESS_BIN=${
          lib.escapeShellArg (if adbWireless != null then "${adbWireless}/bin/adb-wireless" else "")
        }
        export ANDROID_CONVERGE_LEASE_TTL=${lib.escapeShellArg (toString cfg.leaseTtlSec)}
        export ANDROID_CONVERGE_APPLY=${if cfg.apply then "1" else "0"}
        export ANDROID_CONVERGE_STATUS=${lib.escapeShellArg "${config.home.homeDirectory}/.cache/android-converge.status"}
        export FLEET_STATUS_OWNER=${lib.escapeShellArg (fleetCfg.owner or "aspauldingcode")}
        export FLEET_STATUS_REPO=${lib.escapeShellArg (fleetCfg.repo or "dendritic-fleet-status")}
        ${lib.optionalString ((fleetCfg.enable or false) && (fleetCfg.useSopsToken or false)) ''
          export FLEET_STATUS_TOKEN_FILE=${lib.escapeShellArg config.sops.secrets.fleet_status_github_token.path}
        ''}
        exec ${pkgs.bash}/bin/bash ${../../scripts/android-converge-agent.sh}
      '';
      logDir = "${config.home.homeDirectory}/.cache";
    in
    {
      options.dendritic.androidConverge = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Always-on android-rebuild agent (launchd on Darwin, systemd user timer
            on Linux). Enable on controller hosts only (mba, sliceanddice).
          '';
        };

        hostId = lib.mkOption {
          type = lib.types.str;
          # Prefer fleet host id when set — same identity for the phone lease.
          default = config.dendritic.fleet.hostId or "";
          defaultText = lib.literalExpression "config.dendritic.fleet.hostId";
          description = "Controller identity written into the on-device lease.";
        };

        device = lib.mkOption {
          type = lib.types.str;
          default = "oneplus6t";
          description = "nix-android device.name (lease file key + docs).";
        };

        flakeAttr = lib.mkOption {
          type = lib.types.str;
          default = flakeAttr;
          description = "Flake output after # (oneplus6t-darwin / oneplus6t-linux).";
        };

        dotfilesRoot = lib.mkOption {
          type = lib.types.str;
          default = config.dendritic.fleet.dotfilesRoot or defaultDotfiles;
          defaultText = lib.literalExpression "config.dendritic.fleet.dotfilesRoot";
          description = "Checkout path used in --flake ROOT#ATTR.";
        };

        intervalSec = lib.mkOption {
          type = lib.types.ints.positive;
          default = 900;
          description = "Converge interval in seconds (default 15m).";
        };

        leaseTtlSec = lib.mkOption {
          type = lib.types.ints.positive;
          default = 600;
          description = "On-device lease TTL so a crashed controller does not block forever.";
        };

        apply = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "If true, run switch; if false, plan-only (dry).";
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            assertions = [
              {
                assertion = cfg.hostId != "";
                message = "dendritic.androidConverge.hostId must be set (or enable dendritic.fleet with hostId)";
              }
              {
                assertion = hasControllerPkgs && androidRebuild != null;
                message = "dendritic.androidConverge requires android-rebuild on ${system} (aarch64-darwin or x86_64-linux)";
              }
            ];

            home.packages = [
              androidRebuild
              pkgs.android-tools
            ]
            ++ lib.optional (adbWireless != null) adbWireless;
          }

          (lib.mkIf pkgs.stdenv.isDarwin {
            launchd.agents.android-converge = {
              enable = true;
              config = {
                Label = "com.aspauldingcode.android-converge";
                ProgramArguments = [
                  dendriticBin
                  "android"
                  "converge"
                ];
                RunAtLoad = true;
                StartInterval = cfg.intervalSec;
                StandardOutPath = "${logDir}/android-converge.log";
                StandardErrorPath = "${logDir}/android-converge.err.log";
                EnvironmentVariables = {
                  HOME = config.home.homeDirectory;
                  PATH = "${
                    lib.makeBinPath [
                      convergeScript
                      pkgs.coreutils
                    ]
                  }:/usr/bin:/bin";
                  DENDRITIC_ANDROID_CONVERGE = lib.getExe convergeScript;
                };
              };
            };
          })

          (lib.mkIf pkgs.stdenv.isLinux {
            systemd.user.services.android-converge = {
              Unit = {
                Description = "Dendritic nix-android converge (leased)";
                After = [ "default.target" ];
              };
              Service = {
                Type = "oneshot";
                ExecStart = "${dendriticBin} android converge";
                Environment = [ "DENDRITIC_ANDROID_CONVERGE=${lib.getExe convergeScript}" ];
              };
            };
            systemd.user.timers.android-converge = {
              Unit.Description = "Dendritic nix-android converge timer";
              Timer = {
                OnBootSec = "2min";
                OnUnitActiveSec = "${toString cfg.intervalSec}s";
                Persistent = true;
                Unit = "android-converge.service";
              };
              Install.WantedBy = [ "timers.target" ];
            };
          })
        ]
      );
    };
}
