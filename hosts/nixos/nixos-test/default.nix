{ inputs, pkgs, ... }:

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
      fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };
      boot.loader.grub.enable = true;
      boot.loader.grub.device = "nodev";
      boot.kernelPackages = pkgs.linuxPackages_latest;
    }

    # 2. Import Home Manager
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
        
        # ── Feature Toggles ─────────────────────────────────────────
        dendritic.apps.ghostty.enable = true;
        dendritic.apps.nixvim-ide.enable = true;
        dendritic.python.enable = true;
        # ─────────────────────────────────────────────────────────────
      };
    }
  ];
}
