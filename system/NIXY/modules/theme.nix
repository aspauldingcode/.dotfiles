{
  nix-colors,
  pkgs,
  lib,
  ...
}:

# Configure GTK, QT themes, color schemes..
let
  # Define the default color scheme to be used. Some favorite schemes are:
  # - tomorrow-night
  # - gruvbox-dark-soft
  # - catppuccin-macchiato
  # - katy
  # - selenized-dark
  # - pandora
  # - papercolor-dark
  # - zenburn
  scheme = "atelier-dune-light"; 
in
# Choose from: https://nix-community.github.io/nixvim/colorschemes/base16/index.html#colorschemesbase16colorscheme
{
  # Import the default home manager modules from nix-colors
  imports = [ nix-colors.homeManagerModules.default ];

  # Set the global color scheme to the selected scheme
  colorscheme = nix-colors.colorSchemes.${scheme};

  home-manager.users.alex = {
    # Set the color scheme for the user 'alex' to the selected scheme
    colorscheme = nix-colors.colorSchemes.${scheme};

    specialisation = {
      light-theme = {
        configuration = {
          # Override the color scheme with a specific one (katy) for the light-theme specialisation
          # The mkForce function is used to ensure that this value takes precedence over any other definitions
          colorScheme = lib.mkForce nix-colors.colorSchemes.katy;
        };
      };
    };
  };
}
