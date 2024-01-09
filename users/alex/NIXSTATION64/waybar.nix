{ config, lib, pkgs, ... }:

/*Making Waybar follow the Gtk theme
Gtk CSS has some global theme variables, and by using these instead of hardcoded values, Waybar will automatically follow your Gtk theme. An example:

window#waybar {
    background: @theme_base_color;
    border-bottom: 1px solid @unfocused_borders;
    color: @theme_text_color;
}
The Gtk theme variables can be further refined by using the shade, mix, and/or alpha modifiers. For example, if you want to make the bar 25 % lighter and 10 % transparent, you can style the background like this:

window#waybar {
    background: shade(alpha(@borders, 0.9), 1.25);
}
For a list of valid Gtk theme variables, check out Gnome's stylesheet on Gitlab.*/

let
  # Dependencies
  cat = "${pkgs.coreutils}/bin/cat";
  cut = "${pkgs.coreutils}/bin/cut";
  find = "${pkgs.findutils}/bin/find";
  grep = "${pkgs.gnugrep}/bin/grep";
  pgrep = "${pkgs.procps}/bin/pgrep";
  tail = "${pkgs.coreutils}/bin/tail";
  wc = "${pkgs.coreutils}/bin/wc";
  xargs = "${pkgs.findutils}/bin/xargs";
  # timeout = "${pkgs.coreutils}/bin/timeout";
  # ping = "${pkgs.iputils}/bin/ping";

  jq = "${pkgs.jq}/bin/jq";
  systemctl = "${pkgs.systemd}/bin/systemctl";
  journalctl = "${pkgs.systemd}/bin/journalctl";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  playerctld = "${pkgs.playerctl}/bin/playerctld";
  pavucontrol = "${pkgs.pavucontrol}/bin/pavucontrol";
  # wofi = "${pkgs.wofi}/bin/wofi";

  # Function to simplify making waybar outputs
  jsonOutput = name: { pre ? "", text ? "", tooltip ? "", alt ? "", class ? "", percentage ? "" }: "${pkgs.writeShellScriptBin "waybar-${name}" ''
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

  hasSway = config.wayland.windowManager.sway.enable;
  sway = config.wayland.windowManager.sway.package;
  hasHyprland = config.wayland.windowManager.hyprland.enable;
  hyprland = config.wayland.windowManager.hyprland.package;
in
{
  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oa: {
      mesonFlags = (oa.mesonFlags or  [ ]) ++ [ "-Dexperimental=true" ];
    });
    systemd.enable = false;
    settings = {
      primary = {
        mode = "dock";
        layer = "top";
        height = 30;
        margin-top = 10;
        margin-left = 13;
        margin-right = 13;
        position = "top";
        
        modules-left = [
          "custom/menu"
          "sway/workspaces"
          # "custom/gleft"
        ];

        modules-center = [
          "pulseaudio"
          "clock"
          "custom/unread-mail"
          #"custom/gpg-agent"
          "custom/spotify"
          "custom/currentplayer"
          "custom/player"
        ];

        modules-right = [
          "tray"
          "network"
          "battery"
          "custom/tailscale-ping"
          # TODO: currently broken for some reason
          "custom/gammastep"
          #"custom/hostname"
          "cpu"
          "memory"
          "backlight"
        ];
        
        # "custom/gleft" = {
        #   content = [
        #     "custom/menu"
        #     {
        #       class = "left-border-container";
        #       content = [
        #         "sway/workspaces"
        #         "sway/mode"
        #       ];
        #     }
        #   ];
        # };

        "custom/gright" = {

        };

        clock = {
          interval = 1;
          format = "{:%a, %b %d   %r}";
          # on-click = "mode";
          tooltip-format = ''
            <tt><small>{calendar}</small></tt>'';
        };
        pulseaudio = {
          format = "{icon}  {volume}%";
          format-muted = "   0%";
          format-icons = {
            headphone = "󰋋";
            headset = "󰋎";
            portable = "";
            default = [ "󰋋" "󰋋" "󰋋" ];
          };
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
          format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          onclick = "";
        };
        "sway/window" = {
          max-length = 20;
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
          format-wifi = "  {essid}";
          format-ethernet = "󰈁 Connected";
          format-disconnected = "";
          tooltip-format = ''
          {ifname}
          {ipaddr}/{cidr}
          Up: {bandwidthUpBits}
          Down: {bandwidthDownBits}'';
          on-click = ""; #FIXME: Add on-click setup for preview like macos
        };
	      backlight = {
          tooltip = false;
          format = " {}%";
          interval = 1;
          on-scroll-up = "light -A 5";
          on-scroll-down = "light -U 5";
        };
        "custom/spotify" = {
          interval = 1;
          return-type = "json";
          exec = "~/.config/waybar/scripts/spotify.sh";
          exec-if = "pgrep spotify";
          escape = true;
        };
       
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
        "custom/menu" = {
          return-type = "json";
          exec = jsonOutput "menu" {
            text = "";
            tooltip = ''$(${cat} /etc/os-release | ${grep} PRETTY_NAME | ${cut} -d '"' -f2)'';
          };
          on-click-left = "wofi -S drun -x 10 -y 10 -W 25% -H 60%";
          on-click-right = "swaymsg scratchpad show";
        };
        "custom/hostname" = {
          exec = "echo $USER@$HOSTNAME";
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

        "custom/gammastep" = {
          interval = 5;
          return-type = "json";
          exec = jsonOutput "gammastep" {
            pre = ''
              if unit_status="$(${systemctl} --user is-active gammastep)"; then
                status="$unit_status ($(${journalctl} --user -u gammastep.service -g 'Period: ' | ${tail} -1 | ${cut} -d ':' -f6 | ${xargs}))"
              else
                status="$unit_status"
              fi
            '';
            alt = "\${status:-inactive}";
            tooltip = "Gammastep is $status";
          };
          format = "{icon}";
          format-icons = {
            "activating" = "󰁪 ";
            "deactivating" = "󰁪 ";
            "inactive" = "? ";
            "active (Night)" = " ";
            "active (Nighttime)" = " ";
            "active (Transition (Night)" = " ";
            "active (Transition (Nighttime)" = " ";
            "active (Day)" = " ";
            "active (Daytime)" = " ";
            "active (Transition (Day)" = " ";
            "active (Transition (Daytime)" = " ";
          };
          on-click = "${systemctl} --user is-active gammastep && ${systemctl} --user stop gammastep || ${systemctl} --user start gammastep";
        };

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
            "No player active" = " ";
            "Celluloid" = "󰎁 ";
            "spotify" = "󰓇 ";
            "ncspot" = "󰓇 ";
            "qutebrowser" = "󰖟 ";
            "firefox" = " ";
            "discord" = " 󰙯 ";
            "sublimemusic" = " ";
            "kdeconnect" = "󰄡 ";
            "chromium" = " ";
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
    };
    # Cheatsheet:
    # x -> all sides
    # x y -> vertical, horizontal
    # x y z -> top, horizontal, bottom
    # w x y z -> top, right, bottom, left
    style = let inherit (config.colorscheme) colors; in /* css */ ''

* {
  font-family: 'JetBrains Mono', Regular;
  font-size: 8pt;
  padding: 1px;
}

.modules-left,
.modules-center,
.modules-right,
window#waybar,
#custom-menu,
#custom-currentplayer,
#workspaces button,
#workspaces button.hidden,
#workspaces button.focused,
#workspaces button.active,
#clock,
#clock-popup,
#custom-hostname,
#tray,
#pulseaudio,
#memory {
  background-color: #${colors.base00};
  border: 2px solid #${colors.base0C};
  border-radius: 30px;
  color: #${colors.base05};
  padding-left: 16px;
  padding-right: 16px;
  margin: 0px;
}

.modules-left,
.modules-center,
.modules-right {
  margin-top: 8px;
  margin-bottom: 8px;
}

.modules-left,
.modules-center,
.modules-right {
  margin-top: -8px; /* Adjusted padding-top */
	margin-bottom: -8px; /* Adjusted padding-bottom */
	padding-top: 0px;
	padding-bottom: 0px;
}

window#waybar {
  opacity: 0.85;
  border-radius: 10px;
	/* border-left: 0px solid #${colors.base0C}; */
	/* border-right: 0px solid #${colors.base0C};	 */
}

#custom-menu {
  background-color: #${colors.base03};
  border-radius: 30px;
  font-size: 8pt;
  padding-left: 16px;
  padding-right: 19px;
}

#custom-currentplayer {
  background-color: #${colors.base03};
  border-radius: 30px;
}

#workspaces button {
  background-color: #${colors.base00};
  color: #${colors.base05};
  padding-top: 4px;
  padding-bottom: 4px;
  font-size: 8pt;
}

#workspaces button.focused,
#workspaces button.active {
  background-color: #${colors.base0A};
  color: #${colors.base01};
}

#clock,
#memory {
  margin-top: 0px;
  margin-bottom: 0px;
}

#clock-popup {
  background-color: #${colors.base03};
  border: 2px solid #${colors.base0C};
  border-radius: 10px;
  font-size: 16px;
}

#custom-hostname {
  background-color: #${colors.base0C};
  border-radius: 30px;
}

#pulseaudio {
  padding-left: 16px;
}
    '';
  };
}
