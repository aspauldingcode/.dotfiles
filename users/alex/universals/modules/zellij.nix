{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.colorScheme) palette;
in
{
  config = {
    programs.zellij = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      settings = {
        theme = "custom";
        themes = {
          custom = {
            fg = "#${palette.base05}";
            bg = "#${palette.base02}";
            black = "#${palette.base00}";
            red = "#${palette.base08}";
            green = "#${palette.base0B}";
            yellow = "#${palette.base0A}";
            blue = "#${palette.base0D}";
            magenta = "#${palette.base0E}";
            cyan = "#${palette.base0C}";
            white = "#${palette.base05}";
            orange = "#${palette.base09}";
          };
        };
      };
    };
  };
}
