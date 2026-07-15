# Target GPT layout for sliceanddice (Samsung 870 EVO 500GB).
#
# disko generates mount units; it does NOT format on nh os switch.
# Full wipe/reinstall is done from the on-disk installer (PARTLABEL=nixinstall).
#
# Layout:
#   1 ESP | 2 nixos (btrfs subvols) | 3 nixinstall (installer+vault)
#   | 4 windows | 5 wininstall | 6 swap
#
# liveExt4Compat: until the installer reformats nixos to btrfs, force `/` to the
# existing ext4 UUID so nh os switch stays bootable.
{
  inputs,
  lib,
  config,
  ...
}:

let
  disk = "/dev/disk/by-id/ata-Samsung_SSD_870_EVO_500GB_S62ANJ0R238724D";
  espUuid = "8824-4C5F";
  swapUuid = "c570ec29-6025-456b-99d1-8f16b677835a";
  liveExt4Uuid = "b89f5dca-4b37-4062-bf1d-9e4ebfd61916";
  btrfsOpts = [
    "compress=zstd"
    "ssd"
    "noatime"
    "discard=async"
  ];
  liveExt4 = config.dendritic.disk.liveExt4Compat;
in
{
  imports = [ inputs.disko.nixosModules.disko ];

  options.dendritic.disk.liveExt4Compat = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Keep / on the pre-migration ext4 UUID. Set false after btrfs install
      from nixinstall so disko btrfs subvolume mounts apply.
    '';
  };

  config = {
    disko.devices.disk.main = {
      type = "disk";
      device = disk;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            priority = 1;
            size = "512M";
            type = "EF00";
            label = "ESP";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "fmask=0077"
                "dmask=0077"
              ];
            };
          };
          nixos = {
            priority = 2;
            end = "-89G";
            label = "nixos";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = btrfsOpts;
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = btrfsOpts;
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = btrfsOpts;
                };
                "@log" = {
                  mountpoint = "/var/log";
                  mountOptions = btrfsOpts;
                };
              };
            };
          };
          nixinstall = {
            priority = 3;
            size = "8G";
            label = "nixinstall";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/mnt/nixinstall";
              mountOptions = [
                "nofail"
                "noatime"
                "x-systemd.device-timeout=5s"
              ];
            };
          };
          windows = {
            priority = 4;
            size = "64G";
            label = "windows";
            content = {
              type = "filesystem";
              format = "ntfs";
              mountpoint = "/mnt/windows";
              mountOptions = [
                "nofail"
                "rw"
                "uid=1000"
                "gid=100"
                "umask=022"
                "x-systemd.device-timeout=5s"
              ];
            };
          };
          wininstall = {
            priority = 5;
            size = "8G";
            label = "wininstall";
            content = {
              type = "filesystem";
              format = "ntfs";
              mountpoint = "/mnt/wininstall";
              mountOptions = [
                "nofail"
                "ro"
                "uid=1000"
                "gid=100"
                "umask=022"
                "x-systemd.device-timeout=5s"
              ];
            };
          };
          swap = {
            priority = 6;
            size = "100%";
            label = "swap";
            content = {
              type = "swap";
              discardPolicy = "both";
            };
          };
        };
      };
    };

    fileSystems."/boot" = lib.mkForce {
      device = "/dev/disk/by-uuid/${espUuid}";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    fileSystems."/" = lib.mkIf liveExt4 (
      lib.mkForce {
        device = "/dev/disk/by-uuid/${liveExt4Uuid}";
        fsType = "ext4";
        options = [ "noatime" ];
      }
    );

    # When not in liveExt4Compat, disko owns / and subvols; do not mkForce.

    swapDevices =
      if liveExt4 then
        [ ]
      else
        lib.mkForce [
          { device = "/dev/disk/by-uuid/${swapUuid}"; }
        ];
  };
}
