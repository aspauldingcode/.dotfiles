{ config, lib, ... }:

# To prevent discord from checking for new versions.
{
  home.file.".config/discord/settings.json" = {
    text = builtins.toJSON {
      SKIP_HOST_UPDATE = true;
      chromiumSwitches = {}; # wtf is this?
      IS_MAXIMIZED = false; # not respected?
      IS_MINIMIZED = false;
      # not respected?
      WINDOW_BOUNDS = { 
        x = 727;
        y = 65;
        width = 1920;
        height = 1080;
      };
      THEME = "Dark"; # not respected?
      DANGEROUS_ENABLE_DEVTOOLS_ONLY_IF_YOU_KNOW_WHAT_YOU_ARE_DOING = true;
      BACKGROUND_COLOR = "#000000"; # not respected?
      OPEN_ON_STARTUP = true; # not respected?
    };
  };
}
