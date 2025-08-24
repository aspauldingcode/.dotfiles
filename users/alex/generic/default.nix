{
  inputs,
  pkgs,
  lib,
  user,
  nix-colors,
  ...
}: {
  imports = [
    nix-colors.homeManagerModules.default
    ../universals/modules
  ];

  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "24.05";

  # Set a default colorScheme for generic configuration
  colorScheme = nix-colors.colorSchemes.gruvbox-dark-medium;
}
