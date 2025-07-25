{
  nix-colors,
  lib,
  config,
  user,
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
  # - atelier-dune-light
  # - horizon-light
  scheme = "gruvbox-dark-soft";
in
# Choose from: https://tinted-theming.github.io/base16-gallery/
{
  # Import the default home manager modules from nix-colors
  imports = [
    nix-colors.homeManagerModules.default
    ./sa-resources/glow-themes/base16_glow_theme.nix
  ];

  # Set the global color scheme to the selected scheme
  colorscheme = nix-colors.colorSchemes.${scheme};

  home-manager.users.${user} = {
    # Set the color scheme for the user to the selected scheme
    colorscheme = nix-colors.colorSchemes.${scheme};

    specialisation = {
      light-theme = {
        configuration = {
          # Override the color scheme with a specific one (atelier-dune-light) for the light-theme specialisation
          # The mkForce function is used to ensure that this value takes precedence over any other definitions
          # Ensure the attribute name matches the one used elsewhere (colorscheme)
          colorscheme = lib.mkForce nix-colors.colorSchemes."gruvbox-light-soft";
        };
      };
    };
  };
}
