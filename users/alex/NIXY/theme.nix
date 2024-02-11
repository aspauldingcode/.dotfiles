{ nix-colors, pkgs, ... }:

# Configure color schemes..
{
  colorScheme = nix-colors.colorSchemes.gruvbox-dark-soft;
  #colorScheme = nix-colors.colorSchemes.dracula;
  #colorScheme = nix-colors.colorSchemes.paraiso;

  /*
  gtk = {
    enable = true;
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
    };
    #theme = {
      #name = "WhiteSur-GTK-Theme";
      #package = pkgs.whitesur-gtk-theme;
      #name = "adw-gtk3";
      #package = pkgs.adw-gtk3;
    #};
    #iconTheme = {
      #name = "WhiteSur-GTK-Icons";
      #package = pkgs.whitesur-icon-theme;
      #name = "Gruvbox-Dark-gtk";
      #package = pkgs.gruvbox-dark-gtk;
      #name = "breeze";
      #package = ;
    #};
  };
  */
  
  /*qt = {
    enable = false;
    platformTheme = "kde";
    # name of gtk theme
    style = {
      #name = "whitesur-kde-unstable";
      #package = pkgs.whitesur-kde;
      #name = "breeze-dark"; # WORKS
      #name = "whitesur-icon-theme";
      #package = pkgs.whitesur-gtk-theme;
    };
  };
  */
}
