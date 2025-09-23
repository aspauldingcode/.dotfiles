# DELIVERER Home Configuration for alex
{
  user,
  nix-colors,
  ...
}:
{
  imports = [
    nix-colors.homeManagerModules.default
  ];

  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "25.05";

  # Set a default colorScheme for DELIVERER configuration
  colorScheme = nix-colors.colorSchemes.gruvbox-dark-medium;

  # DELIVERER-specific home configuration
}
