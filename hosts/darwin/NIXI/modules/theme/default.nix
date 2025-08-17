{
  inputs,
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
    inputs.nix-colors.homeManagerModules.default
    ./glow-theme.nix
  ];

  # Set the global color scheme to the selected scheme
  colorScheme = nix-colors.colorSchemes.${scheme};

  home-manager.users.${user} = {
    # Import nix-colors home-manager module
    imports = [
      nix-colors.homeManagerModules.default
    ];

    # Set the color scheme for the user to the selected scheme
    colorScheme = nix-colors.colorSchemes.${scheme};

    # Note: Light theme switching is now handled via separate flake outputs (NIXI-light)
    # instead of specialisations, so no specialisation configuration is needed here.
  };
}
