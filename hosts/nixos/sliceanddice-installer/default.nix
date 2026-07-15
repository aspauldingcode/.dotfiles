# Minimal on-disk installer OS for sliceanddice.
# Root = PARTLABEL=nixinstall; shares ESP. Runs disko against the flake to
# reformat PARTLABEL=nixos as btrfs without wiping this partition.
{
  inputs,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    inputs.determinate-nix.nixosModules.default
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.11";

  networking.hostName = "sliceanddice-installer";
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/nixinstall";
    fsType = "ext4";
    options = [ "noatime" ];
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/ESP";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };
  swapDevices = [ ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.alex = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    initialHashedPassword = "";
  };
  users.users.root.initialHashedPassword = "";
  security.sudo.wheelNeedsPassword = false;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "alex"
    ];
  };

  environment.systemPackages = with pkgs; [
    git
    rsync
    disko
    nh
    gnupg
    pass
    age
    sops
    efibootmgr
    gptfdisk
    parted
    btrfs-progs
    e2fsprogs
    ntfs3g
    vim
    tmux
    curl
    jq
    nixos-install-tools
    (writeShellApplication {
      name = "dendritic-vault-sync";
      runtimeInputs = [
        coreutils
        util-linux
        rsync
        gnugrep
        hostname
      ];
      text = builtins.readFile ../../../modules/pkgs/_dendritic-vault.sh;
    })
    (writeShellApplication {
      name = "dendritic-vault-restore";
      runtimeInputs = [
        coreutils
        util-linux
        rsync
        gnugrep
        findutils
      ];
      text = ''
        # shellcheck disable=SC1091
        exec bash ${../../../modules/pkgs/_dendritic-vault.sh} restore "$@"
      '';
    })
    (writeShellApplication {
      name = "dendritic-reinstall";
      runtimeInputs = [
        coreutils
        util-linux
        disko
        nixos-install-tools
        git
        rsync
        nix
        bash
      ];
      excludeShellChecks = [
        "SC2086"
        "SC2164"
        "SC2015"
      ];
      text = builtins.readFile ../../../modules/pkgs/_dendritic-reinstall.sh;
    })
  ];

  services.xserver.enable = false;
  documentation.enable = false;
  documentation.nixos.enable = false;
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
}
