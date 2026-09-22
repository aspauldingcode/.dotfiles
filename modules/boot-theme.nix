# Themed EFI boot + silent splash.
#
# systemd-boot cannot show a wallpaper, a Base16 palette, a clock, or power
# entries — its menu is a text EFI console. Customising loader entries does
# not restyle that UI and is unrelated to generation rollback.
#
# GRUB EFI is the first-class NixOS path that can do all of:
#   • packaged Stylix wallpaper + palette (same seed as gtkgreet)
#   • timeout clock + hostname title
#   • Windows / firmware setup / reboot / shutdown
#   • generation rollback via "NixOS - All configurations" + configurationLimit
#
# Switching bootloaders does not discard profiles. install-grub.pl rewrites
# grub.cfg from /nix/var/nix/profiles/system-*-link: current generation on
# top, rollback in "NixOS - All configurations".
#
# This AMI ignores BootOrder and keeps leftover Linux Boot Manager first.
# Stock NixOS answer when NVRAM is sticky: efiInstallAsRemovable (writes
# EFI/BOOT/BOOTX64.EFI with a correct GRUB prefix) and canTouchEfiVariables
# off (they are mutually exclusive). extraInstallCommands then deletes the
# systemd-boot NVRAM entry and parks the binary under EFI/dendritic-fallback.
{
  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.bootTheme;
      colors = config.lib.stylix.colors;
      fonts = config.stylix.fonts;

      grubTheme = pkgs.callPackage ./pkgs/_dendritic-grub-theme.nix {
        inherit colors fonts;
        hostName = config.networking.hostName;
        wallpaper = config.stylix.image or null;
      };

      plymouthTheme = pkgs.callPackage ./pkgs/_dendritic-plymouth-theme.nix {
        inherit colors;
      };

      grubEfiFirst = pkgs.writeShellApplication {
        name = "dendritic-grub-efi-first";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.efibootmgr
          pkgs.gnused
        ];
        text = builtins.readFile ./pkgs/_dendritic-grub-efi-first.sh;
      };

      extraEntries = lib.concatStringsSep "\n" (
        [
          ''
            menuentry "Windows" --class windows {
              insmod part_gpt
              insmod fat
              insmod chain
              search --no-floppy --set=root --file /EFI/Microsoft/Boot/bootmgfw.efi
              chainloader /EFI/Microsoft/Boot/bootmgfw.efi
            }
          ''
        ]
        ++ lib.optional (config.dendritic.nixinstall.enable or false) ''
          menuentry "NixOS Installer (dendritic)" --class gnu-linux {
            insmod fat
            search --no-floppy --set=root --file /EFI/dendritic-installer/bzImage
            linux /EFI/dendritic-installer/bzImage root=LABEL=nixinstall rootfstype=ext4 rw init=/nix/var/nix/profiles/system/init
            initrd /EFI/dendritic-installer/initrd
          }
        ''
        ++ [
          ''
            menuentry "UEFI Firmware Settings" --class efi {
              fwsetup
            }

            menuentry "Reboot" --class reboot {
              reboot
            }

            menuentry "Shut Down" --class shutdown {
              halt
            }
          ''
        ]
      );
    in
    {
      options.dendritic.bootTheme = {
        enable = lib.mkEnableOption "Stylix-themed GRUB generations menu + silent splash";

        configurationLimit = lib.mkOption {
          type = lib.types.ints.positive;
          default = 5;
          description = ''
            Latest NixOS generations shown in GRUB. Same ESP-safety cap as
            boot.loader.systemd-boot.configurationLimit — rollback stays in
            the "NixOS - All configurations" submenu.
          '';
        };

        splash = lib.mkOption {
          type = lib.types.enum [
            "silent"
            "bgrt"
            "nixos-bgrt"
            "dendritic"
            "stylix"
          ];
          default = "dendritic";
          description = ''
            Post-GRUB splash. NixOS has no first-class Plymouth replacement
            (no psplash / in-kernel bootsplash). Efficiency, lightest first:

            silent     — no Plymouth; quiet kernel/systemd only
            bgrt       — stock Plymouth spinner + firmware OEM logo
            nixos-bgrt — BGRT path with a spinning NixOS snowflake
            dendritic  — packaged two-step theme (NixOS logo + Stylix colours)
            stylix     — script plugin + animated logo (heaviest)
          '';
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            assertions = [
              {
                assertion = config.stylix.enable or false;
                message = "dendritic.bootTheme requires stylix.enable (palette + wallpaper).";
              }
            ];

            boot.loader.systemd-boot.enable = lib.mkForce false;
            # Mutual exclusion with efiInstallAsRemovable. Host may set
            # canTouchEfiVariables = true; AMI does not honor that NVRAM path.
            boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
            boot.loader.timeout = 8;

            boot.loader.grub = {
              enable = true;
              efiSupport = true;
              efiInstallAsRemovable = true;
              device = "nodev";
              useOSProber = false;
              configurationLimit = cfg.configurationLimit;
              gfxmodeEfi = "auto";
              gfxpayloadEfi = "keep";
              splashImage = grubTheme.splashImage;
              splashMode = "stretch";
              backgroundColor = "#${colors.base00}";
              font = toString grubTheme.font;
              theme = grubTheme;
              extraEntries = extraEntries;
              extraInstallCommands = ''
                ${lib.getExe grubEfiFirst}
              '';
            };

            stylix.targets.grub.enable = lib.mkForce false;

            boot.consoleLogLevel = 0;
            boot.initrd.verbose = false;
            boot.kernelParams = [
              "quiet"
              "loglevel=3"
              "udev.log_level=3"
              "udev.log_priority=3"
              "rd.udev.log_level=3"
              "systemd.show_status=false"
              "rd.systemd.show_status=false"
              "vt.global_cursor_default=0"
            ]
            ++ lib.optional (cfg.splash != "silent") "splash";
          }

          (lib.mkIf (cfg.splash == "silent") {
            boot.plymouth.enable = false;
            stylix.targets.plymouth.enable = lib.mkForce false;
          })

          (lib.mkIf (cfg.splash == "bgrt") {
            boot.plymouth.enable = true;
            boot.plymouth.theme = "bgrt";
            stylix.targets.plymouth.enable = lib.mkForce false;
          })

          (lib.mkIf (cfg.splash == "nixos-bgrt") {
            boot.plymouth.enable = true;
            boot.plymouth.theme = "nixos-bgrt";
            boot.plymouth.themePackages = [ pkgs.nixos-bgrt-plymouth ];
            stylix.targets.plymouth.enable = lib.mkForce false;
          })

          (lib.mkIf (cfg.splash == "dendritic") {
            boot.plymouth.enable = true;
            boot.plymouth.theme = "dendritic";
            boot.plymouth.themePackages = [ plymouthTheme ];
            stylix.targets.plymouth.enable = lib.mkForce false;
          })

          (lib.mkIf (cfg.splash == "stylix") {
            boot.plymouth.enable = true;
            stylix.targets.plymouth.enable = true;
            stylix.targets.plymouth.logoAnimated = true;
          })
        ]
      );
    };
}
