{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  programs.spicetify = let
    spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
  in {
    enable = false; # FIX
    theme = {
      name = "base16";
      src = ./themes/base16;
      appendName = true;
      injectCss = true;
      replaceColors = true;
      overwriteAssets = true;
      sidebarConfig = false; # sidebar config does not work with global navbar. please disable.
    };
    customColorScheme = {
      text = "${config.colorScheme.palette.base05}";
      subtext = "${config.colorScheme.palette.base04}";
      sidebar-text = "${config.colorScheme.palette.base05}";
      main = "${config.colorScheme.palette.base00}";
      sidebar = "${config.colorScheme.palette.base01}";
      player = "${config.colorScheme.palette.base00}";
      card = "${config.colorScheme.palette.base01}";
      shadow = "${config.colorScheme.palette.base01}";
      selected-row = "${config.colorScheme.palette.base02}";
      button = "${config.colorScheme.palette.base0D}";
      button-active = "${config.colorScheme.palette.base0E}";
      button-disabled = "${config.colorScheme.palette.base03}";
      tab-active = "${config.colorScheme.palette.base0D}";
      notification = "${config.colorScheme.palette.base0D}";
      notification-error = "${config.colorScheme.palette.base08}";
      misc = "${config.colorScheme.palette.base03}";
    };
    enabledExtensions = with spicePkgs.extensions; [
      adblock
      hidePodcasts
      shuffle
    ];
  };
}
