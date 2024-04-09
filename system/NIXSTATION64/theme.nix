{ nix-colors, ... }:

# Configure GTK, QT themes, color schemes..
let
  scheme = "katy"; # gruvbox-dark-soft
in
# Choose from: https://nix-community.github.io/nixvim/colorschemes/base16/index.html#colorschemesbase16colorscheme
{
  imports = [ nix-colors.homeManagerModules.default ];
  # nix-colors
  colorscheme = nix-colors.colorSchemes.${scheme};
  home-manager.users.alex.colorscheme = nix-colors.colorSchemes.${scheme};
}
