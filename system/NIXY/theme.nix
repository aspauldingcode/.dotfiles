{ nix-colors, pkgs, lib, ... }:

# Configure GTK, QT themes, color schemes..
let 
  scheme = "gruvbox-dark-soft"; #tomorrow-night, #gruvbox-dark-soft, #catppuccin-macchiato, #katy are favorites
  # Choose from: https://nix-community.github.io/nixvim/colorschemes/base16/index.html#colorschemesbase16colorscheme
in
{
  imports = [
    nix-colors.homeManagerModules.default
  ];

  # nix-colors
  colorscheme = nix-colors.colorSchemes.${scheme};

  home-manager.users.alex = {
    colorscheme = nix-colors.colorSchemes.${scheme};

    specialisation = {
      light-theme = {
        configuration = {
          # We have to force the values below to override the ones defined above
          colorScheme = lib.mkForce nix-colors.colorSchemes.katy;
      };
    };
  };
  };
}
