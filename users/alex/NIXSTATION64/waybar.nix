{ config, pkgs, ... }:

let
  # Dependencies
  cat = "${pkgs.coreutils}/bin/cat";
  cut = "${pkgs.coreutils}/bin/cut";
  find = "${pkgs.findutils}/bin/find";
  grep = "${pkgs.gnugrep}/bin/grep";
  pgrep = "${pkgs.procps}/bin/pgrep";
  pkill = "${pkgs.coreutils}/bin/pkill";
  tail = "${pkgs.coreutils}/bin/tail";
  wc = "${pkgs.coreutils}/bin/wc";
  xargs = "${pkgs.findutils}/bin/xargs";
  # wlsunset = "${pkgs.wlsunset}/bin/wlsunset";

  jq = "${pkgs.jq}/bin/jq";
  systemctl = "${pkgs.systemd}/bin/systemctl";
  journalctl = "${pkgs.systemd}/bin/journalctl";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  playerctld = "${pkgs.playerctl}/bin/playerctld";
  pavucontrol = "${pkgs.pavucontrol}/bin/pavucontrol";
  darling = "${pkgs.darling}/bin/darling";

  jsonOutput =
    name:
    {
      pre ? "",
      text ? "",
      tooltip ? "",
      alt ? "",
      class ? "",
      percentage ? "",
    }:
    "${pkgs.writeShellScriptBin "waybar-${name}" ''
      set -euo pipefail
      ${pre}
      ${jq} -cn \
      --arg text "${text}" \
      --arg tooltip "${tooltip}" \
      --arg alt "${alt}" \
      --arg class "${class}" \
      --arg percentage "${percentage}" \
      '{text:$text,tooltip:$tooltip,alt:$alt,class:$class,percentage:$percentage}'
    ''}/bin/waybar-${name}";

  commonConfig = {
    modules-left = [
      "custom/menu"
      "sway/workspaces"
      "custom/seperator-left"
      "sway/window"
    ];

    modules-center = [
      "pulseaudio"
      "custom/backlight"
      "custom/wlgammactl"
      "custom/gammastep"
      "custom/brightness-gammastep"
      "custom/datetime"
      #"custom/gpg-agent"
      # "custom/spotify"
      # "cava" # CRASHES at the moment. Waybar v0.10.3
      "custom/currentplayer"
      # "custom/player"
    ];

    modules-right = [
      "custom/unread-mail"
      "tray"
      "network"
      "battery"
      # "custom/tailscale-ping"
      # TODO: currently broken for some reason
      #"custom/hostname"
      "custom/seperator-right"
      "cpu"
      "memory"
    ];

    "tray" = {
      "icon-size" = 14;
      "spacing" = 8;
    };

    "custom/datetime" = {
      interval = 60;
      return-type = "json";
      format = " {}";
      exec = jsonOutput "menu" {
        text = "$DATETIME"; # date "+%a, %b %d  %I:%M %p
        pre = ''
          CAL="$(gcal | awk '{printf "%-21s\n", $0}' | sed -e 's|<|\[|g' -e 's|>|\]|g' -e '/^$/d' | sed -e '1d;$!s/\]$/&/;$!s/$/ /' -e '$!N;s/\n$//')"
          DATETIME=$(date "+%a, %b %d  %I:%M %p") 
        '';
        tooltip = "$CAL";
      };
      on-click = "xdg-open https://calendar.google.com/calendar/";
    };

    cava = {
      # cava_config = "$XDG_CONFIG_HOME/cava/config";
      framerate = 30;
      autosens = 1;
      # sensitivity = 100; # It's recommended to be omitted when autosens = 1
      bars = 10; # number of bars
      lower_cutoff_freq = 50;
      higher_cutoff_freq = 10000;
      sleep_timer = 0; # seconds when cava goes to sleep mode. 0 for disable.
      hide_on_silence = false;
      method = "pipewire";
      source = "auto";
      sample_rate = 44100;
      sample_bits = 16;
      stereo = false;
      reverse = false;
      bar_delimiter = 0;
      monstercat = false;
      waves = false;
      noise_reduction = 0.77;
      input_delay = 2;
      format-icons = [
        "▁"
        "▂"
        "▃"
        "▄"
        "▅"
        "▆"
        "▇"
        "█"
      ];
      actions = {
        on-click-right = "mode";
      };
    };

    "custom/gammastep" = {
      format = "{icon} gammastep";
      format-source = "{icon} gammastep";
      format-icons = [""];
      on-scroll-down = ''
        #!/bin/bash

        # Define min and max temperatures
        MIN_TEMP=3500
        MAX_TEMP=6500

        # Kill other programs
        killall wlsunset
        killall wl-gammactl

        # Always kill gammastep to ensure a clean state
        killall gammastep

        # Read current temperature from state file, or set to max if file doesn't exist
        if [ -f /tmp/gammastep_state ]; then
            current_temp=$(cat /tmp/gammastep_state)
        else
            current_temp=$MAX_TEMP
        fi

        # Decrease temperature
        new_temp=$((current_temp - 200))
        if [ $new_temp -lt $MIN_TEMP ]; then
            new_temp=$MIN_TEMP
        fi
        gammastep -O "$new_temp" &
        echo "$new_temp" > /tmp/gammastep_state
        notify-send -t 700 "Temp $new_temp K"
      '';
      on-scroll-up = ''
        #!/bin/bash

        # Define min and max temperatures
        MIN_TEMP=3500
        MAX_TEMP=6500

        # Kill other programs
        killall wlsunset
        killall wl-gammactl

        # Always kill gammastep to ensure a clean state
        killall gammastep

        # Read current temperature from state file, or set to min if file doesn't exist
        if [ -f /tmp/gammastep_state ]; then
            current_temp=$(cat /tmp/gammastep_state)
        else
            current_temp=$MIN_TEMP
        fi

        # Increase temperature
        new_temp=$((current_temp + 200))
        if [ $new_temp -gt $MAX_TEMP ]; then
            new_temp=$MAX_TEMP
        fi
        gammastep -O "$new_temp" &
        echo "$new_temp" > /tmp/gammastep_state
        notify-send -t 700 "Temp $new_temp K"
      '';
      on-click = ''
        #!/bin/bash

        # Kill other programs
        killall wlsunset
        killall wl-gammactl

        # Read current state
        if [ -f /tmp/gammastep_state ]; then
            current_temp=$(cat /tmp/gammastep_state)
        else
            current_temp=$(cat /tmp/gammastep_state)
        fi

        if pgrep gammastep >/dev/null; then
            killall gammastep
            notify-send -t 700 "RedGlow Stopped"
        else
            gammastep -O "$current_temp" &
            notify-send -t 700 "RedGlow ON"
        fi
      '';
    };
    
    "custom/brightness-gammastep" = {
      format = "󰈋 brightness-gammastep";
      format-source = "{icon} brightness-gammastep";
      format-icons = [""];
      on-scroll-down = ''
        #!/bin/bash

        # Define min and max temperatures and brightness
        MIN_TEMP=3500
        MAX_TEMP=6500
        MIN_BRIGHTNESS=0.1
        MAX_BRIGHTNESS=1.0

        # Kill other programs
        killall wlsunset
        killall wl-gammactl

        # Always kill gammastep to ensure a clean state
        killall gammastep

        # Read current temperature and brightness from state file, or set to defaults if file doesn't exist
        if [ -f /tmp/gammastep_state ]; then
            read current_temp current_brightness <<< $(cat /tmp/gammastep_state)
        else
            current_temp=$MAX_TEMP
            current_brightness=$MAX_BRIGHTNESS
        fi

        # Decrease temperature
        new_temp=$((current_temp - 200))
        if [ $new_temp -lt $MIN_TEMP ]; then
            new_temp=$MIN_TEMP
        fi

        # Decrease brightness
        new_brightness=$(awk "BEGIN {print $current_brightness - 0.05}")
        if (( $(echo "$new_brightness < $MIN_BRIGHTNESS" | bc -l) )); then
            new_brightness=$MIN_BRIGHTNESS
        fi

        gammastep -O "$new_temp" -b "$new_brightness:$new_brightness" &
        echo "$new_temp $new_brightness" > /tmp/gammastep_state
        notify-send -t 700 "Temp $new_temp K, Brightness $new_brightness"
      '';
      on-scroll-up = ''
        #!/bin/bash

        # Define min and max temperatures and brightness
        MIN_TEMP=3500
        MAX_TEMP=6500
        MIN_BRIGHTNESS=0.1
        MAX_BRIGHTNESS=1.0

        # Kill other programs
        killall wlsunset
        killall wl-gammactl

        # Always kill gammastep to ensure a clean state
        killall gammastep

        # Read current temperature and brightness from state file, or set to defaults if file doesn't exist
        if [ -f /tmp/gammastep_state ]; then
            read current_temp current_brightness <<< $(cat /tmp/gammastep_state)
        else
            current_temp=$MIN_TEMP
            current_brightness=$MIN_BRIGHTNESS
        fi

        # Increase temperature
        new_temp=$((current_temp + 200))
        if [ $new_temp -gt $MAX_TEMP ]; then
            new_temp=$MAX_TEMP
        fi

        # Increase brightness
        new_brightness=$(awk "BEGIN {print $current_brightness + 0.05}")
        if (( $(echo "$new_brightness > $MAX_BRIGHTNESS" | bc -l) )); then
            new_brightness=$MAX_BRIGHTNESS
        fi

        gammastep -O "$new_temp" -b "$new_brightness:$new_brightness" &
        echo "$new_temp $new_brightness" > /tmp/gammastep_state
        notify-send -t 700 "Temp $new_temp K, Brightness $new_brightness"
      '';
      on-click = ''
        #!/bin/bash

        # Kill other programs
        killall wlsunset
        killall wl-gammactl

        # Read current state
        if [ -f /tmp/gammastep_state ]; then
            read current_temp current_brightness <<< $(cat /tmp/gammastep_state)
        else
            current_temp=6500
            current_brightness=1.0
        fi

        if pgrep gammastep >/dev/null; then
            killall gammastep
            notify-send -t 700 "RedGlow Stopped"
        else
            gammastep -O "$current_temp" -b "$current_brightness:$current_brightness" &
            notify-send -t 700 "RedGlow ON (Temp: $current_temp K, Brightness: $current_brightness)"
        fi
      '';
    };

    "custom/wlgammactl" = {
      format = "{icon} wlgammactl";
      format-source = "{icon} wlgammactl";
      format-icons = ["󰃞"];
      on-scroll-down = ''
        #!/bin/bash

        # Default brightness
        default_brightness=1.0

        # Kill other programs
        killall gammastep
        killall wlsunset

        # Read current brightness from state file
        if [ -f /tmp/wl_gammactl_state ]; then
            current_brightness=$(cat /tmp/wl_gammactl_state)
        else
            current_brightness=$default_brightness
        fi

        # Check if wl-gammactl is currently running
        if pgrep wl-gammactl >/dev/null; then
            # Decrease the brightness
            new_brightness=$(awk "BEGIN {print $current_brightness - 0.05}")
            
            # Ensure the new brightness is not below 0.5
            if (( $(echo "$new_brightness < 0.5" | bc -l) )); then
                new_brightness=0.5
                notify-send -t 700 "Brightness can't go below 0.5."
            else
                current_gamma=$(awk "BEGIN {print 2 - ($new_brightness - 0.5) * 2}")
                killall wl-gammactl
                wl-gammactl -c 1.000 -b "$new_brightness" -g "$current_gamma" &
                echo "$new_brightness" > /tmp/wl_gammactl_state
                notify-send -t 700 "Brightness $new_brightness, Gamma $current_gamma"
            fi
        else
            wl-gammactl -c 1.000 -b "$current_brightness" -g 1.000 &
            echo "$current_brightness" > /tmp/wl_gammactl_state
            notify-send -t 700 "Brightness Control Started"
        fi
      '';
      
      on-scroll-up = ''
        #!/bin/bash

        # Default brightness
        default_brightness=1.0

        # Kill other programs
        killall gammastep
        killall wlsunset

        # Read current brightness from state file
        if [ -f /tmp/wl_gammactl_state ]; then
            current_brightness=$(cat /tmp/wl_gammactl_state)
        else
            current_brightness=$default_brightness
        fi

        # Check if wl-gammactl is currently running
        if pgrep wl-gammactl >/dev/null; then
            # Increase the brightness
            new_brightness=$(awk "BEGIN {print $current_brightness + 0.05}")
            
            # Ensure the new brightness does not exceed 1.0
            if (( $(echo "$new_brightness > 1.0" | bc -l) )); then
                new_brightness=1.0
                notify-send -t 700 "Brightness can't exceed 1.0."
            else
                current_gamma=$(awk "BEGIN {print 2 - ($new_brightness - 0.5) * 2}")
                killall wl-gammactl
                wl-gammactl -c 1.000 -b "$new_brightness" -g "$current_gamma" &
                echo "$new_brightness" > /tmp/wl_gammactl_state
                notify-send -t 700 "Brightness $new_brightness, Gamma $current_gamma"
            fi
        else
            wl-gammactl -c 1.000 -b "$current_brightness" -g 1.000 &
            echo "$current_brightness" > /tmp/wl_gammactl_state
            notify-send -t 700 "Brightness Control Started"
        fi
      '';
      
      on-click = ''
        #!/bin/bash

        # Kill other programs
        killall gammastep
        killall wlsunset

        if pgrep wl-gammactl >/dev/null; then
            killall wl-gammactl
            notify-send -t 700 "Brightness Control Stopped"
        else
            if [ -f /tmp/wl_gammactl_state ]; then
                saved_brightness=$(cat /tmp/wl_gammactl_state)
                saved_gamma=$(awk "BEGIN {print 2 - ($saved_brightness - 0.5) * 2}")
            else
                saved_brightness=1.0
                saved_gamma=1.0
            fi
            wl-gammactl -c 1.000 -b "$saved_brightness" -g "$saved_gamma" &
            notify-send -t 700 "Brightness Control ON (Brightness: $saved_brightness, Gamma: $saved_gamma)"
        fi
      '';
    };

    pulseaudio = {
      format = "{icon} {volume}%"; # {format_source}";
      format-muted = "󰝟 0%";
      format-source = "Mic ON";
      format_source-muted = "Mic OFF";
      format-icons = {
        headphone = "󰋋";
        headset = "󰋎";
        portable = "";
        default = [
          "󰕿"
          "󰖀"
          "󰖀"
          "󰕾"
        ];
      };
      interval = 10;
      scroll-step = 6;
      on-click = pavucontrol;
    };

    idle_inhibitor = {
      format = "{icon}";
      format-icons = {
        activated = "󰒳";
        deactivated = "󰒲";
      };
    };
    battery = {
      bat = "BAT0";
      interval = 10;
      format-icons = [
        "󰁺"
        "󰁻"
        "󰁼"
        "󰁽"
        "󰁾"
        "󰁿"
        "󰂀"
        "󰂁"
        "󰂂"
        "󰁹"
      ];
      format = "{icon} {capacity}%";
      format-charging = "󰂄 {capacity}%";
      onclick = "";
    };

    "sway/window" = {
      max-length = 25;
      format = "{title}";
      on-click = "swaymsg kill";
      all-outputs = true;
    };

    "sway/workspaces" = {
      disable-scroll = true;
      all-outputs = true;
    };

    cpu = {
      interval = 15;
      format = "  {}%";
      max-length = 10;
    };
    memory = {
      interval = 30;
      format = "  {}%";
      max-length = 10;
    };

    network = {
      interval = 3;
      format-wifi = "󰖩 ";
      format-ethernet = "󰈁 Connected";
      format-disconnected = "";
      tooltip-format = ''
          {essid}
        󱘖  {ifname}
          {ipaddr}/{cidr}
        󱚺  {bandwidthUpBits}
        󱚶  {bandwidthDownBits}'';
      on-click = "nm-connection-editor"; # Open nm-applet menu when clicked
      # on-click-right = "";
    };
    
    "custom/backlight" = {
      exec-if = "light status 2>/dev/null";
      tooltip = false;
      format = " {}%";
      interval = 1;
      on-scroll-up = "light -A 5";
      on-scroll-down = "light -U 5";
    };

    # "custom/spotify" = {
    #   interval = 1;
    #   return-type = "json";
    #   exec = "~/.config/waybar/scripts/spotify.sh";
    #   exec-if = "pgrep spotify";
    #   escape = true;
    # }; 

    # "custom/tailscale-ping" = {
    #   interval = 10;
    #   return-type = "json";
    #   exec =
    #     let
    #       inherit (builtins) concatStringsSep attrNames;
    #       hosts = attrNames outputs.nixosConfigurations;
    #       homeMachine = "merope";
    #       remoteMachine = "alcyone";
    #     in
    #     jsonOutput "tailscale-ping" {
    #       # Build variables for each host
    #       pre = ''
    #         set -o pipefail
    #         ${concatStringsSep "\n" (map (host: ''
    #           ping_${host}="$(${timeout} 2 ${ping} -c 1 -q ${host} 2>/dev/null | ${tail} -1 | ${cut} -d '/' -f5 | ${cut} -d '.' -f1)ms" || ping_${host}="Disconnected"
    #         '') hosts)}
    #       '';
    #       # Access a remote machine's and a home machine's ping
    #       text = "  $ping_${remoteMachine} /  $ping_${homeMachine}";
    #       # Show pings from all machines
    #       tooltip = concatStringsSep "\n" (map (host: "${host}: $ping_${host}") hosts);
    #     };
    #   format = "{}";
    #   on-click = "";
    # };

    "custom/seperator-left" = {
      return-type = "json";
      exec = jsonOutput "seperator-left" {
        text = "";
        # tooltip = ''$(${cat} /etc/os-release | ${grep} PRETTY_NAME | ${cut} -d '"' -f2)'';
      };
    };
    "custom/seperator-right" = {
      return-type = "json";
      exec = jsonOutput "seperator-right" {
        text = "";
        # tooltip = ''$(${cat} /etc/os-release | ${grep} PRETTY_NAME | ${cut} -d '"' -f2)'';
      };
    };

    "custom/menu" = {
      return-type = "json";
      exec = jsonOutput "menu" {
        text = "󱄅";
        pre = ''
          OS="$(${cat} /etc/os-release | ${grep} PRETTY_NAME | ${cut} -d '"' -f2)"
          Kernel="$(uname -s -r -m)"
          Wine="$(wine-version)"'';
        # Darling="$(${darling} shell uname -s -r -m) (Darling)"
        tooltip = ''
          $OS
          $Kernel
          $Wine'';
        # $Darling
      };
    };

    "custom/hostname" = {
      exec = "echo $USER@$HOST";
      on-click = "${systemctl} --user restart waybar";
    };

    "custom/unread-mail" = {
      interval = 5;
      return-type = "json";
      exec = jsonOutput "unread-mail" {
        pre = ''
          count=$(${find} ~/Mail/*/Inbox/new -type f | ${wc} -l)
          if ${pgrep} mbsync &>/dev/null; then
          status="syncing"
          else if [ "$count" == "0" ]; then
          status="read"
          else
          status="unread"
          fi
          fi
        '';
        text = "$count";
        alt = "$status";
      };
      format = "{icon}  ({})";
      format-icons = {
        "read" = "󰇯";
        "unread" = "󰇮";
        "syncing" = "󰁪";
      };
    };

    #"custom/gpg-agent" = {
    #  interval = 2;
    #  return-type = "json";
    #  exec =
    #    let gpgCmds = import ../../../cli/gpg-commands.nix { inherit pkgs; };
    #     in
    #     jsonOutput "gpg-agent" {
    #       pre = ''status=$(${gpgCmds.isUnlocked} && echo "unlocked" || echo "locked")'';
    #       alt = "$status";
    #       tooltip = "GPG is $status";
    #     };
    #   format = "{icon}";
    #   format-icons = {
    #     "locked" = "";
    #     "unlocked" = "";
    #   };
    #   on-click = "";
    # };

    "custom/currentplayer" = {
      interval = 2;
      return-type = "json";
      exec = jsonOutput "currentplayer" {
        pre = ''
          player="$(${playerctl} status -f "{{playerName}}" 2>/dev/null || echo "No player active" | ${cut} -d '.' -f1)"
          count="$(${playerctl} -l 2>/dev/null | ${wc} -l)"
          if ((count > 1)); then
          more=" +$((count - 1))"
          else
          more=""
          fi
        '';
        alt = "$player";
        tooltip = "$player ($count available)";
        text = "$more";
      };
      format = "{icon}{}";
      format-icons = {
        "No player active" = " ";
        "Celluloid" = "󰎁 ";
        "spotify" = " ";
        "ncspot" = " ";
        "qutebrowser" = "󰖟 ";
        "firefox" = " ";
        "discord" = " 󰙯 ";
        "sublimemusic" = " ";
        "kdeconnect" = "󰄡 ";
        "chromium" = " ";
        "brave" = " ";
      };
      on-click = "${playerctld} shift";
      on-click-right = "${playerctld} unshift";
    };

    "custom/player" = {
      exec-if = "${playerctl} status 2>/dev/null";
      exec = ''${playerctl} metadata --format '{"text": "{{title}} - {{artist}}", "alt": "{{status}}", "tooltip": "{{title}} - {{artist}} ({{album}})"}' 2>/dev/null '';
      return-type = "json";
      interval = 2;
      max-length = 30;
      format = "{icon} {}";
      format-icons = {
        "Playing" = "󰏤 🔊";
        "Paused" = "󰐊  ";
        "Stopped" = "󰐊";
      };
      on-click = "${playerctl} play-pause";
    };
  };

  gapsOnConfig = commonConfig // {
    name = "gaps";
    mode = "dock";
    layer = "top";
    # height = 33;
    margin-top = 10;
    margin-left = 10;
    margin-right = 10;
    position = "top";
  };

  gapsOffConfig = commonConfig // {
    name = "gapless";
    start_hidden = true;
    mode = "dock";
    layer = "top";
    # height = 33;
    margin-top = 0;
    margin-left = 0;
    margin-right = 0;
    position = "top";
  };
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      gaps = gapsOnConfig;
      gapsless = gapsOffConfig;
    };
    style =
      let
        inherit (config.colorscheme) colors;
      in
      ''
        window#waybar {
          background-color: alpha(#${colors.base00}, 0.9);
          border: 2px solid #${colors.base05};
        }
        window#waybar.gaps {
          border-radius: 10;
        }
        window#waybar.gapless {
          border-radius: 0;
        }

        window#waybar.hidden {
          opacity: 0.2;
        }

        #workspaces {
          transition: none;
          background: transparent;
          color: #${colors.base04};
          padding: 0px;
          padding-left: 4px;
          /* margin: -8 0px; */
          font-size: 9pt;
        }

        #workspaces button {
          transition: none;
          background: transparent;
          color: #${colors.base04};
          padding: 0px;
          margin: -2px -16px;
          border: none;
        }

        #workspaces button.hover {
          transition: none;
          background: transparent;
          box-shadow: inherit;
          text-shadow: inherit;
          border-radius: inherit;
        }

        #workspaces button.focused {
          transition: none;color: #${colors.base0A};
          font-family: 'JetBrains Mono', Bold;
        }

        .modules-left {
          background-color: #${colors.base00};
          border: 2px solid #${colors.base05};
          border-radius: 30px;
          margin-left: 21px;
          margin-top: 7px;
          margin-bottom: 7px;
          font-family: 'JetBrains Mono', Regular;
          font-size: 9pt;
          color: #${colors.base05};
        }

        .modules-center {
          background-color: #${colors.base00};
          border: 2px solid #${colors.base05};
          border-radius: 30px;
          margin-top: 7px;
          margin-bottom: 7px;
          font-family: 'JetBrains Mono', Regular;
          font-size: 10pt;
          color: #${colors.base05};
        }

        .modules-right {
          background-color: #${colors.base00};
          border: 2px solid #${colors.base05};
          border-radius: 30px;
          margin-top: 7px;
          margin-bottom: 7px;
          margin-right: 21px;
          font-family: 'JetBrains Mono', Regular;
          font-size: 10pt;
          color: #${colors.base05};
        }

        #custom-menu {
          background-color: #${colors.base02};
          border-radius: 30px;
          padding-left: 14px;
          padding-right: 14px;
        }

        #custom-currentplayer { /* SPOTIFY ICON */
          background-color: #${colors.base02};
          border: 0px solid #${colors.base05};
          border-radius: 30px;
          padding-left: 18px;
          padding-right: 14px;
          font-size: 9pt;
        }

        #custom-player {
          padding-left: 8px;
          padding-right: 8px;
        }

        #custom-seperator-left,
        #custom-seperator-right {
          padding-left: 8px;
        }

        #window {
          padding-left: 16px;
          padding-right: 8px;
        }

        #custom-datetime    
        #memory {
          /* margin-top: 0px; */
          /* margin-bottom: 0px; */
        }

        #custom-datetime {
          font-family: 'JetBrains Mono', Regular;
          font-size: 9pt;
          background-color: #${colors.base02};
          border: 0px solid #${colors.base05};
          border-radius: 30px;
          padding-left: 16px;
          padding-right: 16px;
          font-size: 9pt;
        }

        #custom-hostname {
          background-color: #${colors.base0C};
          border-radius: 30px;
        }

        #pulseaudio {
          background-color: #${colors.base00};
          border: 0px solid #${colors.base05};
          border-radius: 30px;
          color: #${colors.base05};
          padding-left: 8px;
          padding-right: 8px;
          margin: 0px;
          font-size: 9pt;
        }

        #custom-backlight {
          background-color: #${colors.base00};
          border: 0px solid #${colors.base05};
          border-radius: 30px;
          color: #${colors.base05};
          padding-left: 8px;
          padding-right: 8px;
          margin: 0px;
          font-size: 9pt;
        }
        
        #custom-wlgammactl {
          background-color: #${colors.base00};
          border: 0px solid #${colors.base05};
          border-radius: 30px;
          color: #${colors.base05};
          padding-left: 8px;
          padding-right: 8px;
          margin: 0px;
          font-size: 9pt;
        }

        #custom-gammastep {
          background-color: #${colors.base00};
          border: 0px solid #${colors.base05};
          border-radius: 30px;
          color: #${colors.base05};
          padding-left: 8px;
          padding-right: 8px;
          margin: 0px;
          font-size: 9pt;
        }

        #custom-brightness-gammastep {
          background-color: #${colors.base00};
          border: 0px solid #${colors.base05};
          border-radius: 30px;
          color: #${colors.base05};
          padding-left: 8px;
          padding-right: 8px;
          margin: 0px;
          font-size: 9pt;
        }

        #cava {
          padding-left: 4px;
          padding-right: 4px;
          font-size: 9pt;
          font-family: 'JetBrains Mono', Regular;      
        }

        #custom-datetime
        #spotify,
        .mail
        {
          background-color: #${colors.base02};
          border: 0px solid #${colors.base05};
          border-radius: 30px;
          padding-left: 16px;
          padding-right: 16px;
        }

        #tray {
          padding-left: 8px;
          padding-right: 8px;
        }

        #network {
          padding-right: 4px;
        }

        #cpu {
          background-color: #${colors.base00};
          border-radius: 30px; 
          padding-left: 16px;
          padding-right: 16px;
          font-size: 9pt;
        }
        #memory {
          background-color: #${colors.base02};
          border: 0px solid #${colors.base05};
          border-radius: 30px;
          padding-left: 16px;
          padding-right: 16px;
          font-size: 9pt;
        }

        tooltip {
          background-color: alpha(#${colors.base00}, 0.95);
          border: 2px solid #${colors.base05};
          border-radius: 10px;
          margin-top: 20px;
        }

        tooltip * {
          color: #${colors.base05};
          font-family: 'JetBrains Mono', Regular;
          font-size: 9pt;
          padding: 6px 5px;
          text-shadow: 3px 3px 4px rgba(0, 0, 0, 0.95);
        }
      '';
  };
  
  services.gammastep = {
    enable = true;
    provider = "manual";
    latitude = 47.658779;
    longitude = -117.426048;
    temperature = {
      day = 5500;
      night = 3500;
    };
    brightness = {
      day = 1.0;
      night = 0.7;
    };
  };
}