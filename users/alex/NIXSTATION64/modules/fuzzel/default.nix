{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.colorscheme) colors;
in
{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "${pkgs.alacritty}/bin/alacritty";
        prompt = "❯ ";
        font = "monospace:size=12";
        dpi-aware = "yes";
        show-actions = "yes";
        password-character = "*";
        fields = "filename,name,generic";
        fuzzy = "yes";
        width = 50;
        tabs = 8;
        horizontal-pad = 40;
        vertical-pad = 8;
        inner-pad = 0;
      };

      colors = {
        background = "${colors.base00}dd";
        text = "${colors.base05}ff";
        match = "${colors.base0C}ff";
        selection = "${colors.base02}ff";
        selection-text = "${colors.base05}ff";
        selection-match = "${colors.base0C}ff";
        border = "${colors.base07}ff";
      };

      border = {
        width = 2;
        radius = 8;
      };
    };
  };
}
