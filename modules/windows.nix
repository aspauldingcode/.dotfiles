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
      offlineShrinkScript = ./pkgs/_dendritic-windows-offline-shrink.sh;

      labelGpt = pkgs.writeShellApplication {
        name = "dendritic-windows-label-gpt";
        runtimeInputs = with pkgs; [
          gptfdisk
          util-linux
          parted
          e2fsprogs
        ];
        excludeShellChecks = [
          "SC2086"
          "SC2046"
          "SC2034"
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

      passwordPath =
        if cfg.passwordFile != null then toString cfg.passwordFile else "${stateDir}/password";
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
          default = "IoT Enterprise LTSC";
          description = "WIM image Name substring matched by wimlib-imagex info.";
        };

        localUser = lib.mkOption {
          type = lib.types.str;
          default = "alex";
          description = "Local Windows administrator account (must match unattend template).";
        };

        passwordFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = ''
            Plaintext password file for the Windows local account. When null,
            uses ${stateDir}/password (auto-created with a random password on
            first boot). Optionally copy from sops into that path yourself.
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
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            boot.supportedFilesystems = [ "ntfs" ];
            boot.loader.timeout = lib.mkDefault 5;

            # Offline ext4 shrink must run before sysroot.mount (root is still unmounted).
            boot.initrd.systemd.enable = true;
            boot.initrd.systemd.storePaths = [
              "${pkgs.e2fsprogs}/bin/e2fsck"
              "${pkgs.e2fsprogs}/bin/resize2fs"
              "${pkgs.parted}/bin/parted"
              "${pkgs.gptfdisk}/bin/sgdisk"
              "${pkgs.util-linux}/bin/mkswap"
              "${pkgs.coreutils}/bin/cat"
              "${pkgs.coreutils}/bin/mkdir"
              "${pkgs.coreutils}/bin/rm"
              "${pkgs.coreutils}/bin/sync"
              "${pkgs.coreutils}/bin/basename"
              "${pkgs.bash}/bin/bash"
              "${pkgs.util-linux}/bin/mount"
              "${pkgs.util-linux}/bin/umount"
            ];
            boot.initrd.systemd.services.dendritic-windows-offline-shrink = {
              description = "Dendritic offline root shrink for Windows dual-boot";
              wantedBy = [ "initrd.target" ];
              after = [ "systemd-udev-settle.service" ];
              before = [ "sysroot.mount" ];
              unitConfig = {
                DefaultDependencies = false;
              };
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                StandardOutput = "journal+console";
                ExecStart = pkgs.writeShellScript "dendritic-windows-offline-shrink-initrd" ''
                  set -euo pipefail
                  export PATH="${pkgs.e2fsprogs}/bin:${pkgs.parted}/bin:${pkgs.gptfdisk}/bin:${pkgs.util-linux}/bin:${pkgs.coreutils}/bin''${PATH:+:$PATH}"
                  exec ${pkgs.bash}/bin/bash ${offlineShrinkScript}
                '';
              };
            };

            environment.systemPackages = [
              labelGpt
              bootstrap
              finalize
              pkgs.wimlib
              pkgs.ntfs3g
              pkgs.efibootmgr
            ];

            # /mnt/windows mount comes from disko.nix (PARTLABEL=windows, nofail).

            systemd.tmpfiles.rules = [
              "d ${stateDir} 0750 root root -"
              "d ${cacheDir} 0750 root root -"
              "d ${cfg.mountPoint} 0755 root root -"
              "d ${cfg.installMountPoint} 0755 root root -"
            ];

            # Ensure a password file exists before bootstrap (sops or generated).
            systemd.services.dendritic-windows-ensure-password = {
              description = "Ensure Windows local-account password file exists";
              wantedBy = [ "multi-user.target" ];
              before = [ "dendritic-windows-bootstrap.service" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = pkgs.writeShellScript "dendritic-windows-ensure-password" ''
                  set -euo pipefail
                  pw=${lib.escapeShellArg passwordPath}
                  mkdir -p "$(dirname "$pw")"
                  if [ ! -s "$pw" ]; then
                    if [ -s /run/secrets/windows_local_password ]; then
                      cp /run/secrets/windows_local_password "$pw"
                    else
                      # pipefail + head closing early makes tr exit 141; disable for this line.
                      set +o pipefail
                      tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20 >"$pw"
                      set -o pipefail
                      echo "dendritic-windows: generated Windows password at $pw" >&2
                    fi
                    chmod 600 "$pw"
                  fi
                '';
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
                DENDRITIC_WINDOWS_ISO_SHA256 = cfg.isoSha256;
                DENDRITIC_WINDOWS_ISO_URL = cfg.isoUrl;
                DENDRITIC_WINDOWS_ISO_NAME = cfg.isoName;
                DENDRITIC_WINDOWS_FORCE = if cfg.forceRedeploy then "1" else "0";
                DENDRITIC_WINDOWS_AUTO_REBOOT = if cfg.autoReboot then "1" else "0";
                DENDRITIC_WINDOWS_ESP = "/boot";
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
