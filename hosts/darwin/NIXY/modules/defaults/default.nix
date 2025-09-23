{
  config,
  ...
}:
# To avoid confusion, default.nix is for importing this only.
# Defaults is a macOS configuration tool for setting configuration of .plist files.
{
  system = {
    activationScripts.postActivation.text = ''
      # Following line should allow us to avoid a logout/login cycle
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

      # Disable persistence opening apps at login
      defaults write -g ApplePersistence -bool no

      # Show AirDrop in the sidebar
      defaults write com.apple.sidebarlists systemitems -dict-add ShowAirDrop -bool true

      # Disable the "Are you sure you want to open this application?" dialog
      defaults write com.apple.LaunchServices LSQuarantine -bool false
    '';
    startup.chime = false; # MUTE STARTUP CHIME!
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = false;
      remapCapsLockToEscape = false;
      nonUS.remapTilde = false;
      swapLeftCommandAndLeftAlt = false;
      swapLeftCtrlAndFn = false; # was true, was nice, but fucked up external usb keyboard.
    };
    defaults = {
      smb = {
        NetBIOSName = "${config.networking.hostName}";
        ServerDescription = null;
      };
    };
  };

  # Replace deprecated alf options with new networking.applicationFirewall options
  networking.applicationFirewall = {
    allowSignedApp = true;
    allowSigned = true;
  };
}
