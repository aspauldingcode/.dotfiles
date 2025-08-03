{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf pkgs.stdenv.isLinux {
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          output = [
            "eDP-1"
            "HDMI-A-1"
          ];
          modules-left = [
            "sway/workspaces"
            "sway/mode"
          ];
          modules-center = [
            "sway/window"
          ];
          modules-right = [
            "idle_inhibitor"
            "pulseaudio"
            "network"
            "cpu"
            "memory"
            "temperature"
            "backlight"
            "battery"
            "clock"
            "tray"
          ];

          # Modules configuration
          "sway/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
          };
          "sway/mode" = {
            format = "<span style=\"italic\">{}</span>";
          };
          "idle_inhibitor" = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
          };
          tray = {
            # icon-size = 21;
            spacing = 10;
          };
          clock = {
            # timezone = "America/New_York";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            format-alt = "{:%Y-%m-%d}";
          };
          cpu = {
            format = "{usage}% ";
            tooltip = false;
          };
          memory = {
            format = "{}% ";
          };
          temperature = {
            # thermal-zone = 2;
            # hwmon-path = "/sys/class/hwmon/hwmon2/temp1_input";
            critical-threshold = 80;
            # max-length = 7;
            format = "{temperatureC}°C {icon}";
            format-icons = [
              ""
              ""
              ""
            ];
          };
          backlight = {
            # device = "acpi_video1";
            format = "{percent}% {icon}";
            format-icons = [
              ""
              ""
            ];
          };
          battery = {
            states = {
              # good = 95;
              warning = 30;
              critical = 15;
            };
            format = "{capacity}% {icon}";
            format-charging = "{capacity}% ";
            format-plugged = "{capacity}% ";
            format-alt = "{time} {icon}";
            # format-good = ""; // An empty format will hide the module
            # format-full = "";
            format-icons = [
              ""
              ""
              ""
              ""
              ""
            ];
          };
          network = {
            # interface = "wlp2*"; // (Optional) To force the use of this interface
            format-wifi = "{essid} ({signalStrength}%) ";
            format-ethernet = "{ipaddr}/{cidr} ";
            tooltip-format = "{ifname} via {gwaddr} ";
            format-linked = "{ifname} (No IP) ";
            format-disconnected = "Disconnected ⚠";
            format-alt = "{ifname}: {ipaddr}/{cidr}";
          };
          pulseaudio = {
            # scroll-step = 1; // %, can be a float
            format = "{volume}% {icon} {format_source}";
            format-bluetooth = "{volume}% {icon} {format_source}";
            format-bluetooth-muted = " {icon} {format_source}";
            format-muted = " {format_source}";
            format-source = "{volume}% ";
            format-source-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [
                ""
                ""
                ""
              ];
            };
            on-click = "pavucontrol";
          };
        };
      };
      style = ''
        * {
          border: none;
          border-radius: 0;
          font-family: Roboto, Helvetica, Arial, sans-serif;
          font-size: 13px;
          min-height: 0;
        }

        window#waybar {
          background-color: rgba(43, 48, 59, 0.5);
          border-bottom: 3px solid rgba(100, 114, 125, 0.5);
          color: #ffffff;
          transition-property: background-color;
          transition-duration: .5s;
        }

        window#waybar.hidden {
          opacity: 0.2;
        }

        #workspaces button {
          padding: 0 5px;
          background-color: transparent;
          color: #ffffff;
          border-bottom: 3px solid transparent;
        }

        #workspaces button:hover {
          background: rgba(0, 0, 0, 0.2);
          box-shadow: inset 0 -3px #ffffff;
        }

        #workspaces button.focused {
          background-color: #64727D;
          border-bottom: 3px solid #ffffff;
        }

        #workspaces button.urgent {
          background-color: #eb4d4b;
        }

        #mode {
          background-color: #64727D;
          border-bottom: 3px solid #ffffff;
        }

        #clock,
        #battery,
        #cpu,
        #memory,
        #disk,
        #temperature,
        #backlight,
        #network,
        #pulseaudio,
        #custom-media,
        #tray,
        #mode,
        #idle_inhibitor,
        #mpd {
          padding: 0 10px;
          color: #ffffff;
        }

        #window,
        #workspaces {
          margin: 0 4px;
        }

        .modules-left > widget:first-child > #workspaces {
          margin-left: 0;
        }

        .modules-right > widget:last-child > #workspaces {
          margin-right: 0;
        }

        #clock {
          background-color: #64727D;
        }

        #battery {
          background-color: #ffffff;
          color: #000000;
        }

        #battery.charging, #battery.plugged {
          color: #ffffff;
          background-color: #26A65B;
        }

        @keyframes blink {
          to {
            background-color: #ffffff;
            color: #000000;
          }
        }

        #battery.critical:not(.charging) {
          background-color: #f53c3c;
          color: #ffffff;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
        }

        label:focus {
          background-color: #000000;
        }

        #cpu {
          background-color: #2ecc71;
          color: #000000;
        }

        #memory {
          background-color: #9b59b6;
        }

        #disk {
          background-color: #964B00;
        }

        #backlight {
          background-color: #90b1b1;
        }

        #network {
          background-color: #2980b9;
        }

        #network.disconnected {
          background-color: #f53c3c;
        }

        #pulseaudio {
          background-color: #f1c40f;
          color: #000000;
        }

        #pulseaudio.muted {
          background-color: #90b1b1;
          color: #2a5c45;
        }

        #temperature {
          background-color: #f0932b;
        }

        #temperature.critical {
          background-color: #eb4d4b;
        }

        #tray {
          background-color: #2980b9;
        }

        #tray > .passive {
          -gtk-icon-effect: dim;
        }

        #tray > .needs-attention {
          -gtk-icon-effect: highlight;
          background-color: #eb4d4b;
        }

        #idle_inhibitor {
          background-color: #2d3748;
        }

        #idle_inhibitor.activated {
          background-color: #ecf0f1;
          color: #2d3748;
        }

        #mpd {
          background-color: #66cc99;
          color: #2a5c45;
        }

        #mpd.disconnected {
          background-color: #f53c3c;
        }

        #mpd.stopped {
          background-color: #90b1b1;
        }

        #mpd.paused {
          background-color: #51a37a;
        }

        #language {
          background: #00b093;
          color: #740864;
          padding: 0 5px;
          margin: 0 5px;
          min-width: 16px;
        }

        #keyboard-state {
          background: #97e1ad;
          color: #000000;
          padding: 0 0px;
          margin: 0 5px;
          min-width: 16px;
        }

        #keyboard-state > label {
          padding: 0 5px;
        }

        #keyboard-state > label.locked {
          background: rgba(0, 0, 0, 0.2);
        }
      '';
    };
  };
}
