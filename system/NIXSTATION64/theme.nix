{ nix-colors, ... }:

# Configure GTK, QT themes, color schemes..
let 
  scheme = "tomorrow-night"; #gruvbox-dark-soft
  # Choose from: https://nix-community.github.io/nixvim/colorschemes/base16/index.html#colorschemesbase16colorscheme
in
  {
    imports = [
      nix-colors.homeManagerModules.default
    ];
    # nix-colors
    colorscheme = nix-colors.colorSchemes.${scheme};
    home-manager.users.alex.colorscheme = nix-colors.colorSchemes.${scheme};
  }
