{ config, ... }:

let inherit (config.colorScheme) palette;
in {
  home.file.".config/macwmfx/config" = {
    force = true; # overwrite the file
    text = builtins.toJSON {
      # blacklistedBundleIdentifiers = [
      #   "com.apple.dock"
      #   "com.vmware.vmware-vmx"
      #   "com.apple.loginwindow"
      #   "com.apple.Spotlight"
      #   "com.apple.SystemUIServer"
      #   "com.apple.screencaptureui"
      # ];
      # whitelistedBundleIdentifiers = [ "com.apple.safari" ];
      disableTitlebar = true;
      disableWindowSizeConstraints = true;
      disableTrafficLights = true;
      disableWindowShadow = true;
      outlineWindow = {
        enabled = true;
        type = "inline"; # inline, outline, centerline
        width = 2;
        cornerRadius = 0; # try 10, 40, 0...
        activeColor = "${palette.base07}";
        inactiveColor = "${palette.base05}";
      };
      systemColorSchemeVariant = "${config.colorScheme.variant}";
      transparency = 0.95;
      blurRadius = 10;
      blurPasses = 1;
    };
  };
}
