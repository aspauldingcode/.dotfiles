# Cold-boot speedups that do not replace AMI / flash SPI.
#
# Measured sliceanddice (AMI + systemd-boot + SATA):
#   9.6s firmware + 2.1s loader + 2.0s kernel + 2.9s initrd + 34.6s userspace
# graphical.target was blocked by:
#   • home-manager-*.service Before=systemd-user-sessions (~23s)
#   • greetd Type=idle (waits for every other boot job)
#   • NetworkManager-wait-online (6s) — niri does not need a carrier
#
# Firmware flash / coreboot is not in scope (no MS-1582 port; brick risk).
# UKI is skipped: 512M ESP × generationLimit cannot hold kernel+initrd UKIs.
{
  flake.modules.nixos.dendritic =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.bootSpeed;
      hmUsers = if config ? home-manager then lib.attrNames (config.home-manager.users or { }) else [ ];
      autologinUser =
        if config.dendritic.identity.enable or false then config.dendritic.identity.username else cfg.user;
    in
    {
      options.dendritic.bootSpeed = {
        enable = lib.mkEnableOption "fast cold boot: autologin, unblock HM/NM, defer heavy daemons";

        user = lib.mkOption {
          type = lib.types.str;
          default = "alex";
          description = "Session user when dendritic.identity is off.";
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            assertions = [
              {
                assertion = !(config.dendritic.bootTheme.enable or false);
                message = "dendritic.bootSpeed conflicts with dendritic.bootTheme (GRUB timeout + Plymouth).";
              }
            ];

            boot.loader.timeout = lib.mkDefault 0;
            boot.plymouth.enable = lib.mkDefault false;

            # systemd in initrd is nixpkgs default; keep it explicit.
            boot.initrd.systemd.enable = true;
            boot.initrd.checkJournalingFS = false;

            # iTCO / NMI watchdog probe + redundant i915 modeset.
            boot.kernelParams = lib.mkAfter [
              "nowatchdog"
              "nmi_watchdog=0"
              "i915.fastboot=1"
            ];

            # Sword has CNVi Wi-Fi only — no WWAN. NM still pulls ModemManager.
            networking.modemmanager.enable = lib.mkForce false;
            # Discover LAN printers on first print, not at boot.
            services.printing.startWhenNeeded = true;
            services.printing.browsed.enable = false;
            # Adapter stays available; blueman can power it when used.
            hardware.bluetooth.powerOnBoot = lib.mkForce false;
            services.speechd.enable = false;

            systemd.services = lib.mkMerge (
              [
                (lib.mkIf (config.networking.networkmanager.enable or false) {
                  NetworkManager-wait-online.enable = false;
                })
                (lib.mkIf (config.systemd.network.enable or false) {
                  systemd-networkd-wait-online.enable = false;
                })
              ]
              ++ map (user: {
                # WantedBy + After the same target: pulled in, does not delay boot.
                "home-manager-${user}" = {
                  after = lib.mkForce [
                    "multi-user.target"
                    "nix-daemon.socket"
                  ];
                  before = lib.mkForce [ ];
                  wantedBy = lib.mkForce [ "multi-user.target" ];
                };
              }) hmUsers
            );
          }

          (lib.mkIf (config.dendritic.apps.niri.enable or false) {
            dendritic.apps.niri.autologinUser = lib.mkDefault autologinUser;
          })

          (lib.mkIf (config.services.ollama.enable or false) {
            systemd.services.ollama = {
              wantedBy = lib.mkForce [ "graphical.target" ];
              after = lib.mkForce [ "graphical.target" ];
            };
          })

          (lib.mkIf (config.dendritic.local-ai.llamaCpp.enable or false) {
            systemd.services.dendritic-llama-cpp = {
              wantedBy = lib.mkForce [ "graphical.target" ];
              after = lib.mkForce [ "graphical.target" ];
            };
          })
        ]
      );
    };
}
