{ config, pkgs, lib, nix-colors, ... }:

# generate a color palette from nix-colors (to view all colors in a file!)
{
  home.file = {
    "colors.txt" = 
    let
      hexColorBase00 = "${config.colorscheme.colors.base00}";
      hexColorConvertedBase00 = builtins.toString (
        (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase00))
        ++ ["Other"]
      );
      hexColorBase01 = "${config.colorscheme.colors.base01}";
      hexColorConvertedBase01 = builtins.toString (
        (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase01))
        ++ ["Other"]
      );
      hexColorBase02 = "${config.colorscheme.colors.base02}";
      hexColorConvertedBase02 = builtins.toString (
        (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase02))
        ++ ["Other"]
      );
      hexColorBase03 = "${config.colorscheme.colors.base03}";
      hexColorConvertedBase03 = builtins.toString (
        (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase03))
        ++ ["Other"]
      );
      hexColorBase04 = "${config.colorscheme.colors.base04}";
      hexColorConvertedBase04 = builtins.toString (
        (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase04))
        ++ ["Other"]
      );
      hexColorBase05 = "${config.colorscheme.colors.base05}";
      hexColorConvertedBase05 = builtins.toString (
        (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase05))
        ++ ["Other"]
      );
      hexColorBase06 = "${config.colorscheme.colors.base06}";
      hexColorConvertedBase06 = builtins.toString (
        (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase06))
        ++ ["Other"]
      );
      hexColorBase07 = "${config.colorscheme.colors.base07}";
      hexColorConvertedBase07 = builtins.toString (
        (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase07))
        ++ ["Other"]
      );
      hexColorBase08 = "${config.colorscheme.colors.base08}";
      hexColorConvertedBase08 = builtins.toString (
        (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase08))
        ++ ["Other"]
      );
      hexColorBase09 = "${config.colorscheme.colors.base09}";
      hexColorConvertedBase09 = builtins.toString (
        (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase09))
        ++ ["Other"]
      );
      hexColorBase0A = "${config.colorscheme.colors.base0A}";
      hexColorConvertedBase0A = builtins.toString (
        (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase0A))
        ++ ["Other"]
      );
      hexColorBase0B = "${config.colorscheme.colors.base0B}";
      hexColorConvertedBase0B = builtins.toString (
        (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase0B))
        ++ ["Other"]
      );
      hexColorBase0C = "${config.colorscheme.colors.base0C}";
      hexColorConvertedBase0C = builtins.toString (
        (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase0C))
        ++ ["Other"]
      );
      hexColorBase0D = "${config.colorscheme.colors.base0D}";
      hexColorConvertedBase0D = builtins.toString (
        (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase0D))
        ++ ["Other"]
      );
      hexColorBase0E = "${config.colorscheme.colors.base0E}";
      hexColorConvertedBase0E = builtins.toString (
        (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase0E))
        ++ ["Other"]
      );
      hexColorBase0F = "${config.colorscheme.colors.base0F}";
      hexColorConvertedBase0F = builtins.toString (
        (builtins.map (x: x / 255.0) (nix-colors.lib.conversions.hexToRGB hexColorBase0F))
        ++ ["Other"]
      );

      # convert image to nix-colors:
      
    in {
      text = ''
        # nix-colors palette as hex values
        base00: #${config.colorscheme.colors.base00}
        base01: #${config.colorscheme.colors.base01}
        base02: #${config.colorscheme.colors.base02}
        base03: #${config.colorscheme.colors.base03}
        base04: #${config.colorscheme.colors.base04}
        base05: #${config.colorscheme.colors.base05}
        base06: #${config.colorscheme.colors.base06}
        base07: #${config.colorscheme.colors.base07}
        base08: #${config.colorscheme.colors.base08}
        base09: #${config.colorscheme.colors.base09}
        base0A: #${config.colorscheme.colors.base0A}
        base0B: #${config.colorscheme.colors.base0B}
        base0C: #${config.colorscheme.colors.base0C}
        base0D: #${config.colorscheme.colors.base0D}
        base0E: #${config.colorscheme.colors.base0E}
        base0F: #${config.colorscheme.colors.base0F}
        
        # AppleHighlightColor example run in terminal:
        # defaults read -g AppleHighlightColor
        base00: ${hexColorConvertedBase00};
        base01: ${hexColorConvertedBase01};
        base02: ${hexColorConvertedBase02};
        base03: ${hexColorConvertedBase03};
        base04: ${hexColorConvertedBase04};
        base05: ${hexColorConvertedBase05};
        base06: ${hexColorConvertedBase06};
        base07: ${hexColorConvertedBase07};
        base08: ${hexColorConvertedBase08};
        base09: ${hexColorConvertedBase09};
        base0A: ${hexColorConvertedBase0A};
        base0B: ${hexColorConvertedBase0B};
        base0C: ${hexColorConvertedBase0C};
        base0D: ${hexColorConvertedBase0D};
        base0E: ${hexColorConvertedBase0E};
        base0F: ${hexColorConvertedBase0F};
      '';
    };
  };
}