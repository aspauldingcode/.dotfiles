{
  config,
  pkgs,
  ...
}: {
  launchd.agents = {
    toggle-darkmode = {
      enable = true;
      config = {
        Label = "com.aspauldingcode.toggle-darkmode";
        ProgramArguments = [
          "toggle-darkmode"
          "${config.colorScheme.variant}"
        ];
        RunAtLoad = true;
        KeepAlive = false;
        StandardOutPath = "/tmp/toggle-darkmode.log";
        StandardErrorPath = "/tmp/toggle-darkmode.error.log";
      };
    };

    dbus-session = {
      enable = true;
      config = {
        Label = "org.aspauldingcode.dbus-session";
        ProgramArguments = [
          "/opt/homebrew/Cellar/dbus/1.14.10/bin/dbus-daemon"
          "--nofork"
          "--session"
        ];
        Sockets = {
          unix_domain_listener = {
            SecureSocketWithKey = "DBUS_LAUNCHD_SESSION_BUS_SOCKET";
          };
        };
      };
    };

    fix-wm = {
      enable = true;
      config = {
        Label = "com.aspauldingcode.fix-wm";
        ProgramArguments = [
          "fix-wm"
        ];
        RunAtLoad = true;
        KeepAlive = false;
        StandardOutPath = "/tmp/fix-wm.log";
        StandardErrorPath = "/tmp/fix-wm.error.log";
      };
    };

    notificationcenter = {
      enable = true;
      config = {
        Label = "com.aspauldingcode.notificationcenter";
        ProgramArguments = [
          "launchctl"
          "unload"
          "-w"
          "/System/Library/LaunchAgents/com.apple.notificationcenterui.plist"
          "&&"
          "killall"
          "NotificationCenter"
        ];
        RunAtLoad = true;
        KeepAlive = false;
        StandardOutPath = "/tmp/notificationcenter.log";
        StandardErrorPath = "/tmp/notificationcenter.error.log";
      };
    };

    unnaturalscrollwheels = {
      enable = true;
      config = {
        Label = "com.aspauldingcode.unnaturalscrollwheels";
        ProgramArguments = [
          "${pkgs.unnaturalscrollwheels}/Applications/UnnaturalScrollWheels.app/Contents/MacOS/UnnaturalScrollWheels"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/unnaturalscrollwheels.log";
        StandardErrorPath = "/tmp/unnaturalscrollwheels.error.log";
      };
    };

    unmenu = {
      enable = true;
      config = {
        Label = "com.aspauldingcode.unmenu";
        ProgramArguments = [
          "/Users/alex/Applications/Home Manager Trampolines/unmenu.app/Contents/MacOS/unmenu"
        ];
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;
          Crashed = true;
        };
        StandardOutPath = "/tmp/unmenu.log";
        StandardErrorPath = "/tmp/unmenu.error.log";
      };
    };

    alacritty = {
      enable = true;
      config = {
        Label = "com.aspauldingcode.alacritty";
        ProgramArguments = [
          "/usr/bin/open"
          "-a"
          "Alacritty"
        ];
        RunAtLoad = true;
        LaunchOnlyOnce = true;
        StandardOutPath = "/tmp/alacritty.log";
        StandardErrorPath = "/tmp/alacritty.error.log";
      };
    };
  };
}
