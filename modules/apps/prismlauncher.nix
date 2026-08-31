{
  # Prism Launcher — Minecraft, both Darwin and Linux.
  # Was only in sliceanddice systemPackages, so mba never got the app.
  flake.modules.homeManager.dendritic =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.prismlauncher ];
    };

  flake.modules.darwin.dendritic =
    { pkgs, lib, ... }:
    {
      dendritic.dock.apps = lib.mkOrder 135 [
        "${pkgs.prismlauncher}/Applications/PrismLauncher.app"
      ];
    };
}
