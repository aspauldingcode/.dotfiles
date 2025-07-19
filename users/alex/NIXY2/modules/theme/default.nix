{
  nix-colors,
  config,
  pkgs,
  ...
}:
let
  inherit (nix-colors.lib-contrib { inherit pkgs; }) gtkThemeFromScheme;
in
{
  home.pointerCursor = {
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
  };

  gtk = {
    enable = true;
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
    };
    theme = {
      name = "${config.colorScheme.slug}";
      package = gtkThemeFromScheme { scheme = config.colorScheme; };
    };
    gtk3.extraConfig = {
      gtk-decoration-layout = "appmenu:none";
    };
    gtk4.extraConfig = {
      gtk-decoration-layout = "appmenu:none";
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };
}
