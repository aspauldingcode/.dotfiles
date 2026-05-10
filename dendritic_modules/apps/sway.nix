{
  flake.modules.homeManager.sway = { config, pkgs, lib, ... }: {
    options.dendritic.apps.sway = {
      enable = lib.mkEnableOption "Sway window manager";
    };

    config = lib.mkIf config.dendritic.apps.sway.enable {
      wayland.windowManager.sway = {
        enable = true;
        package = null; # Use the system package
        config = rec {
          modifier = "Mod4";
          terminal = "${config.programs.ghostty.package}/bin/ghostty";
          keybindings = lib.mkOptionDefault {
            "${modifier}+Return" = "exec ${terminal}";
          };
        };
      };
    };
  };
}
