# Silicon Motion InstantView
#
# Darwin: `pkgs.macos-instantview` (overlaid from nixpkgs-unstable →
# 3.24R0004 / nixpkgs#530053). 26.05 still carries 3.22R0002.
#
# Linux: vendored package under ./instantview-linux/pkg (mirrors the
# in-progress nixpkgs packaging) until upstream lands.
#
# GC note (Darwin): with `targets.darwin.linkApps`, Launch Services writes
# `com.apple.macl` onto the store `.app`. That xattr makes
# `nix store gc`'s pre-delete `fchmodat` fail with EPERM
# (NixOS/nix#6765). Darwin activation strips it (see below);
# overlay also clears quarantine/macl at build time.
{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      ...
    }:
    {
      config = lib.mkIf pkgs.stdenv.isDarwin {
        home.packages = [ pkgs.macos-instantview ];

        home.activation.stripInstantViewMacl = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          app="${pkgs.macos-instantview}/Applications/macOS InstantView.app"
          if [ -d "$app" ]; then
            /usr/bin/xattr -d com.apple.macl "$app" 2>/dev/null || true
          fi
        '';
      };
    };

  flake.modules.darwin.dendritic =
    {
      lib,
      ...
    }:
    {
      system.activationScripts.postActivation.text = lib.mkAfter ''
        echo "  🧹 Stripping com.apple.macl from nix-store .app bundles (GC hygiene)..." >&2
        for app in /nix/store/*/Applications/*.app; do
          [ -d "$app" ] || continue
          /usr/bin/xattr -d com.apple.macl "$app" 2>/dev/null || true
        done
      '';
    };

  # Inline NixOS InstantView wiring (do not place a bare NixOS module under
  # modules/ — auto-import treats every non-default.nix as flake-parts).
  flake.modules.nixos.dendritic =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.dendritic.apps.instantview.linux.enable = lib.mkEnableOption ''
        Silicon Motion SM76x InstantView on Linux (EVDI + SMIUSBDisplayManager).
        Uses the vendored package under modules/apps/instantview-linux/pkg
      '';

      config = lib.mkIf config.dendritic.apps.instantview.linux.enable (
        let
          evdi = config.boot.kernelPackages.evdi;
          instantview = pkgs.callPackage ./instantview-linux/pkg { inherit evdi; };
        in
        {
          nixpkgs.overlays = [
            (final: prev: {
              instantview = final.callPackage ./instantview-linux/pkg {
                inherit (final.linuxPackages) evdi;
              };
            })
          ];

          boot.extraModulePackages = [ evdi ];
          boot.kernelModules = [ "evdi" ];
          # One virtual DRM card is enough for a single SM76x panel; 4 caused
          # niri MESA/renderer probe spam and idle GPU noise at every login.
          boot.extraModprobeConfig = ''
            options evdi initial_device_count=1
          '';

          services.udev.packages = [ instantview ];
          # Package rules SYSTEMD_WANTS=instantview on add; stop on unplug so the
          # proprietary manager is not always-on (~15–20% CPU when idle).
          services.udev.extraRules = ''
            ACTION=="remove", SUBSYSTEM=="usb", ENV{PRODUCT}=="90c/*", \
              RUN+="${pkgs.systemd}/bin/systemctl --no-block stop instantview.service"
          '';

          # Proprietary manager hardcodes /opt/siliconmotion for firmware.
          systemd.tmpfiles.rules =
            let
              fw = "${instantview}/lib/instantview";
            in
            [
              "d /opt 0755 root root -"
              "d /opt/siliconmotion 0755 root root -"
              "d /opt/siliconmotion/pic 0755 root root -"
              "L+ /opt/siliconmotion/Bootloader0.bin - - - - ${fw}/Bootloader0.bin"
              "L+ /opt/siliconmotion/Bootloader1.bin - - - - ${fw}/Bootloader1.bin"
              "L+ /opt/siliconmotion/firmware0.bin - - - - ${fw}/firmware0.bin"
              "L+ /opt/siliconmotion/USBDisplay.bin - - - - ${fw}/USBDisplay.bin"
              "L+ /opt/siliconmotion/USBDisplay770.bin - - - - ${fw}/USBDisplay770.bin"
            ];

          environment.etc."X11/xorg.conf.d/40-instantview.conf" = lib.mkIf config.services.xserver.enable {
            text = ''
              Section "OutputClass"
                Identifier  "InstantView"
                MatchDriver "evdi"
                Driver      "modesetting"
                Option      "TearFree" "true"
                Option      "AccelMethod" "none"
              EndSection
            '';
          };

          # Started via udev SYSTEMD_WANTS on Silicon Motion USB plug (see
          # instantview-linux/pkg/99-instantview.rules); stopped on unplug above.
          # No WantedBy=multi-user — keeps the manager off when the panel is absent.
          systemd.services.instantview = {
            description = "Silicon Motion InstantView USB Display Manager";
            after = [
              "systemd-tmpfiles-setup.service"
              "systemd-udev-settle.service"
              "modprobe@evdi.service"
            ];
            wants = [ "modprobe@evdi.service" ];

            serviceConfig = {
              Type = "simple";
              # Prefer current-system so a switch without reboot can still load
              # newly added out-of-tree modules (booted-system lags until reboot).
              ExecStartPre = "${pkgs.kmod}/bin/modprobe -d /run/current-system/kernel-modules evdi";
              ExecStart = "${instantview}/bin/SMIUSBDisplayManager";
              WorkingDirectory = "/opt/siliconmotion";
              # on-failure: clean stop on unplug must not respawn forever.
              Restart = "on-failure";
              RestartSec = 5;
              # Proprietary manager ignores SIGTERM; don't block udev/switch for 90s.
              TimeoutStopSec = 8;
              KillMode = "control-group";
              FinalKillSignal = "SIGKILL";
              LogsDirectory = "instantview";
            };
          };
        }
      );
    };
}
