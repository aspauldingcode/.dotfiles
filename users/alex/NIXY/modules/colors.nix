{ config, pkgs, lib, ... }:

# generate a color palette from nix-colors (to view all colors in a file!)
{
  home.file = {
    "colors.txt" = {
      text = ''
        #${config.colorscheme.colors.base00}
        #${config.colorscheme.colors.base01}
        #${config.colorscheme.colors.base02}
        #${config.colorscheme.colors.base03}
        #${config.colorscheme.colors.base04}
        #${config.colorscheme.colors.base05}
        #${config.colorscheme.colors.base06}
        #${config.colorscheme.colors.base07}
        #${config.colorscheme.colors.base08}
        #${config.colorscheme.colors.base09}
        #${config.colorscheme.colors.base0A}
        #${config.colorscheme.colors.base0B}
        #${config.colorscheme.colors.base0C}
        #${config.colorscheme.colors.base0D}
        #${config.colorscheme.colors.base0E}
        #${config.colorscheme.colors.base0F}
      '';
    };
  };
}