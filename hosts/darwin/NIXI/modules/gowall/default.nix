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
  environment.etc."gowall/theme.json" = {
    enable = true;
    text = ''
      {
        "name": "${config.colorscheme.slug}",
        "colors": [
          "#${palette.base00}",
          "#${palette.base01}",
          "#${palette.base02}",
          "#${palette.base03}",
          "#${palette.base04}",
          "#${palette.base05}",
          "#${palette.base06}",
          "#${palette.base07}",
          "#${palette.base08}",
          "#${palette.base09}",
          "#${palette.base0A}",
          "#${palette.base0B}",
          "#${palette.base0C}",
          "#${palette.base0D}",
          "#${palette.base0E}",
          "#${palette.base0F}"
        ]
      }
    '';
  };
}
