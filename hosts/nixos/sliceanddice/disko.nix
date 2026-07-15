# Target GPT layout for sliceanddice (Samsung 870 EVO 500GB).
#
# disko generates mount units; it does NOT repartition on every nh os switch.
# Live shrink + Windows/wininstall creation is owned by dendritic-windows-bootstrap.
#
# Layout after bootstrap:
#   1 ESP | 2 nixos | 3 windows (64G) | 4 wininstall (~8G Setup media) | 5 swap
#
# wininstall holds extracted IoT LTSC ISO + Autounattend; first bootstrap boots
# into it once. Partition stays for repair media; bootstrap does not re-run.
{
  inputs,
  lib,
  ...
}:

let
  disk = "/dev/disk/by-id/ata-Samsung_SSD_870_EVO_500GB_S62ANJ0R238724D";
  # Preserved across resize2fs shrink:
  rootUuid = "b89f5dca-4b37-4062-bf1d-9e4ebfd61916";
  espUuid = "8824-4C5F";
  # Preserved across bootstrap recreate via mkswap -U:
  swapUuid = "c570ec29-6025-456b-99d1-8f16b677835a";
in
{
  imports = [ inputs.disko.nixosModules.disko ];

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
        # Leaves 64G Windows + 8G wininstall + ~9G swap at the end of the disk.
        nixos = {
          priority = 2;
          end = "-81G";
          label = "nixos";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = [ "noatime" ];
          };
        };
        windows = {
          priority = 3;
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
        # Extracted Setup media (ISO contents + Autounattend). Stays after install.
        wininstall = {
          priority = 4;
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
          priority = 5;
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

  # Bootable before bootstrap finishes labeling / creating Windows.
  fileSystems."/" = lib.mkForce {
    device = "/dev/disk/by-uuid/${rootUuid}";
    fsType = "ext4";
    options = [ "noatime" ];
  };
  fileSystems."/boot" = lib.mkForce {
    device = "/dev/disk/by-uuid/${espUuid}";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };
  # Stable UUID: bootstrap recreates swap with the same UUID (-U).
  swapDevices = lib.mkForce [
    { device = "/dev/disk/by-uuid/${swapUuid}"; }
  ];
}
