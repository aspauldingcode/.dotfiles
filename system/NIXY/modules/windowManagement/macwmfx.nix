# assuming you mean a nix-darwin option, i believe there's no nice way to do it.
# once my nix-darwin PR is merged, then
# system.file."Library/Application Support/exampleapp/config".source = <drv>;
# https://github.com/LnL7/nix-darwin/pull/1205

{ config, ... }:

let
  inherit (config.colorScheme) palette;
in
{
  system.file."Library/Application Support/macwmfx/config" = {
    force = true; # overwrite the file
    text = builtins.toJSON {
      disableTitlebar = true;
      disableWindowSizeConstraints = true;
      disableTrafficLights = true;
      disableWindowShadow = true;
      outlineWindow = {
        enabled = true;
        type = "inline"; # inline, outline, centerline
        width = 2;
        cornerRadius = 40; # try 10, 40, 0...
        activeColor = "${palette.base07}";
        inactiveColor = "${palette.base05}";
      };
      systemColorSchemeVariant = "${config.colorScheme.variant}";
      transparency = 0.95;
      blur = {
        enabled = true;
        radius = 10;
        passes = 1;
      };
    };
  };
}
