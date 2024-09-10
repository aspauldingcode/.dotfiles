{ config, pkgs, lib, ... }:

# generate a color palette from nix-colors (to view all colors in a file!)
{
  home.file = {
    "colors.txt" = {
      text = ''
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
      '';
    };
  };
}