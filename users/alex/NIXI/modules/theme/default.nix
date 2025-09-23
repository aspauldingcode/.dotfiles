{
  nix-colors,
  pkgs,
  ...
}:
# Configure GTK, QT themes, color schemes.. USE NIXOS MODULE
{
  home = {
    packages = with pkgs; [
      # Removed old toggle-theme script - now using universal module
    ];
  };

  gtk = {
    enable = true;
  };
  qt = {
    enable = false;
    platformTheme = "gtk";
    # name of gtk theme
    style = {
    };
  };
}
