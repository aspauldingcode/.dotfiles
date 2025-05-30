{
  config,
  pkgs,
  ...
}:

let
in
/*
  desktop_cleaner = pkgs.writeScriptBin "desktop_cleaner" ''
    #!/bin/bash

    DESKTOP_PATH="$HOME/Desktop"
    REDIRECT_PATH="$HOME/Desktop_Redirect"

    # Create the redirect folder if it doesn't exist
    mkdir -p "$REDIRECT_PATH"

    # Function to check if desktop is empty
    is_desktop_empty() {
      [ -z "$(ls -A "$DESKTOP_PATH")" ]
    }

    # Function to move items and notify if desktop was not empty
    move_and_notify_if_cleaned() {
      if ! is_desktop_empty; then
        mv "$DESKTOP_PATH"/* "$REDIRECT_PATH"
        osascript -e 'display notification "Desktop items have been moved to ~/Desktop_Redirect" with title "Desktop Cleaned"'
      fi
    }

    # Main loop
    while true; do
      move_and_notify_if_cleaned
      sleep 5  # Check every 5 seconds
    done
  '';
*/
{
  environment.systemPackages = with pkgs; [
    # desktop_cleaner
  ];

  launchd = {
    user.agents = {
      toggle-darkmode = {
        serviceConfig = {
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

      alt-tab-macos = {
        serviceConfig = {
          Label = "com.aspauldingcode.alt-tab-macos";
          Program = "${pkgs.alt-tab-macos}/Applications/AltTab.app/Contents/MacOS/AltTab";
          RunAtLoad = true;
          KeepAlive = true;
        };
      };

      dbus-session = {
        serviceConfig = {
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

      /*
        desktop-cleaner = {
          serviceConfig = {
            Label = "com.aspauldingcode.desktop-cleaner";
            ProgramArguments = [
              "${desktop_cleaner}/bin/desktop_cleaner"
            ];
            RunAtLoad = true;
            KeepAlive = true;
            StandardOutPath = "/tmp/desktop_cleaner.log";
            StandardErrorPath = "/tmp/desktop_cleaner.error.log";
          };
        };
      */

      fix-wm = {
        serviceConfig = {
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

      # disable notification center at login
      notificationcenter = {
        serviceConfig = {
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
        serviceConfig = {
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
        serviceConfig = {
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
    };
    daemons = {
      "limit.maxfiles" = {
        serviceConfig = {
          Label = "limit.maxfiles";
          ProgramArguments = [
            "/bin/launchctl"
            "limit"
            "maxfiles"
            "65536"
            "65536"
          ];
          RunAtLoad = true;
        };
      };
    };
  };
}
