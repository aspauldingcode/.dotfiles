{ inputs, pkgs, ... }:

{
  imports = [
    {
      nixpkgs.config.allowUnfree = true;
      home.username = "8amps";
      home.homeDirectory = "/home/8amps";
      home.stateVersion = "24.11";
      targets.genericLinux.enable = true;
    }

    # Pull in Feature Modules from the Hub
    inputs.self.modules.homeManager.shell
    inputs.self.modules.homeManager.editor
    inputs.self.modules.homeManager.secrets
    inputs.self.modules.homeManager.styling
    inputs.self.modules.homeManager.apps
    inputs.self.modules.homeManager.ghostty
    inputs.self.modules.homeManager.antigravity
    inputs.self.modules.homeManager.wallpaper
    inputs.self.modules.homeManager.spotify
    
    # External modules
    inputs.stylix.homeModules.stylix

    {
      # ── Feature Toggles ─────────────────────────────────────────
      dendritic.apps.ghostty.enable = true;
      dendritic.apps.antigravity.enable = true;
      # ─────────────────────────────────────────────────────────────
    }
  ];
}
