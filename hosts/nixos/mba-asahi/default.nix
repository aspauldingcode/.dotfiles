{ inputs, pkgs, lib, ... }:

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
        extraGroups = [ "wheel" ];
        shell = pkgs.zsh;
      };

      fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
      fileSystems."/boot" = { device = "/dev/disk/by-label/boot"; fsType = "vfat"; };
      fileSystems."/boot/asahi" = { device = "/dev/disk/by-label/asahi"; fsType = "vfat"; };
      hardware.asahi.extractPeripheralFirmware = false;
    }

    # 2. Support modules
    inputs.apple-silicon.nixosModules.apple-silicon-support
    inputs.home-manager.nixosModules.home-manager

    # 3. Pull in Feature Modules from the Hub
    inputs.self.modules.nixos.shell
    inputs.self.modules.nixos.secrets
    inputs.self.modules.nixos.styling
    inputs.self.modules.nixos.linux-desktop
    inputs.self.modules.nixos.microvm
    inputs.self.modules.nixos.python

    # 4. Configure Home Manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "backup";
      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.users."8amps" = {
        imports = [
          inputs.self.modules.homeManager.shell
          inputs.self.modules.homeManager.editor
          inputs.self.modules.homeManager.secrets
          inputs.self.modules.homeManager.styling
          inputs.self.modules.homeManager.apps
          inputs.self.modules.homeManager.ghostty
          inputs.self.modules.homeManager.python
          inputs.self.modules.homeManager.nixvim-ide
          inputs.self.modules.homeManager.wallpaper
          inputs.self.modules.homeManager.spotify
          inputs.self.modules.homeManager.vesktop
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
        dendritic.apps.nixvim-ide.enable = true;
        dendritic.python.enable = true;

        # ─────────────────────────────────────────────────────────────
      };
    }
  ];
}
