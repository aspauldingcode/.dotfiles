{
  config,
  pkgs,
  lib,
  nix-colors,
  ...
}:
# generate a color palette from nix-colors (to view all colors in a file!)
{
  home.file = {
    "colors.toml" =
      let
        hexColorBase00 = "${config.colorscheme.palette.base00}";
        hexColorConvertedBase00 = builtins.toString (
          (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase00)) ++ [ "Other" ]
        );
        hexColorBase01 = "${config.colorscheme.palette.base01}";
        hexColorConvertedBase01 = builtins.toString (
          (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase01)) ++ [ "Other" ]
        );
        hexColorBase02 = "${config.colorscheme.palette.base02}";
        hexColorConvertedBase02 = builtins.toString (
          (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase02)) ++ [ "Other" ]
        );
        hexColorBase03 = "${config.colorscheme.palette.base03}";
        hexColorConvertedBase03 = builtins.toString (
          (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase03)) ++ [ "Other" ]
        );
        hexColorBase04 = "${config.colorscheme.palette.base04}";
        hexColorConvertedBase04 = builtins.toString (
          (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase04)) ++ [ "Other" ]
        );
        hexColorBase05 = "${config.colorscheme.palette.base05}";
        hexColorConvertedBase05 = builtins.toString (
          (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase05)) ++ [ "Other" ]
        );
        hexColorBase06 = "${config.colorscheme.palette.base06}";
        hexColorConvertedBase06 = builtins.toString (
          (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase06)) ++ [ "Other" ]
        );
        hexColorBase07 = "${config.colorscheme.palette.base07}";
        hexColorConvertedBase07 = builtins.toString (
          (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase07)) ++ [ "Other" ]
        );
        hexColorBase08 = "${config.colorscheme.palette.base08}";
        hexColorConvertedBase08 = builtins.toString (
          (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase08)) ++ [ "Other" ]
        );
        hexColorBase09 = "${config.colorscheme.palette.base09}";
        hexColorConvertedBase09 = builtins.toString (
          (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase09)) ++ [ "Other" ]
        );
        hexColorBase0A = "${config.colorscheme.palette.base0A}";
        hexColorConvertedBase0A = builtins.toString (
          (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase0A)) ++ [ "Other" ]
        );
        hexColorBase0B = "${config.colorscheme.palette.base0B}";
        hexColorConvertedBase0B = builtins.toString (
          (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase0B)) ++ [ "Other" ]
        );
        hexColorBase0C = "${config.colorscheme.palette.base0C}";
        hexColorConvertedBase0C = builtins.toString (
          (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase0C)) ++ [ "Other" ]
        );
        hexColorBase0D = "${config.colorscheme.palette.base0D}";
        hexColorConvertedBase0D = builtins.toString (
          (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase0D)) ++ [ "Other" ]
        );
        hexColorBase0E = "${config.colorscheme.palette.base0E}";
        hexColorConvertedBase0E = builtins.toString (
          (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase0E)) ++ [ "Other" ]
        );
        hexColorBase0F = "${config.colorscheme.palette.base0F}";
        hexColorConvertedBase0F = builtins.toString (
          (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase0F)) ++ [ "Other" ]
        );
      in
      # convert image to nix-colors:
      {
        text = builtins.toJSON {
          base16_nix_colors = {
            # nix-colors palette information
            variant = config.colorscheme.variant;
            slug = config.colorscheme.slug;

            # nix-colors palette as hex values
            base00 = "#${config.colorscheme.palette.base00}";
            base01 = "#${config.colorscheme.palette.base01}";
            base02 = "#${config.colorscheme.palette.base02}";
            base03 = "#${config.colorscheme.palette.base03}";
            base04 = "#${config.colorscheme.palette.base04}";
            base05 = "#${config.colorscheme.palette.base05}";
            base06 = "#${config.colorscheme.palette.base06}";
            base07 = "#${config.colorscheme.palette.base07}";
            base08 = "#${config.colorscheme.palette.base08}";
            base09 = "#${config.colorscheme.palette.base09}";
            base0A = "#${config.colorscheme.palette.base0A}";
            base0B = "#${config.colorscheme.palette.base0B}";
            base0C = "#${config.colorscheme.palette.base0C}";
            base0D = "#${config.colorscheme.palette.base0D}";
            base0E = "#${config.colorscheme.palette.base0E}";
            base0F = "#${config.colorscheme.palette.base0F}";
          };

          base16_default_colors = {
            # These colors are default base16 colors:
            base00 = "#181818";
            base01 = "#282828";
            base02 = "#383838";
            base03 = "#585858";
            base04 = "#b8b8b8";
            base05 = "#d8d8d8";
            base06 = "#e8e8e8";
            base07 = "#f8f8f8";
            base08 = "#ff0000";
            base09 = "#ffa500";
            base0A = "#ffff00";
            base0B = "#008000";
            base0C = "#00ffff";
            base0D = "#0000ff";
            base0E = "#ff00ff";
            base0F = "#a52a2a";
          };

          # Default base16 color scheme reference:
          base16_reference = {
            base00 = "Background (Darkest)";
            base01 = "Lighter Background (Status bars)";
            base02 = "Selection Background";
            base03 = "Comments, Invisibles, Line Highlighting";
            base04 = "Dark Foreground (Status bars)";
            base05 = "Default Foreground, Caret, Delimiters";
            base06 = "Light Foreground";
            base07 = "Lightest Foreground (Highlights)";
            base08 = "Red (Errors, Important)";
            base09 = "Orange (Warnings, Escape Sequences)";
            base0A = "Yellow (Classes, Constants)";
            base0B = "Green (Strings, Success)";
            base0C = "Cyan (Special Cases, Regexp)";
            base0D = "Blue (Functions, Methods)";
            base0E = "Magenta (Keywords, Storage)";
            base0F = "Brown (Deprecated, Special)";
          };

          # AppleHighlightColor example run in terminal:
          # defaults read -g AppleHighlightColor
        };
      };
  };
}
