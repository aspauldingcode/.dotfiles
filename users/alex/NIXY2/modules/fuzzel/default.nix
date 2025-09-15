{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.colorScheme) palette;
in {
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

      palette = {
        background = "${palette.base00}dd";
        text = "${palette.base05}ff";
        match = "${palette.base0C}ff";
        selection = "${palette.base02}ff";
        selection-text = "${palette.base05}ff";
        selection-match = "${palette.base0C}ff";
        border = "${palette.base07}ff";
      };

      border = {
        width = 2;
        radius = 8;
      };
    };
  };
}
