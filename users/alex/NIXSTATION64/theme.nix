{
  nix-colors,
  config,
  pkgs,
  ...
}:

# Configure GTK, QT themes, color schemes.. USE NIXOS MODULE
#let 
#  theme = "gruvbox-dark-soft";
#  # Choose from: https://nix-community.github.io/nixvim/colorschemes/base16/index.html#colorschemesbase16colorscheme
#in

let
  inherit (nix-colors.lib-contrib { inherit pkgs; }) gtkThemeFromScheme;
in
{
  #colorScheme = nix-colors.colorSchemes.${theme};

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
      #name = "WhiteSur-GTK-Theme";
      #package = pkgs.whitesur-gtk-theme;
      #name = "adw-gtk3";
      #package = pkgs.adw-gtk3;
    };
    #iconTheme = {
    #name = "WhiteSur-GTK-Icons";
    #package = pkgs.whitesur-icon-theme;
    #name = "Gruvbox-Dark-gtk";
    #package = pkgs.gruvbox-dark-gtk;
    #name = "breeze";
    #package = ;
    #};
  };
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    # name of gtk theme
    #style = {
    #  name = "${config.colorScheme.slug}";
    #  package = gtkThemeFromScheme {scheme = config.colorScheme;};
    #name = "whitesur-kde-unstable";
    #package = pkgs.whitesur-kde;
    #name = "breeze-dark"; # WORKS
    #name = "whitesur-icon-theme";
    #package = pkgs.whitesur-gtk-theme;
    #};
  };
}
