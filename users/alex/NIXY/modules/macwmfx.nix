{ config, ... }:

let
  inherit (config.colorScheme) palette;
in
{
  home.file.".config/macwmfx/config" = {
    force = true; # overwrite the file
    text = builtins.toJSON {
      blacklistedBundleIdentifiers = [
        "com.apple.dock"
        "com.vmware.vmware-vmx"
        "com.apple.loginwindow"
        "com.apple.Spotlight"
        "com.apple.SystemUIServer"
        "com.apple.screencaptureui"
      ];
      whitelistedBundleIdentifiers = [ "com.apple.safari" ];
      outlineWindow = {
        enabled = true;
        width = "2";
        cornerRadius = "";
        activeColor = "${palette.base07}";
        inactiveColor = "${palette.base05}";
      };
      transparency = 1.0;
    };
  };
}