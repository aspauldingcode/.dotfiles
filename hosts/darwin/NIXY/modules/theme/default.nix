{
  inputs,
  nix-colors,
  user,
  ...
}:
# Configure GTK, QT themes, color schemes..
let
  # Centralized theme selection for NIXY
  themes = {
    dark = "selenized-dark";
    light = "selenized-light";
  };

  # Use dark theme by default (light theme handled by NIXY-light flake output)
  scheme = themes.dark;
in
# Choose from: https://tinted-theming.github.io/base16-gallery/
{
  # Import the default home manager modules from nix-colors
  imports = [
    inputs.nix-colors.homeManagerModules.default
    # ./tinted-mac.nix
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
  };
}
