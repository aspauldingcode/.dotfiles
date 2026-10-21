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
      dendritic = pkgs.callPackage ../crates/dendritic/_package.nix { };
      # Letters toggle the built-in quirk bit (set if clear). These devices
      # enumerate with quirks=0x0 on 7.2.10, so each letter enables one:
      # b RESET_RESUME, g DELAY_INIT, k NO_LPM, o HUB_SLOW_RESET.
      # 1a40:0801 is the Terminus hub stuck in full-speed "[Safe]" mode
      # (bDeviceProtocol 00). Slow reset on its parent 0bda:5411 is what
      # lengthens the chirp window. 05e3:0610 is the Genesys chain whose
      # ports die with EPROTO -71.
      usbCoreQuirks = "0bda:5411:bko,0bda:0411:k,1a40:0101:bgko,1a40:0801:bgko,05e3:0610:bko,05e3:0620:k";
      # Apple Watch cable 05ac:0503 advertises HID report_size 32768 and
      # hid-generic rejects it (-22). IGNORE (0x4) skips the driver; VBUS
      # charging does not need HID.
      usbHidQuirks = "0x05ac:0x0503:0x4";
      usbHubRecover = pkgs.writeShellScript "dendritic-usb-hub-recover" ''
        set -eu
        devpath="''${1:-}"
        [ -n "$devpath" ] || exit 0
        name=$(${pkgs.coreutils}/bin/basename "$devpath")
        ${pkgs.coreutils}/bin/mkdir -p /run
        exec 9>/run/dendritic-usb-hub-recover.lock
        ${pkgs.util-linux}/bin/flock -w 20 9 || exit 0
        stamp=/run/dendritic-usb-hub-recover.stamp
        now=$(${pkgs.coreutils}/bin/date +%s)
        if [ -f "$stamp" ]; then
          then_=$(${pkgs.coreutils}/bin/stat -c %Y "$stamp")
          if [ $((now - then_)) -lt 15 ]; then
            exit 0
          fi
        fi
        ${pkgs.coreutils}/bin/touch "$stamp"
        ${pkgs.coreutils}/bin/sleep 3
        if [ -e "/sys/bus/usb/devices/$name/idVendor" ]; then
          exit 0
        fi
        cur=$name
        while true; do
          case "$cur" in
            *.*)
              parent="''${cur%.*}"
              port="''${cur##*.}"
              ;;
            *-*)
              parent="usb''${cur%%-*}"
              port="''${cur##*-}"
              ;;
            *)
              exit 0
              ;;
          esac
          portdir=""
          for d in /sys/bus/usb/devices/"$parent"/*/"$parent"-port"$port" \
                   /sys/bus/usb/devices/"$parent"/*/*-port"$port"; do
            if [ -w "$d/disable" ]; then
              portdir=$d
              break
            fi
          done
          if [ -n "$portdir" ]; then
            # 1 cuts VBUS (hubs that support it) and disconnects the port.
            # 0 enables it again. End enabled.
            echo 1 >"$portdir/disable" || true
            ${pkgs.coreutils}/bin/sleep 0.5
            echo 0 >"$portdir/disable" || true
            exit 0
          fi
          case "$parent" in
            usb*) exit 0 ;;
          esac
          cur=$parent
        done
      '';
      powerd = pkgs.writeShellApplication {
        name = "dendritic-powerd";
        text = ''
          exec ${lib.getExe dendritic} power "$@"
        '';
      };
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
              "usbcore.quirks=${usbCoreQuirks}"
              "usbhid.quirks=${usbHidQuirks}"
              # Touchpad / sensor I2C: reduce designware timeout storms around s2idle.
              "i2c_designware.timeout_ms=5000"
            ];

            boot.blacklistedKernelModules = lib.mkIf cfg.blacklistUnusedXe [ "xe" ];

            # usbcore.quirks is read on each new enumeration. Write it at
            # activation so a later port bounce picks it up before reboot.
            system.activationScripts.dendritic-usb-hub-quirks.text = ''
              quirks=/sys/module/usbcore/parameters/quirks
              if [ -w "$quirks" ]; then
                printf '%s' '${usbCoreQuirks}' >"$quirks" || true
              fi
            '';

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

              # Dock hubs: Realtek RTS5411, Terminus FE1.1 safe-mode, Genesys GL3523.
              # Hardware LPM is separate from usbcore.autosuspend and wedges TTs.
              ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="5411", TEST=="power/usb2_hardware_lpm", ATTR{power/usb2_hardware_lpm}="0"
              ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="0411", TEST=="power/usb2_hardware_lpm", ATTR{power/usb2_hardware_lpm}="0"
              ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="1a40", ATTR{idProduct}=="0801", TEST=="power/usb2_hardware_lpm", ATTR{power/usb2_hardware_lpm}="0"
              ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="1a40", ATTR{idProduct}=="0101", TEST=="power/usb2_hardware_lpm", ATTR{power/usb2_hardware_lpm}="0"
              ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="05e3", ATTR{idProduct}=="0610", TEST=="power/usb2_hardware_lpm", ATTR{power/usb2_hardware_lpm}="0"
              ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="05e3", ATTR{idProduct}=="0620", TEST=="power/usb2_hardware_lpm", ATTR{power/usb2_hardware_lpm}="0"

              # Hub dropped off the bus (EPROTO -71 / connect-debounce failed).
              # Kernel uevent PRODUCT is unpadded lowercase hex.
              ACTION=="remove", SUBSYSTEM=="usb", ENV{PRODUCT}=="bda/5411/*", RUN+="${pkgs.systemd}/bin/systemd-run --collect --no-block --quiet ${usbHubRecover} %E{DEVPATH}"
              ACTION=="remove", SUBSYSTEM=="usb", ENV{PRODUCT}=="1a40/801/*", RUN+="${pkgs.systemd}/bin/systemd-run --collect --no-block --quiet ${usbHubRecover} %E{DEVPATH}"
              ACTION=="remove", SUBSYSTEM=="usb", ENV{PRODUCT}=="5e3/610/*", RUN+="${pkgs.systemd}/bin/systemd-run --collect --no-block --quiet ${usbHubRecover} %E{DEVPATH}"
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
                ExecStart = "${lib.getExe dendritic} power";
                Restart = "always";
                RestartSec = 2;
              };
            };
          }
        ]
      );
    };

}
