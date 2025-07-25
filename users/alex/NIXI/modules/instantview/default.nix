{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.file = {
    "InstantView.plist" = {
      target = "Library/Application Support/InstantView/InstantView.plist";
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>AlreadyBeenLaunched</key>
          <string>3.20 R0003</string>
          <key>AlreadyInstalled</key>
          <string>1</string>
          <key>AppleWatchUnlock</key>
          <integer>1</integer>
          <key>AutoUpdate</key>
          <string>1</string>
          <key>OpenBeforeLogin</key>
          <integer>1</integer>
          <key>PopupAppAtPlugin</key>
          <integer>0</integer>
          <key>SleepInClamshell</key>
          <integer>0</integer>
          <key>UseHiDpi</key>
          <integer>1</integer>
          <key>notLaunchFromLocal</key>
          <integer>1</integer>
        </dict>
        </plist>
      '';
      force = true; # replace backup if it exists already.
    };
  };
}
