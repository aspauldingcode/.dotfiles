{ config, pkgs, ... }:

# Better-Discord, themes, plugins, and configuration.
{
  home = {
    packages = with pkgs; [
      # discord
      # Using brew to install betterdiscord!
    ];
  };

  ##FIXME: copy instead of symlink?
  #home.file.betterdiscordtheme = {
  #  target = ".config/BetterDiscord/data/stable/themes.json";
  #  force = true;
  #  text = /* json */ ''
  #    {
  #        "NixColors": false
  #    }
  #  '';
  #};

  home.file.betterdiscordthemeconf = {
    target = "Library/Application Support/BetterDiscord/themes/NixColors.theme.css";
    text =
      let
        inherit (config.colorScheme) colors;
      in
      # css
      ''
        /**
        * @name NixColors
        * @description 
        * @author aspauldingcode
        * @version 1.0.0
        * @website https://github.com/aspauldingcode/.dotfiles
        */

        /* For Better Look */
        @import url("https://nyri4.github.io/Discolored/main.css");

        .theme-dark, .theme-light { 

          --header-primary: var(--text-normal);
          --header-secondary: var(--text-muted);

          /*  Text-Color  */
          --text-normal: #${colors.base05};
          --text-muted: #${colors.base06};
          --interactive-normal: #${colors.base05};
          --interactive-hover: #${colors.base06};
          --interactive-active: #${colors.base0A};
          --interactive-muted: #${colors.base07};

          /* Background-Color */
          --background-primary: #${colors.base00}88;
          --background-secondary: #${colors.base00};
          --background-secondary-alt: #${colors.base00};
          --background-tertiary: #${colors.base00}55; /*main background thing actually? */
          --background-tertiary-alt: var(--background-secondary-alt);
          --background-accent: #${colors.base00}55;
          --background-floating: #${colors.base00};
          --background-modifier-hover: #${colors.base04}88;
          --background-modifier-active: #${colors.base04}55;
          --background-modifier-selected: #${colors.base04}88;
          --background-modifier-accent: #${colors.base03};
          --background-mentioned: #${colors.base0A}11;
          --border-mentioned: #${colors.base0A};
          --background-mentioned-hover: #${colors.base0B};
          --accent-color: #${colors.base02};

          /* Folder-Color */
          --folder-color: #${colors.base03}55;
          --folder-color-light: #${colors.base06}55;

          /* Scrollbars-Color */
          --scrollbar-thin-thumb: #${colors.base0C};
          --scrollbar-thin-track: #${colors.base01}55;
          --scrollbar-auto-thumb: #${colors.base04}55;
          --scrollbar-auto-thumb-hover: #${colors.base08};
          --scrollba-auto-track: #${colors.base0E}55;
          --scrollbar-auto-scrollbar-color-thumb: var(--scrollbar-auto-thumb);
          --scrollbar-auto-scrollbar-color-track: var(--scrollbar-auto-track);

          /* Chat Box Color */
          --channeltextarea-background: var(--background-secondary);
          --channeltextarea-background-hover: var(--background-tertiary);    
        }
      '';
  };
}
