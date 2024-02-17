{ nix-colors, pkgs, ... }:

# Configure color schemes..
let 
  theme = "black-metal-bathory";
  # Choose from: https://nix-community.github.io/nixvim/colorschemes/base16/index.html#colorschemesbase16colorscheme
in
{
  colorScheme = nix-colors.colorSchemes.${theme};

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
