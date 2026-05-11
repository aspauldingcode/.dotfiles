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
    inputs.self.nixosModules.shell
    inputs.self.nixosModules.secrets
    inputs.self.nixosModules.styling
    inputs.self.nixosModules.linux-desktop
    inputs.self.nixosModules.microvm
    inputs.self.nixosModules.python

    # 4. Configure Home Manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "backup";
      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.users."8amps" = {
        imports = [
          inputs.self.homeManagerModules.shell
          inputs.self.homeManagerModules.editor
          inputs.self.homeManagerModules.secrets
          inputs.self.homeManagerModules.styling
          inputs.self.homeManagerModules.apps
          inputs.self.homeManagerModules.ghostty
          inputs.self.homeManagerModules.python
          inputs.self.homeManagerModules.nixvim-ide
          inputs.self.homeManagerModules.wallpaper
          inputs.self.homeManagerModules.spotify
          inputs.self.homeManagerModules.vesktop
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
