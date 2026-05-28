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
      nixpkgs.hostPlatform = "x86_64-linux";
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [ ];
      system.stateVersion = "24.11";

      users.users."8amps" = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        shell = pkgs.zsh;
      };

      # Dummy filesystem for CI verification
      fileSystems."/" = {
        device = "/dev/sda1";
        fsType = "ext4";
      };
      boot.loader.grub.enable = true;
      boot.loader.grub.device = "nodev";
      boot.kernelPackages = pkgs.linuxPackages_latest;
    }

    # 2. Import Home Manager
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

        # ── Feature Toggles ─────────────────────────────────────────
        dendritic.apps.ghostty.enable = true;
        dendritic.python.enable = true;
        # ─────────────────────────────────────────────────────────────
      };
    }
  ];
}
