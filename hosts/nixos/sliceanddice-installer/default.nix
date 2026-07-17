# Minimal on-disk installer OS for sliceanddice.
# Root = PARTLABEL=nixinstall; shares ESP. Safe reinstall preserves this partition.
{
  inputs,
  pkgs,
  lib,
  ...
}:

let
  sshKeys = import ../../../home/ssh-keys.nix;
  allPubkeys = lib.unique (lib.attrValues sshKeys);

  installerWifi = pkgs.writeShellApplication {
    name = "dendritic-installer-wifi";
    runtimeInputs = with pkgs; [
      networkmanager
      jq
      util-linux
      coreutils
      gnugrep
    ];
    excludeShellChecks = [
      "SC2086"
      "SC2046"
    ];
    text = builtins.readFile ../../../modules/pkgs/_dendritic-installer-wifi.sh;
  };
in
{
  imports = [
    inputs.determinate-nix.nixosModules.default
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.11";

  networking.hostName = "sliceanddice-installer";
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
    wifi.powersave = false;
  };
  networking.wireless.enable = false;
  networking.wireless.iwd.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  # Wi-Fi / NIC firmware (Sword 15 Intel).
  hardware.enableRedistributableFirmware = true;

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
  boot.kernelModules = [
    "kvm-intel"
    "iwlwifi"
  ];

  # SSH for Cursor / remote `dendritic-reinstall` once vault Wi-Fi is up.
  # Keys: flake home/ssh-keys.nix + optional /vault/ssh (see root-keys service).
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
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
    openssh.authorizedKeys.keys = allPubkeys;
  };
  users.users.root = {
    initialHashedPassword = "";
    openssh.authorizedKeys.keys = allPubkeys;
  };
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
    networkmanager # nmtui + nmcli
    installerWifi
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
        gptfdisk
        parted
        e2fsprogs
        btrfs-progs
        ntfs3g
        nixos-install-tools
        git
        rsync
        nix
        bash
        systemd
      ];
      excludeShellChecks = [
        "SC2086"
        "SC2164"
        "SC2015"
        "SC2046"
        "SC2004"
      ];
      text = builtins.readFile ../../../modules/pkgs/_dendritic-reinstall.sh;
    })
  ];

  # Declarative Wi-Fi from /vault/wifi (synced from main OS). Fallback: nmtui.
  systemd.services.dendritic-installer-wifi = {
    description = "Apply vault Wi-Fi profiles on installer";
    after = [
      "NetworkManager.service"
      "iwd.service"
    ];
    wants = [
      "NetworkManager.service"
      "iwd.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${installerWifi}/bin/dendritic-installer-wifi";
    };
  };

  # Merge vault SSH keys onto root + alex (in addition to flake pubkeys above).
  systemd.services.dendritic-installer-ssh-keys = {
    description = "Install authorized_keys from vault for root and alex";
    wantedBy = [ "multi-user.target" ];
    before = [ "sshd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "dendritic-installer-ssh-keys" ''
        set -euo pipefail
        install_keys() {
          local home="$1"
          local uid gid
          uid="$(id -u "$(basename "$home")" 2>/dev/null || echo 0)"
          gid="$(id -g "$(basename "$home")" 2>/dev/null || echo 0)"
          mkdir -p "$home/.ssh"
          touch "$home/.ssh/authorized_keys"
          if [[ -f /vault/ssh/authorized_keys ]]; then
            cat /vault/ssh/authorized_keys >>"$home/.ssh/authorized_keys"
          fi
          if [[ -f /vault/ssh/id_ed25519.pub ]]; then
            cat /vault/ssh/id_ed25519.pub >>"$home/.ssh/authorized_keys"
          fi
          if [[ -s $home/.ssh/authorized_keys ]]; then
            sort -u -o "$home/.ssh/authorized_keys" "$home/.ssh/authorized_keys"
          fi
          chmod 700 "$home/.ssh"
          chmod 600 "$home/.ssh/authorized_keys"
          chown -R "$uid:$gid" "$home/.ssh"
        }
        install_keys /root
        install_keys /home/alex
      '';
    };
  };

  services.xserver.enable = false;
  documentation.enable = false;
  documentation.nixos.enable = false;
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
}
