# dendritic.power — quiet-first laptop power automation (feedback controller).
#
# Sole owner of RAPL PL1/PL2, EPP, and intel_pstate max_perf_pct.
# Do not enable auto-cpufreq / TLP / power-profiles-daemon alongside this.
{
  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.power;
      powerd = pkgs.writers.writePython3Bin "dendritic-powerd" {
        libraries = [ ];
        flakeIgnore = [
          "E501"
          "W503"
          "E265"
          "E402"
        ];
      } (builtins.readFile ./pkgs/_dendritic-powerd.py);
    in
    {
      options.dendritic.power = {
        enable = lib.mkEnableOption "dendritic quiet-first power automation (RAPL/EPP feedback controller)";

        suspendOnIdleSeconds = lib.mkOption {
          type = lib.types.ints.positive;
          default = 900;
          description = "Seconds of idle before systemctl suspend (swayidle); HM niri wires this.";
        };

        blacklistUnusedXe = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Blacklist the unused `xe` DRM module when i915 is the active Intel
            driver (Tiger Lake / this host). Disable on newer Intel iGPU hosts
            that need xe.
          '';
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            assertions = [
              {
                assertion = !(config.services.tlp.enable or false);
                message = "dendritic.power conflicts with services.tlp — disable TLP.";
              }
              {
                assertion = !(config.services.power-profiles-daemon.enable or false);
                message = "dendritic.power conflicts with power-profiles-daemon — disable PPD.";
              }
              {
                assertion = !(config.services.auto-cpufreq.enable or false);
                message = "dendritic.power owns EPP/RAPL — disable services.auto-cpufreq.";
              }
              {
                assertion = !(config.zramSwap.enable or false);
                message = "dendritic.power uses boot.zswap — disable zramSwap (no double compression).";
              }
            ];

            # ── Kernel / ASPM / sleep (Sword 15 Tiger Lake) ──
            # deep (S3) resume breaks the TB4 xHCI at 00:0d.0:
            #   xHC error in resume, USBSTS 0x401, Reinit
            #   usb usb4-port6: Cannot enable. Maybe the USB cable is bad?
            # That "bad cable" line is a kernel red herring (known on TGL TB4
            # 8086:9a13/9a17) — the controller failed restore, not the cable.
            # s2idle avoids the S3 power-loss path that triggers the reinit.
            # Quiet CPU policy stays in RAPL/EPP (powerd), not ASPM.
            boot.kernelParams = [
              "intel_pstate=active"
              "mem_sleep_default=s2idle"
              "pcie_aspm.policy=default"
              "usbcore.autosuspend=-1"
              # Touchpad / sensor I2C: reduce designware timeout storms around s2idle.
              "i2c_designware.timeout_ms=5000"
            ];

            boot.blacklistedKernelModules = lib.mkIf cfg.blacklistUnusedXe [ "xe" ];

            # Fail loud if a generation regresses to deep S3 (breaks TB4 xHCI here).
            system.activationScripts."dendritic-s2idle-guard".text = ''
              if [ -r /sys/power/mem_sleep ]; then
                mem_sleep="$(${pkgs.coreutils}/bin/cat /sys/power/mem_sleep)"
                case "$mem_sleep" in
                  *'[s2idle]'*) ;;
                  *)
                    echo "WARNING: dendritic.power expected [s2idle] in /sys/power/mem_sleep, got: $mem_sleep" >&2
                    ;;
                esac
              fi
            '';

            # ── Memory ladder (macOS-like): zswap → disk swap → oomd ──
            boot.zswap = {
              enable = true;
              compressor = "lz4";
              zpool = "zsmalloc";
              maxPoolPercent = 30;
              shrinkerEnabled = true;
            };

            boot.kernel.sysctl = {
              # Start at 60; powerd may raise to 80 when zswap is healthy + IO PSI low.
              "vm.swappiness" = 60;
              "vm.page-cluster" = 0;
              "vm.vfs_cache_pressure" = 50;
            };

            # Reduce metadata write heat on the SATA root.
            fileSystems."/".options = lib.mkAfter [ "noatime" ];

            services.fstrim.enable = true;

            # ── Thermals: thermald = emergency; powerd = comfort ──
            services.thermald.enable = true;

            services.upower.enable = true;

            systemd.oomd = {
              enable = true;
              enableUserSlices = true;
              settings.OOM.DefaultMemoryPressureLimit = "70%";
            };

            powerManagement.enable = true;
            powerManagement.powertop.enable = false;

            # ── Lid → suspend (AC and battery); ignore when docked externally ──
            # InhibitDelayMaxSec: swayidle before-sleep must finish locking before
            # logind forces sleep (default 5s is too short for gtklock CSS + start).
            services.logind.settings.Login = {
              HandleLidSwitch = "suspend";
              HandleLidSwitchExternalPower = "suspend";
              HandleLidSwitchDocked = "ignore";
              InhibitDelayMaxSec = 45;
            };
            # Ensure logind picks up InhibitDelayMaxSec on switch (not only reboot).
            systemd.services.systemd-logind.restartTriggers = [
              (toString config.services.logind.settings.Login.InhibitDelayMaxSec)
            ];

            # NVIDIA resume reliability with systemd >= 256
            systemd.services.systemd-suspend.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
            systemd.services.systemd-hibernate.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
            systemd.services.systemd-hybrid-sleep.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";

            # ── Runtime PM: Realtek NIC + USB/xHCI keep-awake ──
            # SATA ALPM dropped: host0/host1 expose link_power_management_policy
            # but reject med_power_with_dipm (ENOTSUP spam every boot).
            services.udev.extraRules = ''
              # RTL8168: allow runtime suspend when link is down; disable WOL
              ACTION=="add|change", SUBSYSTEM=="pci", ATTR{vendor}=="0x10ec", ATTR{device}=="0x8168", ATTR{power/control}="auto"
              ACTION=="add|change", SUBSYSTEM=="net", KERNEL=="enp2s0", RUN+="${pkgs.ethtool}/bin/ethtool -s %k wol d"

              # Tiger Lake-H: keep both xHCI controllers awake across suspend.
              # 8086:9a17 = TB4 USB (00:0d.0) — source of USBSTS 0x401 reinit storms
              # 8086:43ed = USB 3.2 xHCI (00:14.0)
              ACTION=="add|change", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x9a17", TEST=="power/control", ATTR{power/control}="on"
              ACTION=="add|change", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x43ed", TEST=="power/control", ATTR{power/control}="on"

              # Root hubs + external hubs: never autosuspend (dock/kbd vanish on resume).
              ACTION=="add|change", SUBSYSTEM=="usb", KERNEL=="usb[0-9]*", TEST=="power/control", ATTR{power/control}="on"
              ACTION=="add|change", SUBSYSTEM=="usb", ATTR{bDeviceClass}=="09", TEST=="power/control", ATTR{power/control}="on"

              # HID (keyboard/mouse) stay powered — needed for gtklock after resume.
              ACTION=="add|change", SUBSYSTEM=="usb", ENV{ID_USB_INTERFACES}=="*:0301*:*", TEST=="power/control", ATTR{power/control}="on"
              ACTION=="add|change", SUBSYSTEM=="usb", ENV{ID_USB_INTERFACES}=="*:0302*:*", TEST=="power/control", ATTR{power/control}="on"
            '';

            # Resume: power-cycle sticky usb4-port6 ("bad cable" red herring on TGL).
            # Pre: best-effort unmount external disks (e.g. WD easystore) to avoid
            # Buffer I/O errors when the drive vanishes across s2idle.
            environment.etc."systemd/system-sleep/dendritic-power-sleep" = {
              mode = "0755";
              text = ''
                #!${pkgs.runtimeShell}
                set -eu
                port6_disable() {
                  # USB 3.2 xHCI (00:14.0) port6 — lid/dock physical location.
                  for d in /sys/devices/pci0000:00/0000:00:14.0/usb4/*/usb4-port6/disable \
                           /sys/bus/usb/devices/usb4/*/usb4-port6/disable; do
                    if [ -w "$d" ]; then
                      echo "$1" >"$d" || true
                      return 0
                    fi
                  done
                  # Fallback: any usb4-port6 on the system.
                  for d in /sys/bus/usb/devices/*/usb4-port6/disable; do
                    if [ -w "$d" ]; then
                      echo "$1" >"$d" || true
                      return 0
                    fi
                  done
                  return 0
                }
                case "$1" in
                  pre)
                    # Sync + unmount non-root removable mounts (WD easystore, etc.).
                    ${pkgs.util-linux}/bin/findmnt -nlo TARGET,FSTYPE,SOURCE -t ext4,ntfs,vfat,exfat,btrfs 2>/dev/null \
                      | while read -r target fstype source; do
                          case "$target" in
                            /|/nix|/boot|/boot/*|/var|/var/*|/home|/home/*|/usr|/usr/*|/tmp|/tmp/*) continue ;;
                          esac
                          case "$source" in
                            /dev/sd[b-z]*|/dev/sd[b-z][0-9]*|/dev/nvme[1-9]*|/dev/mapper/*)
                              ${pkgs.util-linux}/bin/umount -l "$target" 2>/dev/null || true
                              ;;
                          esac
                        done
                    ${pkgs.coreutils}/bin/sync || true
                    ;;
                  post)
                    port6_disable 0
                    ${pkgs.coreutils}/bin/sleep 0.3
                    port6_disable 1
                    ;;
                esac
              '';
            };

            environment.systemPackages = with pkgs; [
              powerd
              (writeShellScriptBin "dendritic-power" ''
                exec ${lib.getExe powerd} --status
              '')
              powertop
              nvtopPackages.nvidia
              lm_sensors
              config.boot.kernelPackages.turbostat
              iw
              ethtool
            ];

            systemd.tmpfiles.rules = [
              "d /run/dendritic-power 0755 root root -"
              "d /var/lib/dendritic-power 0755 root root -"
            ];

            systemd.services.dendritic-powerd = {
              description = "Dendritic acoustic/thermal feedback controller";
              wantedBy = [ "multi-user.target" ];
              after = [
                "multi-user.target"
                "systemd-udev-settle.service"
              ];
              path = with pkgs; [
                coreutils
                iw
              ];
              serviceConfig = {
                Type = "simple";
                # RAPL / intel_pstate / backlight sysfs writes require root.
                User = "root";
                ExecStart = "${lib.getExe powerd}";
                Restart = "always";
                RestartSec = 2;
              };
            };
          }
        ]
      );
    };

}
