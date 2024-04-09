{ config, pkgs, ... }:

# Discocss discord css injector theme
{
  programs.discocss = {
    enable = false;
    discordAlias = false; # Whether to alias discocss to discord.
    package = pkgs.discocss.overrideAttrs (
      old: rec {
        # FIXES for discord 0.0.30, but we on 0.0.42 rn
        version = "0.3.0";
        src = pkgs.fetchFromGitHub {
          owner = "bddvlpr";
          repo = "discocss";
          rev = "v${version}";
          hash = "sha256-2K7SPTvORzgZ1ZiCtS5TOShuAnmtI5NYkdQPRXIBP/I=";
        };
      }
    );
    css =
      let
        inherit (config.colorscheme) colors;
      in
      # css
      ''
        .theme-light {
          --background-primary: #${colors.base00}88;
          --background-primary-alt: #${colors.base01}88;
          --background-secondary: #${colors.base02}88;
          --background-secondary-alt: #${colors.base03}88;
          --background-tertiary: #${colors.base04}88;
        }
      '';

    /* NOTES: If you want your window to be transparent, you have to change the --background- css
       variables to have an alpha value. You can add alpha to a hex color by appending 2 extra hex
       digits to it. Example from my theme (44 is the hex alpha value):
    */
  };
}
