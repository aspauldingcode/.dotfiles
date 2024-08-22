{ config, lib, pkgs, ... }:

{
  home.file.".config/afloaty/config" = {
    force = true; # overwrite the file
    text = builtins.toJSON {
      appSettings = {
        "org.alacritty" = {
          afloaty = {
            isFloating = true;
            isColorInverted = false;
            isDropped = false;
          };
          isColorInverted = true;
        };
        "com.apple.systempreferences" = {
          isFloating = true;
          isColorInverted = true;
          isDropped = false;
        };
        "com.apple.dt.Xcode" = {
          "Welcome to Xcode" = {
            isFloating = true;
          };
        };
      };
      blacklistedBundleIdentifiers = [
        "com.apple.dock"
        "com.vmware.vmware-vmx"
        "com.apple.loginwindow"
        "com.apple.Spotlight"
        "com.apple.SystemUIServer"
        "com.apple.screencaptureui"
      ];
      hotkeyBindings = {
        toggleClickThrough = "Cmd+Shift+C";
        toggleStickyMode = "Cmd+Shift+S";
        toggleInvertColors = "Cmd+Shift+I";
        toggleKeepOnTop = "Cmd+Shift+T";
        toggleTransientMode = "Cmd+Shift+M";
        increaseTransparency = "Cmd+Shift+Up";
        toggleKeepBehind = "Cmd+Shift+B";
        decreaseTransparency = "Cmd+Shift+Down";
        cycleOutlineColor = "Cmd+Shift+O";
      };
      defaultSettings = {
        transientMode = false;
        clickThrough = false;
        keepOnTop = false;
        stickyMode = false;
        outlineWindow = {
          enabled = true;
          width = "2";
          activeColor = "AccentColor";
          inactiveColor = "black";
        };
        transparency = 1;
        invertColors = false;
        keepBehind = false;
      };
      outlineColors = [
        "red"
        "green"
        "blue"
        "yellow"
        "orange"
        "purple"
        "cyan"
        "magenta"
      ];
      transparencyStep = 0.1;
    };
  };
}
