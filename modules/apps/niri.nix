{
  # niri — scrollable-tiling Wayland compositor + rice (HM) and system
  # session (NixOS: programs.niri, greetd+gtkgreet, gtklock PAM, plumbing).
  #
  # Coloring comes from the shared Stylix base16 palette; wallpaper is the
  # same `stylix.image` (mountain-sunset). gtkgreet (login) and gtklock
  # (session lock) share CSS from `_gtk-auth-style.nix`.
  #
  # niri does NOT merge a user config.kdl with its built-in defaults — a present
  # config fully replaces them — so the HM half defines a complete keymap + look.

  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.niri;
      wallpaper = config.stylix.image or null;
      authCss = import ../_gtk-auth-style.nix {
        inherit lib pkgs wallpaper;
        colors = config.lib.stylix.colors;
      };
      gtkgreet = pkgs.gtkgreet;
      swayGreeterConfig = pkgs.writeText "greetd-sway-gtkgreet" ''
        # Minimal kiosk compositor for gtkgreet (desktop sway stays disabled).
        exec "${gtkgreet}/bin/gtkgreet -l -s /etc/greetd/gtkgreet.css; ${pkgs.sway}/bin/swaymsg exit"
        bindsym Mod4+shift+e exec ${pkgs.sway}/bin/swaynag \
          -t warning \
          -m 'Power?' \
          -b 'Poweroff' 'systemctl poweroff' \
          -b 'Reboot' 'systemctl reboot'
      '';
    in
    {
      options.dendritic.apps.niri.enable =
        lib.mkEnableOption "niri Wayland compositor (system session + greeter)";

      config = lib.mkIf cfg.enable {
        programs.niri.enable = true;
        # Desktop sway off; greeter still uses pkgs.sway as a kiosk binary.
        programs.sway.enable = lib.mkForce false;

        services.greetd = {
          enable = true;
          settings.default_session = {
            command = "${pkgs.sway}/bin/sway --config ${swayGreeterConfig}";
            user = "greeter";
          };
        };

        environment.etc."greetd/environments".text = ''
          niri-session
        '';
        environment.etc."greetd/gtkgreet.css".text = authCss;

        security.pam.services.gtklock = { };

        environment.variables.NIXOS_OZONE_WL = "1";

        environment.systemPackages = with pkgs; [
          libnotify
          swaybg
          wl-clipboard
          cliphist
          brightnessctl
          playerctl
          pavucontrol
          grim
          slurp
          xwayland-satellite
          foot
        ];
      };
    };

  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.niri;
      c = config.lib.stylix.colors.withHashtag;
      wallpaper = config.stylix.image or null;
      # gtklock's reveal/conceal icons need Adwaita on the icon search path.
      # Force a raster eye into CSS too — SVG/`currentColor` symbolic lookup
      # often shows up as an empty/"missing font" box in GTK3 entries.
      gtklockRevealIcon =
        let
          svg = "${pkgs.adwaita-icon-theme}/share/icons/Adwaita/symbolic/actions/view-reveal-symbolic.svg";
          accent = config.lib.stylix.colors.withHashtag.base0D;
        in
        pkgs.runCommand "gtklock-reveal-eye.png"
          {
            nativeBuildInputs = [
              pkgs.imagemagick
              pkgs.librsvg
            ];
            preferLocalBuild = true;
          }
          ''
            # Rasterize Adwaita's eye, then tint to the Stylix accent.
            rsvg-convert -w 64 -h 64 -o "$out.tmp.png" ${lib.escapeShellArg svg}
            magick "$out.tmp.png" -fill ${lib.escapeShellArg accent} -colorize 100 PNG32:"$out"
            rm -f "$out.tmp.png"
          '';
      authCss = import ../_gtk-auth-style.nix {
        inherit lib pkgs wallpaper;
        colors = config.lib.stylix.colors;
        revealIcon = gtklockRevealIcon;
      };
      gtklockStyle = pkgs.writeText "gtklock-style.css" authCss;
      gtklockGtkConfig = pkgs.writeTextDir "gtk-3.0/settings.ini" ''
        [Settings]
        gtk-icon-theme-name=Adwaita
      '';
      lock = "${pkgs.writeShellScript "gtklock-auth" ''
        export XDG_DATA_DIRS=${lib.escapeShellArg "${pkgs.adwaita-icon-theme}/share"}''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}
        export XDG_CONFIG_HOME=${lib.escapeShellArg gtklockGtkConfig}
        exec ${lib.getExe pkgs.gtklock} -s ${gtklockStyle} "$@"
      ''}";

      # Night-light toggle: wlsunset runs on an auto schedule (see
      # services.wlsunset below); this flips it on/off from the keyboard.
      nightToggle = pkgs.writeShellScriptBin "night-toggle" ''
        notify() {
          ${pkgs.libnotify}/bin/notify-send -t 1500 \
            -h string:x-canonical-private-synchronous:nightlight "Night light" "$1"
        }
        if systemctl --user is-active --quiet wlsunset.service; then
          systemctl --user stop wlsunset.service
          notify "Off"
        else
          systemctl --user start wlsunset.service
          notify "On"
        fi
      '';
    in
    {
      options.dendritic.apps.niri = {
        enable = lib.mkEnableOption "niri Wayland compositor rice";
        terminal = lib.mkOption {
          type = lib.types.str;
          default = "ghostty";
          description = "Command niri spawns for a new terminal (Mod+T / Mod+Return).";
        };
        launcher = lib.mkOption {
          type = lib.types.str;
          default = "fuzzel";
          description = "Command niri spawns for the application launcher (Mod+D).";
        };
      };

      config = lib.mkIf cfg.enable {
        # ── waybar (floating islands) ─────────────────────────────────
        # Let Stylix inject the base16 @define-color vars + fonts, but not its
        # stock CSS; we ship our own design (appended via mkAfter so it lands
        # after Stylix's color definitions).
        stylix.targets.waybar.addCss = false;

        programs.waybar = {
          enable = true;
          systemd.enable = false; # spawned by niri instead, for determinism
          settings.mainBar = {
            layer = "top";
            position = "top";
            height = 34;
            spacing = 4;
            margin-top = 6;
            margin-left = 10;
            margin-right = 10;

            modules-left = [
              "niri/workspaces"
              "niri/window"
            ];
            modules-center = [ "clock" ];
            modules-right = [
              "tray"
              "custom/appearance"
              "custom/power"
              "pulseaudio"
              "network"
              "cpu"
              "memory"
              "battery"
            ];

            "niri/workspaces" = {
              format = "{index}";
            };
            "niri/window" = {
              format = "{title}";
              max-length = 60;
            };
            clock = {
              # Nerd Font (Maple Mono NF) glyphs — not ASCII spaces.
              format = "󰥔 {:%H:%M}";
              format-alt = "󰃭 {:%a %d %b}";
              tooltip-format = "<tt><small>{calendar}</small></tt>";
            };
            cpu = {
              format = "󰍛 {usage}%";
              interval = 2;
            };
            memory = {
              format = "󰘚 {percentage}%";
              interval = 5;
            };
            battery = {
              states = {
                warning = 30;
                critical = 15;
              };
              format = "{icon} {capacity}%";
              format-charging = "󰂄 {capacity}%";
              format-plugged = "󰚥 {capacity}%";
              format-icons = [
                "󰁺"
                "󰁼"
                "󰁾"
                "󰂀"
                "󰁹"
              ];
              interval = 10;
            };
            network = {
              format-wifi = "󰤨 {essid}";
              format-ethernet = "󰈀 {ifname}";
              format-disconnected = "󰤭 offline";
              tooltip-format = "{ifname}: {ipaddr}\nClick: network settings";
              interval = 5;
              on-click = lib.getExe' pkgs.networkmanagerapplet "nm-connection-editor";
            };
            pulseaudio = {
              format = "{icon} {volume}%";
              format-muted = "󰝟 muted";
              format-icons = {
                default = [
                  "󰕿"
                  "󰖀"
                  "󰕾"
                ];
              };
              on-click = "pavucontrol";
              scroll-step = 5;
            };
            tray = {
              spacing = 10;
            };
            "custom/appearance" = {
              exec = "${pkgs.writeShellScript "waybar-dendritic-appearance" ''
                set -euo pipefail
                if command -v dendritic-appearance >/dev/null 2>&1; then
                  dendritic-appearance status --waybar
                else
                  echo '{"text":"󰔎","tooltip":"dendritic-appearance missing","class":"unknown"}'
                fi
              ''}";
              return-type = "json";
              interval = 5;
              on-click = "dendritic-appearance toggle";
              on-click-right = "dendritic-appearance apply --wallpaper next";
            };
            "custom/power" = {
              exec = pkgs.writeShellScript "waybar-dendritic-power" ''
                set -euo pipefail
                f=/run/dendritic-power/status.json
                if [ ! -r "$f" ]; then
                  echo '{"text":"󰓅 —","tooltip":"dendritic-powerd starting"}'
                  exit 0
                fi
                ${pkgs.jq}/bin/jq -c '
                  {
                    text: (
                      (if .state == "quiet" then "󰒮 "
                       elif .state == "audible" then "󰓅 "
                       else "󰈸 " end)
                      + (.pl1_w|tostring) + "W"
                    ),
                    tooltip: (
                      "state=\(.state) reason=\(.reason)\n"
                      + "PL1=\(.pl1_w)W pkg=\(.pkg_w)W temp=\(.pkg_temp)C fan=\(.fan_rpm)\n"
                      + "EPP=\(.epp) workload=\(.workload) docked=\(.docked) AC=\(.ac_online)\n"
                      + "budget=\(.budget_used)"
                    ),
                    class: .state
                  }
                ' "$f"
              '';
              return-type = "json";
              interval = 3;
            };
          };

          # Concentric corners (macOS Tahoe / Apple ConcentricRectangle):
          #   r_inner = max(0, r_outer - gap)  ⇔  r_outer = r_inner + gap
          # Arc centers share one origin so inset thickness stays constant
          # through the curve. GTK3/Waybar has no CSS custom props, so radii
          # are computed in Nix. Refs: bettercorners.io, Cloud Four nested
          # radii, SwiftUI ConcentricRectangle / .concentric(minimum:).
          style =
            let
              # Outer island radius (module pills).
              islandRadius = 12;
              # Uniform inset between island edge and nested chip (all sides).
              nestGap = 3;
              # Inner chip radius — concentric with island.
              chipRadius = lib.max 0 (islandRadius - nestGap);
              # Calendar / module tooltips: match island radius. GTK keeps a
              # separate `decoration` node square unless styled the same —
              # that causes weird corners on first hover (Waybar #5130).
              tooltipRadius = islandRadius;
              # Optional inset between tooltip chrome and label content.
              tooltipPad = 6;
              tooltipLabelRadius = lib.max 0 (tooltipRadius - tooltipPad);
              islandPadX = 12;
              px = n: "${toString n}px";
            in
            lib.mkAfter ''
              window#waybar {
                  background: transparent;
              }

              tooltip {
                  background-color: @base00;
                  border: 1px solid @base0D;
                  border-radius: ${px tooltipRadius};
                  padding: ${px tooltipPad};
              }
              /* GTK decoration stays square by default → corner artifacts
                 on first paint under niri/wlroots. Keep concentric with tooltip. */
              tooltip decoration {
                  border-radius: ${px tooltipRadius};
              }
              tooltip label {
                  color: @base05;
                  border-radius: ${px tooltipLabelRadius};
              }

              #workspaces,
              #window,
              #clock,
              #cpu,
              #memory,
              #battery,
              #network,
              #pulseaudio,
              #custom-power,
              #custom-appearance,
              #tray {
                  background-color: alpha(@base01, 0.92);
                  padding: 0 ${px islandPadX};
                  margin: 4px 3px;
                  border-radius: ${px islandRadius};
              }

              /* Nested chips: gap is parent padding only (uniform on all sides)
                 so r_chip = r_island − gap holds around the full corner. */
              #workspaces {
                  padding: ${px nestGap};
              }
              #workspaces button {
                  padding: 0 8px;
                  margin: 0;
                  color: @base04;
                  background: transparent;
                  border-radius: ${px chipRadius};
                  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
              }
              #workspaces button:hover {
                  background: alpha(@base0D, 0.2);
                  color: @base06;
              }
              #workspaces button.active,
              #workspaces button.focused {
                  background: @base0D;
                  color: @base00;
              }
              #workspaces button.urgent {
                  background: @base08;
                  color: @base00;
              }

              #window {
                  color: @base05;
              }
              window#waybar.empty #window {
                  background: transparent;
              }

              #clock {
                  color: @base0D;
                  font-weight: bold;
              }
              #cpu {
                  color: @base0C;
              }
              #memory {
                  color: @base0E;
              }
              #network {
                  color: @base0D;
              }
              #pulseaudio {
                  color: @base0A;
              }
              #pulseaudio.muted {
                  color: @base04;
              }
              #battery {
                  color: @base0B;
              }
              #battery.warning:not(.charging) {
                  color: @base0A;
              }
              #battery.critical:not(.charging) {
                  color: @base08;
              }
            '';
        };

        # ── fuzzel (launcher) ─────────────────────────────────────────
        # Colors + font come from Stylix; we set the layout/geometry.
        programs.fuzzel.settings = {
          main = {
            layer = "overlay";
            width = 34;
            lines = 10;
            horizontal-pad = 22;
            vertical-pad = 18;
            inner-pad = 10;
            prompt = "\"  \"";
          };
          border = {
            width = 2;
            radius = 14;
          };
        };

        # ── mako (notifications) ──────────────────────────────────────
        services.mako = {
          enable = true;
          settings = {
            width = 380;
            height = 140;
            margin = "10";
            padding = "14";
            border-size = 2;
            border-radius = 14;
            default-timeout = 6000;
            anchor = "top-right";
            max-visible = 5;
            icons = true;
          };
        };

        # ── gtklock (matches gtkgreet login CSS; no HM module on this pin) ──
        home.packages = [
          nightToggle
          pkgs.gtklock
          pkgs.networkmanagerapplet # waybar network → nm-connection-editor
          pkgs.pavucontrol
        ];
        xdg.configFile."gtklock/style.css".source = gtklockStyle;

        # ── night light (wlsunset) ────────────────────────────────────
        # Auto colour-temperature schedule based on location (America/
        # Los_Angeles ≈ 34.05, -118.24). Toggle from the keyboard with the
        # night-toggle script (Mod+Shift+N). Bound to the niri graphical
        # session so it starts/stops with the compositor.
        services.wlsunset = {
          enable = true;
          latitude = 34.05;
          longitude = -118.24;
          temperature = {
            day = 6500;
            night = 3800;
          };
          systemdTarget = "graphical-session.target";
        };

        # ── swayidle (lock + DPMS + suspend) ───────────────────────────
        services.swayidle = {
          enable = true;
          events = {
            before-sleep = lock;
          };
          timeouts = [
            {
              timeout = 300;
              command = lock;
            }
            {
              timeout = 360;
              command = "${lib.getExe pkgs.niri} msg action power-off-monitors";
            }
            {
              # Quiet when away: fans to zero via deep suspend (mem_sleep=deep).
              timeout = 900;
              command = "${pkgs.systemd}/bin/systemctl suspend";
            }
          ];
        };

        # ── niri compositor config ────────────────────────────────────
        xdg.configFile."niri/config.kdl".text = ''
          // Managed by home-manager (dendritic.apps.niri). Edit the Nix module,
          // not this file — it is overwritten on every rebuild.

          input {
              keyboard {
                  xkb {
                      layout "us"
                  }
              }
              touchpad {
                  tap
                  natural-scroll
                  dwt
              }
              mouse {}
              focus-follows-mouse max-scroll-amount="0%"
          }

          // Hybrid graphics: the internal panel is on the Intel iGPU.
          // Run `niri msg outputs` to list connectors and tune scale here.
          output "eDP-1" {
              // scale 1.0
              // transform "normal"
          }

          cursor {
              xcursor-theme "Bibata-Modern-Ice"
              xcursor-size 24
          }

          layout {
              gaps 12
              center-focused-column "never"
              preset-column-widths {
                  proportion 0.33333
                  proportion 0.5
                  proportion 0.66667
              }
              default-column-width { proportion 0.5; }

              focus-ring {
                  width 3
                  active-gradient from="${c.base0D}" to="${c.base0E}" angle=45
                  inactive-color "${c.base02}"
              }

              border {
                  off
              }

              shadow {
                  on
                  softness 30
                  spread 4
                  offset x=0 y=6
                  color "#00000060"
              }

              struts {
                  left 4
                  right 4
                  top 0
                  bottom 4
              }
          }

          prefer-no-csd

          spawn-at-startup "waybar"
          spawn-at-startup "mako"
          spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
          spawn-at-startup "xwayland-satellite" ":0"
          spawn-at-startup "sh" "-c" "wl-paste --watch cliphist store"
          # When dendritic.wallpaper manages the desktop, its apply script owns
          # swaybg (daily cycle). Otherwise fall back to stylix.image.
          ${lib.optionalString (
            wallpaper != null && !(config.dendritic.wallpaper.enable or false)
          ) ''spawn-at-startup "swaybg" "-i" "${wallpaper}" "-m" "fill"''}
          ${lib.optionalString (config.dendritic.wallpaper.enable or false
          ) ''spawn-at-startup "dendritic-wallpaper" "apply" "daily"''}

          // xwayland-satellite provides X11 support; point X clients at it.
          environment {
              DISPLAY ":0"
          }

          screenshot-path "~/Pictures/Screenshots/Screenshot-%Y-%m-%d-%H-%M-%S.png"

          hotkey-overlay {
              skip-at-startup
          }

          // Rounded corners on every window, clipped to the rounded geometry.
          window-rule {
              geometry-corner-radius 10
              clip-to-geometry true
          }

          // Float the audio mixer.
          window-rule {
              match app-id="pavucontrol"
              open-floating true
          }
          window-rule {
              match app-id="nm-connection-editor"
              open-floating true
          }

          binds {
              Mod+Return { spawn "${cfg.terminal}"; }
              Mod+T { spawn "${cfg.terminal}"; }
              Mod+D { spawn "${cfg.launcher}"; }
              Mod+V { spawn "sh" "-c" "cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"; }
              Mod+Q { close-window; }

              Mod+Shift+Slash { show-hotkey-overlay; }

              // Focus
              Mod+Left  { focus-column-left; }
              Mod+Right { focus-column-right; }
              Mod+Up    { focus-window-up; }
              Mod+Down  { focus-window-down; }
              Mod+H     { focus-column-left; }
              Mod+L     { focus-column-right; }
              Mod+K     { focus-window-up; }
              Mod+J     { focus-window-down; }

              // Move
              Mod+Ctrl+Left  { move-column-left; }
              Mod+Ctrl+Right { move-column-right; }
              Mod+Ctrl+Up    { move-window-up; }
              Mod+Ctrl+Down  { move-window-down; }
              Mod+Ctrl+H     { move-column-left; }
              Mod+Ctrl+L     { move-column-right; }
              Mod+Ctrl+K     { move-window-up; }
              Mod+Ctrl+J     { move-window-down; }

              // Monitors
              Mod+Shift+Left  { focus-monitor-left; }
              Mod+Shift+Right { focus-monitor-right; }
              Mod+Shift+Ctrl+Left  { move-column-to-monitor-left; }
              Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }

              // Workspaces
              Mod+Page_Down { focus-workspace-down; }
              Mod+Page_Up   { focus-workspace-up; }
              Mod+1 { focus-workspace 1; }
              Mod+2 { focus-workspace 2; }
              Mod+3 { focus-workspace 3; }
              Mod+4 { focus-workspace 4; }
              Mod+5 { focus-workspace 5; }
              Mod+6 { focus-workspace 6; }
              Mod+7 { focus-workspace 7; }
              Mod+8 { focus-workspace 8; }
              Mod+9 { focus-workspace 9; }

              // Column / window sizing
              Mod+R { switch-preset-column-width; }
              Mod+F { maximize-column; }
              Mod+Shift+F { fullscreen-window; }
              Mod+Minus { set-column-width "-10%"; }
              Mod+Equal { set-column-width "+10%"; }
              Mod+Comma { consume-window-into-column; }
              Mod+Period { expel-window-from-column; }

              // Volume / mic (work while locked); capped so volume can't blow past 100%
              XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "-l" "1.0" "@DEFAULT_AUDIO_SINK@" "0.05+"; }
              XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05-"; }
              XF86AudioMute        allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
              XF86AudioMicMute     allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }

              // Brightness (work while locked)
              XF86MonBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "set" "10%+"; }
              XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "set" "10%-"; }

              // Media transport
              XF86AudioPlay  { spawn "playerctl" "play-pause"; }
              XF86AudioPause { spawn "playerctl" "play-pause"; }
              XF86AudioNext  { spawn "playerctl" "next"; }
              XF86AudioPrev  { spawn "playerctl" "previous"; }
              XF86AudioStop  { spawn "playerctl" "stop"; }

              // Night light toggle
              Mod+Shift+N { spawn "${nightToggle}/bin/night-toggle"; }

              // Screenshots
              Print { screenshot; }
              Ctrl+Print { screenshot-screen; }
              Alt+Print { screenshot-window; }

              // Session (wrapper sets bold reveal icons + style)
              Super+Alt+L { spawn "${lock}"; }
              Mod+Shift+E { quit; }
          }
        '';
      };
    };
}
