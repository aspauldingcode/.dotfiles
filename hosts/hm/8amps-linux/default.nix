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

    # Pull in the merged Dendritic feature module
    inputs.self.modules.homeManager.dendritic

    {
      # ── Feature Toggles ─────────────────────────────────────────
      dendritic.apps.ghostty.enable = true;
      dendritic.apps.vscode.enable = false;
      dendritic.apps.cursor.enable = false;
      dendritic.apps.antigravity.enable = false;
      dendritic.apps.jetbrains.enable = false;
      dendritic.apps.pass.enable = true;
      dendritic.apps.pass.fingerprint = "80AB4D8EFE29CE2ABD3BD0445C04154FC8950A8B";
      dendritic.python.enable = true;
      # ─────────────────────────────────────────────────────────────
    }
  ];
}
