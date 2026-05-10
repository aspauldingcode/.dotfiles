{ inputs, pkgs, ... }:

{
  imports = [
    {
      home.username = "8amps";
      home.homeDirectory = "/home/8amps";
      home.stateVersion = "24.11";
      targets.genericLinux.enable = true;
      manual.manpages.enable = false;
      manual.html.enable = false;
      manual.json.enable = false;
      gtk.gtk4.theme = null;
    }

    # Pull in Feature Modules from the Hub
    inputs.self.modules.homeManager.shell
    inputs.self.modules.homeManager.editor
    inputs.self.modules.homeManager.secrets
    inputs.self.modules.homeManager.styling
    inputs.self.modules.homeManager.apps
    inputs.self.modules.homeManager.ghostty
    inputs.self.modules.homeManager.antigravity
    inputs.self.modules.homeManager.python
    inputs.self.modules.homeManager.wallpaper
    inputs.self.modules.homeManager.spotify
    inputs.self.modules.homeManager.vesktop
    inputs.self.modules.homeManager.sway
    
    # External modules

    {
      # ── Feature Toggles ─────────────────────────────────────────
      dendritic.apps.ghostty.enable = true;
      dendritic.apps.sway.enable = true;
      dendritic.apps.antigravity.enable = false;
      dendritic.python.enable = true;
      # ─────────────────────────────────────────────────────────────
    }
  ];
}
