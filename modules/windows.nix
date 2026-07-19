# dendritic.windows — declarative dual-boot helper for Windows 11 IoT Enterprise LTSC.
#
# Disk layout: hosts/.../disko.nix. Bootstrap oneshot extracts Setup media onto
# a persistent wininstall partition and BootNexts into silent Setup once;
# later nh os switch is a no-op (media-ready / installed markers).
{
  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.windows;
      stateDir = "/var/lib/dendritic-windows";
      cacheDir = "/var/cache/dendritic-windows";

      # Official IoT Enterprise LTSC 2024 x64 eval (Microsoft Eval Center / fwlink).
      # SHA256 from Windows11IoTEnterpriseLTSC2024EvalHashValues.pdf (x64 en-us).
      defaultIsoSha256 = "67cec5865eaa037a72ddc633a717a10a2bed50778862267223ddb9c60ef5da68";
      defaultIsoName = "26100.1742.240906-0331.ge_release_svc_refresh_CLIENT_LTSC_EVAL_x64FRE_en-us.iso";
      # Resolves to software-static.download.prss.microsoft.com … CLIENT_LTSC_EVAL …
      defaultIsoUrl = "https://go.microsoft.com/fwlink/?linkid=2289029";

      unattendTemplate = ./pkgs/_dendritic-windows-unattend.xml;

      labelGpt = pkgs.writeShellApplication {
        name = "dendritic-windows-label-gpt";
        runtimeInputs = with pkgs; [
          gptfdisk
          util-linux
          parted
          e2fsprogs
          gnugrep
          gawk
          coreutils
          findutils
        ];
        excludeShellChecks = [
          "SC2086"
          "SC2046"
          "SC2034"
          "SC2002"
        ];
        text = builtins.readFile ./pkgs/_dendritic-windows-label-gpt.sh;
      };

      bootstrap = pkgs.writeShellApplication {
        name = "dendritic-windows-bootstrap";
        runtimeInputs = with pkgs; [
          coreutils
          util-linux
          parted
          gptfdisk
          e2fsprogs
          ntfs3g
          wimlib
          aria2
          curl
          jq
          efibootmgr
          gawk
          gnused
          gnugrep
          rsync
          findutils
        ];
        excludeShellChecks = [
          "SC2086"
          "SC2046"
          "SC2034"
          "SC2001"
          "SC2016"
        ];
        text = builtins.readFile ./pkgs/_dendritic-windows-bootstrap.sh;
      };

      finalize = pkgs.writeShellApplication {
        name = "dendritic-windows-finalize";
        runtimeInputs = with pkgs; [
          coreutils
          efibootmgr
          gnused
          util-linux
        ];
        excludeShellChecks = [
          "SC2086"
          "SC2207"
        ];
        text = builtins.readFile ./pkgs/_dendritic-windows-finalize.sh;
      };

      continueSetup = pkgs.writeShellApplication {
        name = "dendritic-windows-continue-setup";
        runtimeInputs = with pkgs; [
          coreutils
          efibootmgr
          gnused
          systemd
        ];
        excludeShellChecks = [
          "SC2086"
        ];
        text = builtins.readFile ./pkgs/_dendritic-windows-continue-setup.sh;
      };

      identityEnabled = config.dendritic.identity.enable or false;
      identityCfg = config.dendritic.identity or { };
      identityPasswordPath = if identityEnabled then identityCfg.passwordFile or null else null;

      passwordPath =
        if cfg.passwordFile != null then
          toString cfg.passwordFile
        else if identityPasswordPath != null then
          identityPasswordPath
        else
          "${stateDir}/password";

      localUser = if identityEnabled then identityCfg.username or cfg.localUser else cfg.localUser;

      driverPackType = lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Subdirectory name under the staged driver tree.";
          };
          url = lib.mkOption {
            type = lib.types.str;
            description = "fetchurl download URL (zip or vendor EXE with INF payload).";
          };
          sha256 = lib.mkOption {
            type = lib.types.str;
            description = "Nix sha256 of the download (nix-prefetch-url / SRI).";
          };
        };
      };

      driversTree =
        if cfg.drivers.enable && cfg.drivers.packs != [ ] then
          pkgs.callPackage ./pkgs/_windows-drivers.nix { packs = cfg.drivers.packs; }
        else
          null;

      syncLogin = pkgs.writeShellApplication {
        name = "dendritic-windows-sync-login";
        runtimeInputs = with pkgs; [
          coreutils
          util-linux
          gnused
          gawk
        ];
        excludeShellChecks = [
          "SC2086"
          "SC2016"
        ];
        text = builtins.readFile ./pkgs/_dendritic-windows-sync-login.sh;
      };

      stageDrivers = pkgs.writeShellApplication {
        name = "dendritic-windows-stage-drivers";
        runtimeInputs = with pkgs; [
          coreutils
          util-linux
          rsync
          findutils
          gnugrep
          gawk
          ntfs3g
        ];
        excludeShellChecks = [
          "SC2086"
          "SC2016"
        ];
        text = builtins.readFile ./pkgs/_dendritic-windows-stage-drivers.sh;
      };
    in
    {
      options.dendritic.windows = {
        enable = lib.mkEnableOption "Windows 11 IoT Enterprise LTSC dual-boot bootstrap + mounts";

        disk = lib.mkOption {
          type = lib.types.str;
          default = "/dev/disk/by-id/ata-Samsung_SSD_870_EVO_500GB_S62ANJ0R238724D";
          description = "Target disk by-id (stable).";
        };

        mountPoint = lib.mkOption {
          type = lib.types.str;
          default = "/mnt/windows";
          description = "Where the Windows NTFS volume is mounted from NixOS.";
        };

        installMountPoint = lib.mkOption {
          type = lib.types.str;
          default = "/mnt/wininstall";
          description = "Where the persistent Setup media (extracted ISO) is mounted.";
        };

        sizeGiB = lib.mkOption {
          type = lib.types.ints.positive;
          default = 64;
          description = "Windows partition size in GiB.";
        };

        installSizeGiB = lib.mkOption {
          type = lib.types.ints.positive;
          default = 8;
          description = "wininstall Setup-media partition size in GiB (extracted ISO + Autounattend).";
        };

        editionName = lib.mkOption {
          type = lib.types.str;
          # Eval Center fwlink ISO ships "Windows 11 Enterprise LTSC 2024 Evaluation"
          # (not an "IoT" substring in the WIM Name). Prefer non-N index via match order.
          default = "Enterprise LTSC";
          description = "WIM image Name substring matched by wimlib-imagex info.";
        };

        localUser = lib.mkOption {
          type = lib.types.str;
          default = "alex";
          description = "Local Windows administrator account (stamped into Autounattend).";
        };

        passwordFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = ''
            Plaintext password file for the Windows local account. When null and
            dendritic.identity is enabled, uses the pass-materialized
            dendritic.identity.passwordFile. Otherwise uses ${stateDir}/password
            (random on first boot).
          '';
        };

        syncLogin = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Stage a one-shot Windows Startup script that runs net user with the
            shared password (for the already-installed volume).
          '';
        };

        isoName = lib.mkOption {
          type = lib.types.str;
          default = defaultIsoName;
          description = "Filename under /var/cache/dendritic-windows/.";
        };

        isoSha256 = lib.mkOption {
          type = lib.types.str;
          default = defaultIsoSha256;
          description = "Expected SHA256 of the IoT Enterprise LTSC ISO (lowercase hex).";
        };

        isoUrl = lib.mkOption {
          type = lib.types.str;
          default = defaultIsoUrl;
          description = ''
            Microsoft download URL (default: Eval Center fwlink for IoT LTSC 2024
            x64). Bootstrap follows redirects and verifies isoSha256.
          '';
        };

        forceRedeploy = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Wipe/re-apply Windows even if install marker exists. Dangerous.";
        };

        autoBootstrap = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Run dendritic-windows-bootstrap.service after switch when not installed.";
        };

        autoReboot = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            After extracting Setup media to wininstall, reboot once via EFI
            BootNext into silent Windows Setup (no USB). Setup installs to the
            windows partition; FirstLogon then reboots back to systemd-boot.
            Retries (media already ready) do not auto-reboot.
          '';
        };

        drivers = {
          enable = lib.mkEnableOption "declarative Windows driver packs (C: + wininstall + FirstLogon)";

          packs = lib.mkOption {
            type = lib.types.listOf driverPackType;
            default = [ ];
            description = "Pinned fetchurl driver packs expanded into the staged INF tree.";
          };

          extraDir = lib.mkOption {
            type = lib.types.str;
            default = "${cacheDir}/drivers-extra";
            description = ''
              Optional host-local INF/zip tree merged at stage time (e.g. Intel Wi-Fi
              or MSI packs when CDN fetchurl is unavailable).
            '';
          };
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            boot.supportedFilesystems = [ "ntfs" ];
            boot.loader.timeout = lib.mkDefault 5;

            environment.systemPackages = [
              labelGpt
              bootstrap
              finalize
              continueSetup
              syncLogin
              stageDrivers
              pkgs.wimlib
              pkgs.ntfs3g
              pkgs.efibootmgr
            ]
            ++ lib.optional (driversTree != null) driversTree;

            # Clear legacy ext4 offline-shrink marker (superseded by nixinstall/disko).
            systemd.services.dendritic-windows-clear-legacy-shrink = {
              description = "Remove legacy pending-shrink marker from ESP";
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = pkgs.writeShellScript "clear-legacy-shrink" ''
                  rm -f /boot/dendritic-windows/pending-shrink
                  rm -f /var/lib/dendritic-windows/pending-shrink
                '';
              };
            };
            # /mnt/windows mount comes from disko.nix (PARTLABEL=windows, nofail).

            # wininstall is often a RO NTFS/fuse mount — do not force owner/mode on it.
            systemd.tmpfiles.rules = [
              "d ${stateDir} 0750 root root -"
              "d ${cacheDir} 0750 root root -"
              "d ${cfg.drivers.extraDir} 0750 root root -"
              "d ${cfg.mountPoint} 0755 root root -"
            ];

            # Ensure a password file exists before bootstrap (pass materialize or generated).
            systemd.services.dendritic-windows-ensure-password = {
              description = "Ensure Windows local-account password file exists";
              wantedBy = [ "multi-user.target" ];
              before = [
                "dendritic-windows-bootstrap.service"
                "dendritic-windows-sync-login.service"
              ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = pkgs.writeShellScript "dendritic-windows-ensure-password" ''
                  set -euo pipefail
                  pw=${lib.escapeShellArg passwordPath}
                  # Pass-materialized under $HOME: never mkdir/chown as root.
                  if [[ "$pw" == /home/* ]]; then
                    if [ -s "$pw" ]; then
                      exit 0
                    fi
                    echo "dendritic-windows: waiting for pass-materialized password at $pw" >&2
                    exit 1
                  fi
                  mkdir -p "$(dirname "$pw")"
                  if [ -s "$pw" ]; then
                    chmod 600 "$pw" 2>/dev/null || true
                    exit 0
                  fi
                  if [ -s /run/secrets/windows_local_password ]; then
                    cp /run/secrets/windows_local_password "$pw"
                    chmod 600 "$pw"
                    exit 0
                  fi
                  set +o pipefail
                  tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20 >"$pw"
                  set -o pipefail
                  chmod 600 "$pw"
                  echo "dendritic-windows: generated Windows password at $pw" >&2
                '';
              };
            };

            systemd.services.dendritic-windows-sync-login = lib.mkIf cfg.syncLogin {
              description = "Stage Windows Startup login password sync";
              wantedBy = [ "multi-user.target" ];
              after = [
                "local-fs.target"
                "dendritic-windows-ensure-password.service"
              ];
              wants = [ "dendritic-windows-ensure-password.service" ];
              unitConfig.ConditionPathExists = [
                "${cfg.mountPoint}/Windows"
                passwordPath
              ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = "${syncLogin}/bin/dendritic-windows-sync-login";
              };
              environment = {
                DENDRITIC_WINDOWS_MOUNT = cfg.mountPoint;
                DENDRITIC_WINDOWS_PASSWORD_FILE = passwordPath;
                DENDRITIC_WINDOWS_LOCAL_USER = localUser;
                DENDRITIC_WINDOWS_STATE = stateDir;
              };
            };

            systemd.services.dendritic-windows-stage-drivers =
              lib.mkIf (cfg.drivers.enable && driversTree != null)
                {
                  description = "Stage Windows drivers onto C: and wininstall";
                  wantedBy = [ "multi-user.target" ];
                  after = [ "local-fs.target" ];
                  serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                    TimeoutStartSec = "30m";
                    ExecStart = "${stageDrivers}/bin/dendritic-windows-stage-drivers";
                  };
                  environment = {
                    DENDRITIC_WINDOWS_MOUNT = cfg.mountPoint;
                    DENDRITIC_WINDOWS_INSTALL_MOUNT = cfg.installMountPoint;
                    DENDRITIC_WINDOWS_DRIVERS_SRC = "${driversTree}";
                    DENDRITIC_WINDOWS_DRIVERS_EXTRA = cfg.drivers.extraDir;
                    DENDRITIC_WINDOWS_STATE = stateDir;
                  };
                };

            # Harmless GPT/swap labeling so by-label swap works pre-bootstrap.
            systemd.services.dendritic-windows-label-gpt = {
              description = "Label GPT partitions for dendritic Windows dual-boot";
              wantedBy = [ "multi-user.target" ];
              after = [ "dendritic-windows-ensure-password.service" ];
              before = [ "dendritic-windows-bootstrap.service" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                Environment = [
                  "DENDRITIC_WINDOWS_DISK=${cfg.disk}"
                ];
                ExecStart = "${labelGpt}/bin/dendritic-windows-label-gpt";
              };
            };

            systemd.timers.dendritic-windows-bootstrap = lib.mkIf cfg.autoBootstrap {
              description = "Schedule first-run Windows IoT LTSC bootstrap";
              wantedBy = [ "timers.target" ];
              timerConfig = {
                OnBootSec = "90s";
                Persistent = true;
                Unit = "dendritic-windows-bootstrap.service";
              };
            };

            systemd.services.dendritic-windows-bootstrap = lib.mkIf cfg.autoBootstrap {
              description = "Bootstrap Windows 11 IoT LTSC via wininstall Setup media (idempotent)";
              after = [
                "dendritic-windows-label-gpt.service"
                "dendritic-windows-ensure-password.service"
                "local-fs.target"
                "network-online.target"
              ];
              wants = [
                "network-online.target"
                "dendritic-windows-ensure-password.service"
                "dendritic-windows-label-gpt.service"
              ];
              # Skip when finalize wrote installed (unless force).
              unitConfig = lib.mkIf (!cfg.forceRedeploy) {
                ConditionPathExists = "!${stateDir}/installed";
                StartLimitIntervalSec = 3600;
                StartLimitBurst = 5;
              };
              serviceConfig = {
                Type = "oneshot";
                TimeoutStartSec = "6h";
                # Oneshoot: timer re-triggers; avoid restart storm on shrink/reboot path.
                Restart = "no";
                ExecStart = "${bootstrap}/bin/dendritic-windows-bootstrap";
              };
              # Attrset form quotes values with spaces (edition name).
              environment = {
                DENDRITIC_WINDOWS_DISK = cfg.disk;
                DENDRITIC_WINDOWS_MOUNT = cfg.mountPoint;
                DENDRITIC_WINDOWS_INSTALL_MOUNT = cfg.installMountPoint;
                DENDRITIC_WINDOWS_SIZE_GIB = toString cfg.sizeGiB;
                DENDRITIC_WINDOWS_INSTALL_GIB = toString cfg.installSizeGiB;
                DENDRITIC_WINDOWS_EDITION_NAME = cfg.editionName;
                DENDRITIC_WINDOWS_CACHE = cacheDir;
                DENDRITIC_WINDOWS_STATE = stateDir;
                DENDRITIC_WINDOWS_UNATTEND_TEMPLATE = toString unattendTemplate;
                DENDRITIC_WINDOWS_PASSWORD_FILE = passwordPath;
                DENDRITIC_WINDOWS_LOCAL_USER = localUser;
                DENDRITIC_WINDOWS_ISO_SHA256 = cfg.isoSha256;
                DENDRITIC_WINDOWS_ISO_URL = cfg.isoUrl;
                DENDRITIC_WINDOWS_ISO_NAME = cfg.isoName;
                DENDRITIC_WINDOWS_FORCE = if cfg.forceRedeploy then "1" else "0";
                DENDRITIC_WINDOWS_AUTO_REBOOT = if cfg.autoReboot then "1" else "0";
                DENDRITIC_WINDOWS_ESP = "/boot";
                DENDRITIC_WINDOWS_DRIVERS_SRC = if driversTree != null then "${driversTree}" else "";
              };
            };

            # Resume specialize via WBM. Timer-only — never WantedBy multi-user or
            # os-switch gets SIGTERM mid-activation and the system profile sticks
            # on an old generation (seen repeatedly after BootNext).
            systemd.timers.dendritic-windows-continue-setup = {
              description = "Schedule Windows Setup continue (WBM BootNext)";
              wantedBy = [ "timers.target" ];
              timerConfig = {
                OnBootSec = "3min";
                Unit = "dendritic-windows-continue-setup.service";
              };
            };

            systemd.services.dendritic-windows-continue-setup = {
              description = "Continue in-progress Windows Setup via Windows Boot Manager";
              after = [
                "local-fs.target"
                "dendritic-windows-label-gpt.service"
              ];
              before = [ "dendritic-windows-bootstrap.service" ];
              unitConfig = lib.mkIf (!cfg.forceRedeploy) {
                # Both must be absent (NixOS emits one ConditionPathExists= per list entry).
                ConditionPathExists = [
                  "!${stateDir}/installed"
                  "!${cfg.mountPoint}/dendritic-windows-ready"
                ];
              };
              serviceConfig = {
                Type = "oneshot";
                TimeoutStartSec = "2m";
                Restart = "no";
                ExecStart = "${continueSetup}/bin/dendritic-windows-continue-setup";
              };
              environment = {
                DENDRITIC_WINDOWS_MOUNT = cfg.mountPoint;
                DENDRITIC_WINDOWS_STATE = stateDir;
                DENDRITIC_WINDOWS_AUTO_REBOOT = if cfg.autoReboot then "1" else "0";
              };
            };

            systemd.services.dendritic-windows-finalize = {
              description = "Mark Windows installed; clear BootNext after silent Setup";
              wantedBy = [ "multi-user.target" ];
              after = [ "local-fs.target" ];
              unitConfig = {
                ConditionPathExists = "${cfg.mountPoint}/dendritic-windows-ready";
              };
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                Environment = [
                  "DENDRITIC_WINDOWS_MOUNT=${cfg.mountPoint}"
                ];
                ExecStart = "${finalize}/bin/dendritic-windows-finalize";
              };
            };
          }
        ]
      );
    };
}
