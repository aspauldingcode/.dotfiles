{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:

{
  imports = [
    # 1. Base identity and platform
    {
      nixpkgs.hostPlatform = "aarch64-linux";
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [ ];
      system.stateVersion = "24.11";

      users.users."8amps" = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
        shell = pkgs.zsh;
      };

      fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };
      fileSystems."/boot" = {
        device = "/dev/disk/by-label/boot";
        fsType = "vfat";
      };
      fileSystems."/boot/asahi" = {
        device = "/dev/disk/by-label/asahi";
        fsType = "vfat";
      };
      hardware.asahi.extractPeripheralFirmware = false;
    }

    # 2. Support modules
    inputs.apple-silicon.nixosModules.apple-silicon-support
    inputs.home-manager.nixosModules.home-manager

    # 3. Pull in the merged Dendritic feature module
    inputs.self.modules.nixos.dendritic

    # 4. Configure Home Manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "backup";
      home-manager.sharedModules = [
        {
          dendritic.theme.variant = lib.mkDefault config.dendritic.theme.variant;
        }
      ];
      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.users."8amps" = {
        imports = [
          inputs.self.modules.homeManager.dendritic
        ];
        home.username = "8amps";
        home.homeDirectory = "/home/8amps";
        home.stateVersion = "24.11";

        # ── Show Hidden Files (GTK) ──────────────────────────────────
        dconf.settings = {
          "org/gtk/settings/file-chooser" = {
            show-hidden = true;
          };
          "org/gtk/v4/settings/file-chooser" = {
            show-hidden = true;
          };
        };

        # ── Feature Toggles ─────────────────────────────────────────
        dendritic.apps.ghostty.enable = true;
        dendritic.apps.pass.enable = true;
        dendritic.apps.pass.fingerprint = "80AB4D8EFE29CE2ABD3BD0445C04154FC8950A8B";
        dendritic.ssh.enable = true;
        dendritic.python.enable = true;

        # ─────────────────────────────────────────────────────────────
      };
    }
  ];
}
