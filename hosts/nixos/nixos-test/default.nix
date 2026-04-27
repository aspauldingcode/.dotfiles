{ inputs, ... }:

{
  imports = [
    # 1. Base identity and platform
    {
      nixpkgs.hostPlatform = "x86_64-linux";
      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "24.11";
      
      users.users."8amps" = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
      };
    }

    # 2. Import Home Manager
    inputs.home-manager.nixosModules.home-manager

    # 3. Pull in Feature Modules from the Hub
    inputs.self.modules.nixos.shell
    inputs.self.modules.nixos.secrets
    inputs.self.modules.nixos.styling
    inputs.self.modules.nixos.linux-desktop
    inputs.self.modules.nixos.microvm

    # 4. Configure Home Manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.users."8amps" = {
        imports = [
          inputs.self.modules.homeManager.shell
          inputs.self.modules.homeManager.editor
          inputs.self.modules.homeManager.secrets
          inputs.self.modules.homeManager.styling
          inputs.self.modules.homeManager.apps
          inputs.self.modules.homeManager.ghostty
          inputs.self.modules.homeManager.antigravity
          inputs.self.modules.homeManager.wallpaper
          inputs.self.modules.homeManager.spotify
        ];
        home.username = "8amps";
        home.homeDirectory = "/home/8amps";
        home.stateVersion = "24.11";
        
        # ── Feature Toggles ─────────────────────────────────────────
        dendritic.apps.ghostty.enable = true;
        dendritic.apps.antigravity.enable = true;
        # ─────────────────────────────────────────────────────────────
      };
    }
  ];
}
