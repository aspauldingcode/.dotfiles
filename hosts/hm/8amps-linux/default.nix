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
    inputs.self.homeManagerModules.shell
    # inputs.self.homeManagerModules.editor
    inputs.self.homeManagerModules.secrets
    inputs.self.homeManagerModules.styling
    inputs.self.homeManagerModules.apps
    inputs.self.homeManagerModules.ghostty
    inputs.self.homeManagerModules.antigravity
    inputs.self.homeManagerModules.python
    inputs.self.homeManagerModules.wallpaper
    inputs.self.homeManagerModules.spotify
    inputs.self.homeManagerModules.vesktop
    inputs.self.homeManagerModules.sway
    
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
