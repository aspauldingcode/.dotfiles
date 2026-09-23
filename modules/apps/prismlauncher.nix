{
  # Prism Launcher — Minecraft, both Darwin and Linux.
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.prismlauncher;
    in
    {
      options.dendritic.apps.prismlauncher = {
        enable = lib.mkEnableOption "Prism Launcher (Minecraft)" // {
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.prismlauncher ];
      };
    };

  flake.modules.darwin.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      user = config.system.primaryUser;
      enabled = config.home-manager.users.${user}.dendritic.apps.prismlauncher.enable or false;
    in
    lib.mkIf enabled {
      dendritic.dock.apps = lib.mkOrder 135 [
        "${pkgs.prismlauncher}/Applications/PrismLauncher.app"
      ];
    };
}
