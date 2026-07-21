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
            ];

            boot.blacklistedKernelModules = lib.mkIf cfg.blacklistUnusedXe [ "xe" ];

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
            services.logind.settings.Login = {
              HandleLidSwitch = "suspend";
              HandleLidSwitchExternalPower = "suspend";
              HandleLidSwitchDocked = "ignore";
            };

            # NVIDIA resume reliability with systemd >= 256
            systemd.services.systemd-suspend.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
            systemd.services.systemd-hibernate.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
            systemd.services.systemd-hybrid-sleep.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";

            # ── Runtime PM: Realtek NIC + SATA ALPM + USB/xHCI keep-awake ──
            services.udev.extraRules = ''
              # RTL8168: allow runtime suspend when link is down; disable WOL
              ACTION=="add|change", SUBSYSTEM=="pci", ATTR{vendor}=="0x10ec", ATTR{device}=="0x8168", ATTR{power/control}="auto"
              ACTION=="add|change", SUBSYSTEM=="net", KERNEL=="enp2s0", RUN+="${pkgs.ethtool}/bin/ethtool -s %k wol d"
              # SATA ALPM — only hosts that expose the sysfs attribute (avoids ENOTSUP noise).
              ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", TEST=="link_power_management_policy", ATTR{link_power_management_policy}="med_power_with_dipm"

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
