{ config, pkgs, ... }:

let
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
in
{
  environment.systemPackages = with pkgs; [
    desktop_cleaner
  ];

  environment.launchAgents = {
    "org.flameshot.plist" = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"?>
        <plist version="1.0">
          <dict>
            <key>Label</key>
            <string>com.example.flameshot</string>
            <key>ProgramArguments</key>
            <array>
              <string>${pkgs.flameshot}/Applications/flameshot.app/Contents/MacOS/flameshot</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
          </dict>
        </plist>
      '';
    };

    "com.aspauldingcode.toggle-darkmode.plist" = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"?>
        <plist version="1.0">
          <dict>
            <key>Label</key>
            <string>com.user.toggle-darkmode</string>
            <key>ProgramArguments</key>
            <array>
              <string>toggle-darkmode</string>
              <string>${config.colorScheme.variant}</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
            <key>StandardOutPath</key>
            <string>/tmp/toggle-darkmode.log</string>
            <key>StandardErrorPath</key>
            <string>/tmp/toggle-darkmode.error.log</string>
          </dict>
        </plist>
      '';
    };

    "com.lwouis.alt-tab-macos.plist" = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"?>
        <plist version="1.0">
          <dict>
            <key>AssociatedBundleIdentifiers</key>
            <string>com.lwouis.alt-tab-macos</string>
            <key>Label</key>
            <string>com.lwouis.alt-tab-macos</string>
            <key>LegacyTimers</key>
            <true/>
            <key>LimitLoadToSessionType</key>
            <string>Aqua</string>
            <key>ProcessType</key>
            <string>Interactive</string>
            <key>Program</key>
            <string>/Applications/AltTab.app/Contents/MacOS/AltTab</string>
            <key>RunAtLoad</key>
            <true/>
          </dict>
        </plist>
      '';
    };

    "org.freedesktop.dbus-session.plist" = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"?>
        <plist version="1.0">
          <dict>
            <key>Label</key>
            <string>org.freedesktop.dbus-session</string>

            <key>ProgramArguments</key>
            <array>
              <string>/opt/homebrew/Cellar/dbus/1.14.10/bin/dbus-daemon</string>
              <string>--nofork</string>
              <string>--session</string>
            </array>

            <key>Sockets</key>
            <dict>
              <key>unix_domain_listener</key>
              <dict>
                <key>SecureSocketWithKey</key>
                <string>DBUS_LAUNCHD_SESSION_BUS_SOCKET</string>
              </dict>
            </dict>
          </dict>
        </plist>
      '';
    };

    "com.example.macforgehelper.plist" = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0.dtd"?>
        <plist version="1.0">
          <dict>
            <key>Label</key>
            <string>com.example.macforgehelper</string>
            <key>ProgramArguments</key>
            <array>
              <string>/Applications/MacForge.app/Contents/MacOS/MacForgeHelper</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
          </dict>
        </plist>
      '';
    };

    "org.nix-community.home.xdg_cache_home.plist" = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"?>
        <plist version="1.0">
          <dict>
            <key>Label</key>
            <string>org.nix-community.home.xdg_cache_home</string>
            <key>Program</key>
            <string>/bin/launchctl</string>
            <key>ProgramArguments</key>
            <array>
              <string>/bin/launchctl</string>
              <string>unload</string>
              <string>-F</string>
              <string>/System/Library/LaunchAgents/com.apple.OSDUIHelper.plist</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>StandardErrorPath</key>
            <string>/dev/null</string>
            <key>StandardOutPath</key>
            <string>/dev/null</string>
          </dict>
        </plist>
      '';
    };

    "com.user.desktop-cleaner.plist" = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
          <dict>
            <key>Label</key>
            <string>com.user.desktop-cleaner</string>
            <key>ProgramArguments</key>
            <array>
              <string>${desktop_cleaner}/bin/desktop_cleaner</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
            <key>StandardOutPath</key>
            <string>/tmp/desktop_cleaner.log</string>
            <key>StandardErrorPath</key>
            <string>/tmp/desktop_cleaner.error.log</string>
          </dict>
        </plist>
      '';
    };

    "com.user.fix-wm.plist" = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
          <dict>
            <key>Label</key>
            <string>com.user.fix-wm</string>
            <key>ProgramArguments</key>
            <array>
              <string>fix-wm</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
            <key>StandardOutPath</key>
            <string>/tmp/fix-wm.log</string>
            <key>StandardErrorPath</key>
            <string>/tmp/fix-wm.error.log</string>
          </dict>
        </plist>
      '';
    };

    # disable notification center at login
    notificationcenter = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
          <dict>
            <key>Label</key>
            <string>com.user.notificationcenter</string>
            <key>ProgramArguments</key>
            <array>
              <string>launchctl</string>
              <string>unload</string>
              <string>-w</string>
              <string>/System/Library/LaunchAgents/com.apple.notificationcenterui.plist</string>
              <string>&&</string>
              <string>killall</string>
              <string>NotificationCenter</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
            <key>StandardOutPath</key>
            <string>/tmp/notificationcenter.log</string>
            <key>StandardErrorPath</key>
            <string>/tmp/notificationcenter.error.log</string>
          </dict>
        </plist>
      '';
    };
  };

  environment.launchDaemons = {
    "com.macenhance.MacForge.Injector.plist" = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>com.macenhance.MacForge.Injector</string>
          <key>MachServices</key>
          <dict>
            <key>com.macenhance.MacForge.Injector.mach</key>
            <true/>
          </dict>
          <key>Program</key>
          <string>/Library/PrivilegedHelperTools/com.macenhance.MacForge.Injector</string>
          <key>ProgramArguments</key>
          <array>
            <string>/Library/PrivilegedHelperTools/com.macenhance.MacForge.Injector</string>
          </array>
        </dict>
        </plist>
      '';
    };

    "dev.orbstack.OrbStack.privhelper.plist" = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>AssociatedBundleIdentifiers</key>
          <array>
            <string>dev.kdrag0n.MacVirt</string>
          </array>
          <key>Label</key>
          <string>dev.orbstack.OrbStack.privhelper</string>
          <key>MachServices</key>
          <dict>
            <key>dev.orbstack.OrbStack.privhelper</key>
            <true/>
          </dict>
          <key>Program</key>
          <string>/Library/PrivilegedHelperTools/dev.orbstack.OrbStack.privhelper</string>
          <key>ProgramArguments</key>
          <array>
            <string>/Library/PrivilegedHelperTools/dev.orbstack.OrbStack.privhelper</string>
          </array>
        </dict>
        </plist>
      '';
    };

    "com.bearisdriving.BGM.App.plist" = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0.dtd"?>
        <plist version="1.0">
          <dict>
            <key>Label</key>
            <string>com.bearisdriving.BGM.App</string>
            <key>ProgramArguments</key>
            <array>
              <string>/Applications/Background Music.app/Contents/MacOS/Background Music</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
          </dict>
        </plist>
      '';
    };

    "com.smiUsbDisplay.macOSInstantView.plist" = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0.dtd"?>
        <plist version="1.0">
          <dict>
            <key>Label</key>
            <string>com.smiUsbDisplay.macOSInstantView</string>
            <key>ProgramArguments</key>
            <array>
              <string>/Applications/macOS InstantView.app/Contents/MacOS/macOS InstantView</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
          </dict>
        </plist>
      '';
    };

    "com.smiUsbDisplay.macOSInstantView.loginscreen.plist" = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
          <dict>
            <key>Label</key>
            <string>com.smiUsbDisplay.macOSInstantView.loginscreen</string>
            <key>LimitLoadToSessionType</key>
            <string>LoginWindow</string>
            <key>Program</key>
            <string>/Applications/macOS InstantView.app/Contents/MacOS/macOS InstantView</string>
            <key>ProgramArguments</key>
            <array>
              <string>/Applications/macOS InstantView.app/Contents/MacOS/macOS InstantView</string>
              <string>LoginWindow</string>
            </array>
            <key>ProcessType</key>
            <string>Interactive</string>
            <key>ThrottleInterval</key>
            <integer>5</integer>
            <key>Disabled</key>
            <false/>
            <key>Umask</key>
            <integer>0</integer>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
          </dict>
        </plist>
      '';
    };

    "org.xquartz.privileged_startx.plist" = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>org.xquartz.privileged_startx</string>
          <key>ProgramArguments</key>
          <array>
            <string>/opt/X11/libexec/privileged_startx</string>
            <string>-d</string>
            <string>/opt/X11/etc/X11/xinit/privileged_startx.d</string>
          </array>
          <key>MachServices</key>
          <dict>
            <key>org.xquartz.privileged_startx</key>
            <true/>
          </dict>
          <key>TimeOut</key>
          <integer>120</integer>
          <key>EnableTransactions</key>
          <true/>
        </dict>
        </plist>
      '';
    };

    "com.bearisdriving.BGM.XPCHelper.plist" = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <!--
          Installing/upgrading overwrites this file (/Library/LaunchDaemons/com.bearisdriving.BGM.XPCHelper.plist), so
          you might not want to edit it directly.
        -->
        <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>com.bearisdriving.BGM.XPCHelper</string>
          <key>ProgramArguments</key>
          <array>
            <string>/usr/local/libexec/BGMXPCHelper.xpc/Contents/MacOS/BGMXPCHelper</string>
          </array>
          <key>MachServices</key>
          <dict>
            <key>com.bearisdriving.BGM.XPCHelper</key>
            <true/>
          </dict>
          <key>ProcessType</key>
          <string>Adaptive</string>
          <key>UserName</key>
          <string>_BGMXPCHelper</string>
          <key>GroupName</key>
          <string>_BGMXPCHelper</string>
        </dict>
        </plist>
      '';
    };

    "com.docker.socket.plist" = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>KeepAlive</key>
          <false/>
          <key>Label</key>
          <string>com.docker.socket</string>
          <key>ProcessType</key>
          <string>Background</string>
          <key>Program</key>
          <string>/Library/PrivilegedHelperTools/com.docker.socket</string>
          <key>ProgramArguments</key>
          <array>
            <string>/Library/PrivilegedHelperTools/com.docker.socket</string>
            <string>/Users/alex/.docker/run/docker.sock</string>
            <string>/var/run/docker.sock</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
        </dict>
        </plist>
      '';
    };

    "com.docker.vmnetd.plist" = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>com.docker.vmnetd</string>
          <key>Program</key>
          <string>/Library/PrivilegedHelperTools/com.docker.vmnetd</string>
          <key>ProgramArguments</key>
          <array>
            <string>/Library/PrivilegedHelperTools/com.docker.vmnetd</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
          <key>Sockets</key>
          <dict>
            <key>Listener</key>
            <dict>
              <key>SockPathMode</key>
              <integer>438</integer>
              <key>SockPathName</key>
              <string>/var/run/com.docker.vmnetd.sock</string>
            </dict>
          </dict>
          <key>Version</key>
          <string>67</string>
        </dict>
        </plist>
      '';
    };
  };

  launchd.user.agents.startMacForge = {
    serviceConfig = {
      Label = "com.user.startMacForge";
      ProgramArguments = [ "${pkgs.bash}/bin/bash" "${pkgs.writeScript "start-macforge" ''
        #!/bin/bash

        # Function to check if MacForge is running
        is_macforge_running() {
            pgrep -x "MacForge" > /dev/null
        }

        # Start MacForge if it is not running
        if ! is_macforge_running; then
            open -a "MacForge" --hide
            sleep 5  # Wait for a few seconds to allow MacForge to start
        fi

        # Check again if MacForge is running
        if is_macforge_running; then

            # Close the MacForge app window
            osascript -e 'tell application "MacForge" to quit' > /dev/null 2>&1
            
            killall Finder
            sleep 2  # Wait for a few seconds to allow Finder to close
            if ! pgrep -x "Finder" > /dev/null; then
                open -a "Finder"
            fi
        fi
      ''}" ];
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/tmp/startMacForge.log";
      StandardErrorPath = "/tmp/startMacForge.error.log";
    };
  };

  launchd.user.agents.unmenu = {
    serviceConfig = {
      Label = "com.unmanbearpig.unmenu";
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
}
