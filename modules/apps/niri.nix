{
  # niri — scrollable-tiling Wayland compositor + rice (HM) and system
  # session (NixOS: programs.niri, greetd+gtkgreet, gtklock PAM, plumbing).
  #
  # Coloring comes from the shared Stylix base16 palette. gtkgreet and
  # gtklock both use the *desktop-current* wallpaper (1:1) via runtime CSS
  # placeholders + `/var/lib/dendritic/auth/current.tsv`. Chrome (avatar,
  # buttons, fonts) comes from `_gtk-auth-style.nix`.
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
      wallpaperFallback = if wallpaper == null then "" else toString wallpaper;
      # Same raster eye as HM gtklock so greetd/gtklock CSS stay aligned.
      greetRevealIcon =
        let
          svg = "${pkgs.adwaita-icon-theme}/share/icons/Adwaita/symbolic/actions/view-reveal-symbolic.svg";
          accent = config.lib.stylix.colors.withHashtag.base0D;
        in
        pkgs.runCommand "gtkgreet-reveal-eye.png"
          {
            nativeBuildInputs = [
              pkgs.imagemagick
              pkgs.librsvg
            ];
            preferLocalBuild = true;
          }
          ''
            rsvg-convert -w 64 -h 64 -o "$out.tmp.png" ${lib.escapeShellArg svg}
            magick "$out.tmp.png" -fill ${lib.escapeShellArg accent} -colorize 100 PNG32:"$out"
            rm -f "$out.tmp.png"
          '';
      # Prefer declarative dendritic profile photo when enabled.
      authAvatar =
        if (config.dendritic.profilePhoto.enable or false) then
          pkgs.runCommand "dendritic-auth-profile.jpg"
            {
              nativeBuildInputs = [ pkgs.imagemagick ];
              src = config.dendritic.profilePhoto.source;
            }
            ''
              magick "$src" \
                -auto-orient -resize '512x512^' -gravity center -extent 512x512 \
                -strip -quality 92 JPEG:"$out"
            ''
        else
          null;
      # Runtime wallpaper placeholders — filled by gtkgreet-auth from desktop current.
      authCss = import ../_gtk-auth-style.nix {
        inherit lib pkgs;
        colors = config.lib.stylix.colors;
        revealIcon = greetRevealIcon;
        fontFamily = config.stylix.fonts.sansSerif.name or "Inter";
        runtimeWallpaper = true;
        wallpaper = null;
        avatar = authAvatar;
      };
      gtkgreetStyleTemplate = pkgs.writeText "gtkgreet-style.template.css" authCss;
      gtkgreet = pkgs.gtkgreet;
      appearanceBin = lib.getExe (pkgs.callPackage ./dendritic-appearance/_package.nix { });
      gtkgreetAuth = pkgs.writeShellScript "gtkgreet-auth" ''
        set -euo pipefail
        runtime="''${XDG_RUNTIME_DIR:-/tmp}"
        css="$runtime/gtkgreet-style.css"
        image=""
        blur=""
        if [ -r /var/lib/dendritic/auth/current.tsv ]; then
          IFS=$'\t' read -r image blur < /var/lib/dendritic/auth/current.tsv || true
        fi
        if [ -z "''${image:-}" ] || [ ! -f "$image" ]; then
          if paths="$(${appearanceBin} wallpaper auth-path 2>/dev/null | ${pkgs.coreutils}/bin/tail -n1)"; then
            IFS=$'\t' read -r image blur <<< "$paths" || true
          fi
        fi
        if [ -z "''${image:-}" ] || [ ! -f "$image" ]; then
          image=${lib.escapeShellArg wallpaperFallback}
          blur="$image"
        fi
        if [ -z "''${blur:-}" ] || [ ! -f "$blur" ]; then
          blur="$image"
        fi
        ${pkgs.gnused}/bin/sed \
          -e "s|__DENDRITIC_AUTH_WALLPAPER__|file://''${image}|g" \
          -e "s|__DENDRITIC_AUTH_WALLPAPER_BLUR__|file://''${blur}|g" \
          ${gtkgreetStyleTemplate} > "$css"
        exec ${gtkgreet}/bin/gtkgreet -l -s "$css" "$@"
      '';
      swayGreeterConfig = pkgs.writeText "greetd-sway-gtkgreet" ''
        # Minimal kiosk compositor for gtkgreet (desktop sway stays disabled).
        exec "${gtkgreetAuth}; ${pkgs.sway}/bin/swaymsg exit"
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

        # Greeter needs a real home (not /var/empty) so wireplumber/state can exist;
        # we still mask portals/pipewire so the kiosk stays quiet.
        users.users.greeter = {
          home = "/var/lib/greeter";
          createHome = true;
        };

        systemd.tmpfiles.rules = [
          "d /var/lib/greeter 0755 greeter greeter -"
          "d /var/lib/greeter/.config 0755 greeter greeter -"
          "d /var/lib/greeter/.config/systemd 0755 greeter greeter -"
          "d /var/lib/greeter/.config/systemd/user 0755 greeter greeter -"
          "d /var/lib/dendritic/auth 0775 root users -"
        ];

        # Mask heavy desktop user units for the greeter kiosk session.
        system.activationScripts.dendriticGreeterMasks.text = ''
          maskdir=/var/lib/greeter/.config/systemd/user
          mkdir -p "$maskdir"
          for u in xdg-desktop-portal.service xdg-desktop-portal-gtk.service \
                   xdg-desktop-portal-gnome.service pipewire.service \
                   pipewire-pulse.service wireplumber.service; do
            ln -sfn /dev/null "$maskdir/$u"
          done
          chown -R greeter:greeter /var/lib/greeter/.config 2>/dev/null || true
        '';

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
        # Fallback baked CSS (placeholders unresolved) — live path uses gtkgreet-auth.
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
      # Cycle Sword keyboard backlight via HID tool (never EC / msi-ec LED).
      # Exit 2 = no HID device yet (Windows factory path); soft-fail for keybinds.
      kbdBacklightCycle = pkgs.writeShellScript "kbd-backlight-cycle" ''
        set -euo pipefail
        if command -v dendritic-sword-kbd-bl >/dev/null 2>&1; then
          dendritic-sword-kbd-bl cycle && exit 0
          ec=$?
          if [ "$ec" = 2 ]; then
            echo "kbd-backlight-cycle: no SteelSeries/MSIKLM HID (see docs/re/sword-kbd-bl/STATUS.md)" >&2
            exit 0
          fi
          exit "$ec"
        fi
        # Legacy fallback: msi-ec LED (disabled on Sword 15 A11UD).
        d=msiacpi::kbd_backlight
        if ! ${lib.getExe pkgs.brightnessctl} -d "$d" info >/dev/null 2>&1; then
          echo "kbd-backlight-cycle: no HID tool and no $d" >&2
          exit 0
        fi
        cur="$(${lib.getExe pkgs.brightnessctl} -d "$d" g)"
        max="$(${lib.getExe pkgs.brightnessctl} -d "$d" m)"
        ${lib.getExe pkgs.brightnessctl} -d "$d" set $(( (cur + 1) % (max + 1) ))
      '';
      # Waybar scroll + XF86 volume keys: adjust sink, then play the freedesktop
      # volume-change click (same cue as GNOME/KDE volume sliders).
      volumeAdjust =
        let
          click = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/audio-volume-change.oga";
          wpctl = "${pkgs.wireplumber}/bin/wpctl";
          # Detached player — must outlive waybar's scroll helper (SIGHUP on exit).
          volumeClick = pkgs.writeShellScript "dendritic-volume-click" ''
            set -eu
            click=${lib.escapeShellArg click}
            paplay=${lib.escapeShellArg "${pkgs.pulseaudio}/bin/paplay"}
            pactl=${lib.escapeShellArg "${pkgs.pulseaudio}/bin/pactl"}
            preferred=""
            speaker=""
            other=""
            while IFS=$'\t' read -r _ name _; do
              case "$name" in
                *[Hh][Dd][Mm][Ii]*|*DisplayPort*|*SMI*|*Silicon_Motion*|*usb-*[Dd]isplay*)
                  continue
                  ;;
                *[Ss]carlett*|*Focusrite*|*Headphones*|*Headphone*)
                  preferred="$name"
                  ;;
                *[Ss]peaker*)
                  speaker="$name"
                  ;;
                *)
                  [ -n "$other" ] || other="$name"
                  ;;
              esac
            done < <("$pactl" list short sinks 2>/dev/null || true)
            target="''${preferred:-''${speaker:-$other}}"
            if [ -z "$target" ]; then
              # Last resort: whatever is currently default (may be silent USB display).
              "$paplay" "$click" >/dev/null 2>&1 || true
              exit 0
            fi
            "$paplay" -d "$target" "$click" >/dev/null 2>&1 || true
          '';
        in
        pkgs.writeShellScript "dendritic-volume" ''
          set -euo pipefail
          case "''${1:-}" in
            up)   ${wpctl} set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
            down) ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
            mute) ${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
            *)
              echo "usage: dendritic-volume up|down|mute" >&2
              exit 2
              ;;
          esac
          if [ "''${1}" = mute ]; then
            if ${wpctl} get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q MUTED; then
              exit 0
            fi
          fi
          # systemd-run keeps the click alive after waybar's helper exits.
          ${pkgs.systemd}/bin/systemd-run --user --quiet --collect \
            --unit="dendritic-vol-click-$RANDOM" \
            ${volumeClick}
        '';
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
      authAvatar =
        if (config.dendritic.profilePhoto.enable or false) then
          pkgs.runCommand "dendritic-auth-profile.jpg"
            {
              nativeBuildInputs = [ pkgs.imagemagick ];
              src = config.dendritic.profilePhoto.source;
            }
            ''
              magick "$src" \
                -auto-orient -resize '512x512^' -gravity center -extent 512x512 \
                -strip -quality 92 JPEG:"$out"
            ''
        else
          null;
      authCss = import ../_gtk-auth-style.nix {
        inherit lib pkgs;
        colors = config.lib.stylix.colors;
        revealIcon = gtklockRevealIcon;
        fontFamily = config.stylix.fonts.sansSerif.name or "Inter";
        # Wallpaper injected at lock time = desktop current (1:1).
        runtimeWallpaper = true;
        wallpaper = null;
        avatar = authAvatar;
      };
      gtklockStyleTemplate = pkgs.writeText "gtklock-style.template.css" authCss;
      gtklockGtkConfig = pkgs.writeTextDir "gtk-3.0/settings.ini" ''
        [Settings]
        gtk-icon-theme-name=Adwaita
      '';
      appearanceBin = lib.getExe (pkgs.callPackage ./dendritic-appearance/_package.nix { });
      wallpaperFallback = if wallpaper == null then "" else toString wallpaper;
      # Shared CSS/wallpaper prep for gtklock (timeout lock + before-sleep).
      # Prints css path on stdout; sets XDG_* in the calling shell via eval-friendly
      # side effect — callers source this and read CSS_PATH.
      gtklockPrep = pkgs.writeShellScript "gtklock-prep-css" ''
        set -euo pipefail
        export XDG_DATA_DIRS=${lib.escapeShellArg "${pkgs.adwaita-icon-theme}/share"}''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}
        export XDG_CONFIG_HOME=${lib.escapeShellArg gtklockGtkConfig}

        runtime="''${XDG_RUNTIME_DIR:-/tmp}"
        css="$runtime/gtklock-style.css"
        image=""
        blur=""
        if [ -r /var/lib/dendritic/auth/current.tsv ]; then
          IFS=$'\t' read -r image blur < /var/lib/dendritic/auth/current.tsv || true
        fi
        if [ -z "''${image:-}" ] || [ ! -f "$image" ]; then
          if paths="$(${appearanceBin} wallpaper auth-path 2>/dev/null | ${pkgs.coreutils}/bin/tail -n1)"; then
            IFS=$'\t' read -r image blur <<< "$paths" || true
          fi
        fi
        if [ -z "''${image:-}" ] || [ ! -f "$image" ]; then
          image=${lib.escapeShellArg wallpaperFallback}
          blur="$image"
        fi
        if [ -z "''${blur:-}" ] || [ ! -f "$blur" ]; then
          blur="$image"
        fi

        ${pkgs.gnused}/bin/sed \
          -e "s|__DENDRITIC_AUTH_WALLPAPER__|file://''${image}|g" \
          -e "s|__DENDRITIC_AUTH_WALLPAPER_BLUR__|file://''${blur}|g" \
          ${gtklockStyleTemplate} > "$css"
        printf '%s\n' "$css"
      '';

      # Idle-timeout lock: hold sleep:block from gtklock start through post-unlock
      # grace with no gap (avoids unlock→instant-suspend bounce).
      lock = "${pkgs.writeShellScript "gtklock-auth" ''
        set -euo pipefail
        export XDG_DATA_DIRS=${lib.escapeShellArg "${pkgs.adwaita-icon-theme}/share"}''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}
        export XDG_CONFIG_HOME=${lib.escapeShellArg gtklockGtkConfig}
        # Already locked (timeout + before-sleep can race).
        if ${pkgs.procps}/bin/pgrep -x gtklock >/dev/null 2>&1; then
          exit 0
        fi
        css="$(${gtklockPrep})"
        runtime="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
        graceSec=180
        # Export for gtklock child (icons / config).
        export XDG_DATA_DIRS XDG_CONFIG_HOME
        exec ${pkgs.systemd}/bin/systemd-inhibit \
          --what=sleep --who=gtklock --why='session locked + post-unlock grace' --mode=block \
          ${pkgs.bash}/bin/bash -c '
            set -euo pipefail
            export XDG_DATA_DIRS="$4"
            export XDG_CONFIG_HOME="$5"
            ${lib.getExe pkgs.gtklock} -s "$1" || true
            ${pkgs.coreutils}/bin/date +%s >"$2/dendritic-suspend-grace"
            ${lib.getExe pkgs.niri} msg action power-on-monitors >/dev/null 2>&1 || true
            exec ${pkgs.coreutils}/bin/sleep "$3"
          ' bash "$css" "$runtime" "$graceSec" "$XDG_DATA_DIRS" "$XDG_CONFIG_HOME"
      ''}";

      # before-sleep: daemonize so swayidle -w can return before InhibitDelayMaxSec;
      # do not hold sleep:block here (that would fight logind suspend).
      # Stop wlsunset first so niri can restore identity gamma while DRM is healthy
      # (stuck warm LUT after wake is a common hybrid/EVDI failure mode).
      lockBeforeSleep = "${pkgs.writeShellScript "gtklock-before-sleep" ''
        set -euo pipefail
        runtime="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
        if ${pkgs.systemd}/bin/systemctl --user is-active --quiet wlsunset.service 2>/dev/null; then
          ${pkgs.coreutils}/bin/touch "$runtime/dendritic-wlsunset-was-active"
          ${pkgs.systemd}/bin/systemctl --user stop wlsunset.service 2>/dev/null || true
        fi
        export XDG_DATA_DIRS=${lib.escapeShellArg "${pkgs.adwaita-icon-theme}/share"}''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}
        export XDG_CONFIG_HOME=${lib.escapeShellArg gtklockGtkConfig}
        if ${pkgs.procps}/bin/pgrep -x gtklock >/dev/null 2>&1; then
          exit 0
        fi
        css="$(${gtklockPrep})"
        exec ${lib.getExe pkgs.gtklock} -d -s "$css"
      ''}";

      # Waybar NixOS logo → fuzzel session menu (lock / logout / power).
      sessionMenu = pkgs.writeShellScript "dendritic-session-menu" ''
        set -euo pipefail
        fuzzel=${lib.escapeShellArg (lib.getExe pkgs.fuzzel)}
        niri=${lib.escapeShellArg (lib.getExe pkgs.niri)}
        systemctl=${lib.escapeShellArg "${pkgs.systemd}/bin/systemctl"}
        choice="$(
          printf '%s\n' \
            '󰌾  Lock' \
            '󰍃  Logout' \
            '󰤄  Suspend' \
            '󰜉  Reboot' \
            '󰐥  Shut down' \
            | "$fuzzel" --dmenu --prompt 'Session  ' --lines 5
        )" || exit 0
        [ -n "$choice" ] || exit 0
        case "$choice" in
          *Lock*) exec ${lock} ;;
          *Logout*) exec "$niri" msg action quit --skip-confirmation ;;
          *Suspend*) exec "$systemctl" suspend ;;
          *Reboot*) exec "$systemctl" reboot ;;
          *'Shut down'*) exec "$systemctl" poweroff ;;
        esac
      '';

      # gtklock does not talk to the Wayland idle protocol, so swayidle keeps
      # counting idle while the lock screen is up. At unlock the 900s timer is
      # often already expired → suspend in the same second as unlock (bounce).
      # Primary grace is chained inside gtklock-auth; mark is backup for
      # before-sleep / after-resume paths that use daemonized gtklock.
      idleSuspend =
        let
          graceSec = 180;
          postUnlockInhibit = pkgs.writeShellScript "dendritic-post-unlock-inhibit" ''
            exec ${pkgs.systemd}/bin/systemd-inhibit \
              --what=sleep --who=dendritic --why='post-unlock grace' --mode=block \
              ${pkgs.coreutils}/bin/sleep ${toString graceSec}
          '';
        in
        {
          mark = pkgs.writeShellScript "dendritic-suspend-grace-mark" ''
            set -euo pipefail
            runtime="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
            # Write grace stamp first — idle-suspend may race unlock handlers.
            ${pkgs.coreutils}/bin/date +%s >"$runtime/dendritic-suspend-grace"
            ${lib.getExe pkgs.niri} msg action power-on-monitors >/dev/null 2>&1 || true
            # Heal night-light gamma: resume path restores from before-sleep stamp;
            # unlock-only restarts if still active (stuck LUT after DPMS/lock).
            if [ -f "$runtime/dendritic-wlsunset-was-active" ]; then
              ${pkgs.coreutils}/bin/rm -f "$runtime/dendritic-wlsunset-was-active"
              ${pkgs.systemd}/bin/systemctl --user start wlsunset.service 2>/dev/null || true
            elif ${pkgs.systemd}/bin/systemctl --user is-active --quiet wlsunset.service 2>/dev/null; then
              ${pkgs.systemd}/bin/systemctl --user try-restart wlsunset.service 2>/dev/null || true
            fi
            # Skip if gtklock-auth already holds chained post-unlock inhibit.
            if ${pkgs.systemd}/bin/systemd-inhibit --list --no-pager 2>/dev/null \
              | ${pkgs.gnugrep}/bin/grep -E 'gtklock|dendritic' \
              | ${pkgs.gnugrep}/bin/grep -qi 'block'; then
              exit 0
            fi
            ${pkgs.procps}/bin/pkill -f 'dendritic-post-unlock-inhibit' 2>/dev/null || true
            ${postUnlockInhibit} &
          '';
          suspend = pkgs.writeShellScript "dendritic-idle-suspend" ''
            set -euo pipefail
            # Never suspend while gtklock is up (idle timer lies during lock).
            if ${pkgs.procps}/bin/pgrep -x gtklock >/dev/null 2>&1; then
              exit 0
            fi
            # Skip during logout/shutdown (idle timer can fire into teardown).
            case "$(${pkgs.systemd}/bin/systemctl is-system-running 2>/dev/null || echo unknown)" in
              stopping|offline) exit 0 ;;
            esac
            # Already suspending/hibernating — avoid "already in progress" spam.
            if ${pkgs.systemd}/bin/systemctl list-jobs --no-legend 2>/dev/null \
              | ${pkgs.gnugrep}/bin/grep -qE 'suspend\.service|hibernate\.service|hybrid-sleep\.service'; then
              exit 0
            fi
            # Honor any sleep:block inhibitor (chained lock grace / mark).
            if ${pkgs.systemd}/bin/systemd-inhibit --list --no-pager 2>/dev/null \
              | ${pkgs.gnugrep}/bin/grep -i sleep \
              | ${pkgs.gnugrep}/bin/grep -qi block; then
              exit 0
            fi
            runtime="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
            grace="$runtime/dendritic-suspend-grace"
            if [ -r "$grace" ]; then
              ts="$(${pkgs.coreutils}/bin/cat "$grace" 2>/dev/null || echo 0)"
              now="$(${pkgs.coreutils}/bin/date +%s)"
              if [ $((now - ts)) -lt ${toString graceSec} ]; then
                exit 0
              fi
            fi
            exec ${pkgs.systemd}/bin/systemctl suspend
          '';
        };

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

      # Integer Retina-like output scale for every connected display.
      # Mutter/niri DPI targets (135 mobile / 110 desktop), snapped to 1..4.
      # Watches niri's event stream so hotplug / config reload re-applies.
      retinaScale = pkgs.writeShellApplication {
        name = "dendritic-retina-scale";
        runtimeInputs = [
          pkgs.niri
          pkgs.jq
          pkgs.coreutils
        ];
        text = ''
          set -euo pipefail

          MOBILE_TARGET_DPI=135
          LARGE_TARGET_DPI=110
          LARGE_MIN_SIZE_INCHES=20
          MIN_LOGICAL_AREA=$((800 * 480))

          # Args: width_mm height_mm res_w res_h → integer scale (or empty to skip)
          guess_integer_scale() {
            local w_mm=$1 h_mm=$2 rw=$3 rh=$4
            if [ "$w_mm" -eq 0 ] || [ "$h_mm" -eq 0 ]; then
              return 0
            fi
            local diag perfect target best s d bestd
            best=
            bestd=
            diag="$(jq -n --argjson w "$w_mm" --argjson h "$h_mm" \
              '((($w * $w) + ($h * $h)) | sqrt) / 25.4')"
            if jq -ne --argjson d "$diag" --argjson lim "$LARGE_MIN_SIZE_INCHES" \
              '$d < $lim' >/dev/null; then
              target=$MOBILE_TARGET_DPI
            else
              target=$LARGE_TARGET_DPI
            fi
            perfect="$(jq -n \
              --argjson w "$rw" --argjson h "$rh" --argjson diag "$diag" --argjson t "$target" \
              '((($w * $w) + ($h * $h)) | sqrt) / $diag / $t')"
            for s in 1 2 3 4; do
              if ! jq -ne \
                --argjson rw "$rw" --argjson rh "$rh" --argjson s "$s" --argjson min "$MIN_LOGICAL_AREA" \
                '((($rw / $s) | round) * (($rh / $s) | round)) >= $min' >/dev/null; then
                continue
              fi
              d="$(jq -n --argjson s "$s" --argjson p "$perfect" '($s - $p) | fabs')"
              if [ -z "$best" ] || jq -ne --argjson d "$d" --argjson bd "$bestd" '$d < $bd' >/dev/null; then
                best=$s
                bestd=$d
              fi
            done
            printf '%s' "$best"
          }

          apply_scales() {
            local json name w_mm h_mm rw rh cur want
            json="$(niri msg -j outputs)"
            while IFS=$'\t' read -r name w_mm h_mm rw rh cur; do
              [ -n "$name" ] || continue
              want="$(guess_integer_scale "$w_mm" "$h_mm" "$rw" "$rh" || true)"
              if [ -z "$want" ]; then
                continue
              fi
              if jq -ne --argjson cur "$cur" --argjson want "$want" '$cur == $want' >/dev/null; then
                continue
              fi
              echo "dendritic-retina-scale: $name $rw×$rh @ ''${w_mm}×''${h_mm}mm → scale $want (was $cur)" >&2
              niri msg output "$name" scale "$want"
            done < <(
              jq -r '
                to_entries[]
                | .key as $name
                | .value as $o
                | ($o.current_mode) as $cm
                | select($cm != null)
                | ($o.modes[$cm]) as $m
                | [
                    $name,
                    ($o.physical_size[0] // 0),
                    ($o.physical_size[1] // 0),
                    $m.width,
                    $m.height,
                    ($o.logical.scale // 1)
                  ]
                | @tsv
              ' <<<"$json"
            )
          }

          # spawn-at-startup can race the IPC socket briefly.
          for _ in 1 2 3 4 5 6 7 8 9 10; do
            if niri msg -j outputs >/dev/null 2>&1; then
              break
            fi
            sleep 0.2
          done
          apply_scales || true

          # niri has no OutputsChanged event; WorkspacesChanged / ConfigLoaded
          # cover hotplug and config reload. apply_scales is a no-op when scales match.
          niri msg -j event-stream | while IFS= read -r line; do
            case "$line" in
              *'"ConfigLoaded"'* | *'"WorkspacesChanged"'*)
                apply_scales || true
                ;;
            esac
          done
        '';
      };

      # Shared window / island drop shadow — niri `layout.shadow` and waybar
      # module `box-shadow` stay in lockstep (color + offset + blur + spread).
      windowShadow = {
        softness = 30;
        spread = 4;
        offsetX = 0;
        offsetY = 6;
        color = "#00000060";
      };
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
          default = "${pkgs.fuzzel}/bin/fuzzel";
          defaultText = lib.literalExpression "\${pkgs.fuzzel}/bin/fuzzel";
          description = "Command niri spawns for the application launcher (Mod+D). Absolute path preferred so systemd spawn works at teardown.";
        };
      };

      config = lib.mkIf cfg.enable {
        # ── waybar (floating islands) ─────────────────────────────────
        # Let Stylix inject the base16 @define-color vars + fonts, but not its
        # stock CSS; we ship our own design (appended via mkAfter so it lands
        # after Stylix's color definitions).
        stylix.targets.waybar.addCss = false;

        # FreeType stem-darkening (linux-desktop.nix) must reach the waybar
        # unit even if import-environment races session start — pango/cairo
        # read FREETYPE_PROPERTIES at process start. Quote: value has spaces.
        systemd.user.services.waybar.Service.Environment = [
          ''"FREETYPE_PROPERTIES=cff:no-stem-darkening=0 autofitter:no-stem-darkening=0"''
        ];

        programs.waybar = {
          enable = true;
          # Sole starter — do not also spawn-at-startup (that doubles the bar).
          systemd.enable = true;
          settings.mainBar = {
            layer = "top";
            position = "top";
            # Room for per-island box-shadow (GTK clips to the waybar surface).
            # 34 triggers waybar min-height warn; shadow blur needs bottom margin.
            height = 64;
            spacing = 4;
            margin-top = 8;
            margin-left = 12;
            margin-right = 12;

            modules-left = [
              "custom/nixos"
              "niri/workspaces"
              "niri/window"
            ];
            modules-center = [ "clock" ];
            # Network: nm-applet in tray only (no waybar network / iwgtk indicator).
            modules-right = [
              "tray"
              "custom/appearance"
              "custom/power"
              "backlight"
              "pulseaudio"
              "cpu"
              "memory"
              "battery"
            ];

            # Top-left: Unicode snowflake → session menu (clock stays centered).
            # U+2744 + text presentation (FE0E) — not Nerd Font PUA (uneven bearings).
            "custom/nixos" = {
              format = "❄︎";
              tooltip-format = "Session\nLeft: lock / logout / power\nRight: lock screen";
              on-click = "${sessionMenu}";
              on-click-right = "${lock}";
            };

            "niri/workspaces" = {
              format = "{index}";
            };
            "niri/window" = {
              format = "{title}";
              max-length = 60;
            };
            clock = {
              # Single line. Multiple chrono specs need `{0:%…}` (waybar/fmt);
              # glyphs/text stay outside the braces.
              format = "<span color=\"${c.base0D}\">󰥔 {0:%H:%M}</span>  <span color=\"${c.base05}\">{0:%a · %d %b}</span>";
              format-alt = "<span color=\"${c.base0D}\">󰥔 {0:%H:%M:%S}</span>  <span color=\"${c.base05}\">{0:%Y-%m-%d}</span>";
              tooltip-format = "<tt><small>{calendar}</small></tt>";
              calendar = {
                mode = "month";
                mode-mon-col = 3;
                weeks-pos = "right";
                on-scroll = 1;
                format = {
                  months = "<span color='${c.base0D}'><b>{}</b></span>";
                  days = "<span color='${c.base05}'>{}</span>";
                  weeks = "<span color='${c.base04}'><b>W{}</b></span>";
                  weekdays = "<span color='${c.base0A}'><b>{}</b></span>";
                  today = "<span color='${c.base0B}'><b><u>{}</u></b></span>";
                };
              };
              actions = {
                on-click-right = "mode";
                on-scroll-up = "shift_up";
                on-scroll-down = "shift_down";
              };
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
            backlight = {
              format = "{icon} {percent}%";
              format-icons = [
                "󰃞"
                "󰃟"
                "󰃠"
              ];
              tooltip-format = "Brightness: {percent}%\nScroll to adjust";
              on-scroll-up = "brightnessctl set 5%+";
              on-scroll-down = "brightnessctl set 5%-";
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
              # Custom scrolls (built-in scroll-step is silent).
              on-scroll-up = "${volumeAdjust} up";
              on-scroll-down = "${volumeAdjust} down";
              on-click-right = "${volumeAdjust} mute";
            };
            tray = {
              spacing = 10;
            };
            "custom/appearance" = {
              exec = "${lib.getExe (pkgs.callPackage ./dendritic-appearance/_package.nix { })} status --waybar";
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
              # Per-module drop shadow. GTK3: (1) no 8-digit hex — use rgba;
              # (2) blur+offset must fit inside module margin or it is clipped
              # to the waybar surface (shadows cannot paint outside the bar).
              # Niri window shadows stay on windowShadow (compositor-side).
              shadowBlur = 10;
              shadowSpread = 1;
              shadowOffsetY = 3;
              islandShadow = "0 ${toString shadowOffsetY}px ${toString shadowBlur}px ${toString shadowSpread}px rgba(0, 0, 0, 0.42)";
              # bottom ≥ blur + offset + spread so each island's shadow is visible
              islandMargin = "5px 6px ${toString (shadowBlur + shadowOffsetY + shadowSpread + 2)}px 6px";
              px = n: "${toString n}px";
              # Match Stylix desktop size + linux-desktop fontconfig (grayscale
              # AA, slight hinting). Sans for UI; Maple Mono NF for glyphs.
              fontSans = config.stylix.fonts.sansSerif.name;
              fontMono = config.stylix.fonts.monospace.name;
              fontDesktopPt = toString config.stylix.fonts.sizes.desktop;
            in
            lib.mkAfter ''
              /* Override Stylix's monospace-only * rule (mkAfter → wins).
                 pt tracks output scale; px does not under Wayland scaling. */
              * {
                  font-family: "${fontSans}", "${fontMono}", sans-serif;
                  font-size: ${fontDesktopPt}pt;
              }

              /* Never shadow the whole bar — only module islands below. */
              window#waybar {
                  background: transparent;
                  box-shadow: none;
              }
              window#waybar > box {
                  background: transparent;
                  box-shadow: none;
              }

              tooltip {
                  background-color: @base00;
                  border: 1px solid @base0D;
                  border-radius: ${px tooltipRadius};
                  padding: ${px tooltipPad};
                  box-shadow: ${islandShadow};
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

              /* Drop shadow on each island (label.module + box.module), not the bar. */
              #custom-nixos,
              #workspaces,
              #window,
              #clock,
              #cpu,
              #memory,
              #battery,
              #backlight,
              #pulseaudio,
              #custom-power,
              #custom-appearance,
              #tray,
              label.module,
              box.module {
                  background-color: alpha(@base01, 0.92);
                  padding: 0 ${px islandPadX};
                  margin: ${islandMargin};
                  border-radius: ${px islandRadius};
                  box-shadow: ${islandShadow};
              }

              /* Snowflake island: identical L/R pad as sibling modules (islandPadX).
                 No nested label pad / min-width — those skewed the NF glyph. */
              #custom-nixos {
                  color: ${c.base0D};
                  font-size: 1.15em;
                  font-family: "Noto Sans Symbols 2", "${fontSans}", "DejaVu Sans", sans-serif;
                  padding: 0 ${px islandPadX};
                  min-width: 0;
              }
              #custom-nixos,
              #custom-nixos label,
              #custom-nixos decoration {
                  border-radius: ${px islandRadius};
              }
              #custom-nixos label {
                  padding: 0;
                  margin: 0;
              }
              #custom-nixos:hover {
                  color: ${c.base0C};
              }

              #clock {
                  color: @base05;
                  font-weight: 600;
              }
              #clock,
              #clock label,
              #clock decoration {
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
                  box-shadow: none;
                  text-shadow: none;
                  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
              }
              #workspaces button:hover {
                  background: alpha(@base0D, 0.2);
                  color: @base06;
                  box-shadow: none;
                  text-shadow: none;
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
                  box-shadow: none;
              }

              #cpu {
                  color: @base0C;
              }
              #memory {
                  color: @base0E;
              }
              #backlight {
                  color: @base0A;
              }
              #pulseaudio {
                  color: @base09;
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
        # icon-theme=hicolor: HM's `default` theme is the X cursor theme
        # (Bibata), not an app-icon theme — fuzzel would miss packag icons.
        programs.fuzzel.enable = true;
        programs.fuzzel.settings = {
          main = {
            layer = "overlay";
            width = 34;
            lines = 10;
            horizontal-pad = 22;
            vertical-pad = 18;
            inner-pad = 10;
            prompt = "\"  \"";
            icon-theme = "hicolor";
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

        # ── gtklock (chrome matches gtkgreet; wallpaper = desktop via auth-path) ──
        home.packages = [
          nightToggle
          retinaScale
          pkgs.gtklock
          # nm-applet (tray) is the sole network UI — see linux-desktop.nix.
          pkgs.networkmanagerapplet
          pkgs.pavucontrol
        ];
        # Style is written at lock time by gtklock-auth (placeholders → desktop current).

        # ── night light (wlsunset) ────────────────────────────────────
        # Sunrise/sunset for Spokane, WA (≈ 47.66°N, 117.43°W). Toggle with
        # night-toggle (Mod+Shift+N). Tied to the niri graphical session.
        services.wlsunset = {
          enable = true;
          latitude = 47.66;
          longitude = -117.43;
          temperature = {
            day = 6500;
            night = 3800;
          };
          systemdTarget = "graphical-session.target";
        };

        # ── swayidle (lock + DPMS + suspend) ───────────────────────────
        # Grace window on resume/unlock prevents unlock→instant-suspend bounce.
        services.swayidle = {
          enable = true;
          events = {
            before-sleep = lockBeforeSleep;
            after-resume = "${idleSuspend.mark}";
            unlock = "${idleSuspend.mark}";
          };
          timeouts = [
            {
              timeout = 300;
              command = lock;
            }
            {
              timeout = 360;
              command = "${lib.getExe pkgs.niri} msg action power-off-monitors";
              resumeCommand = "${lib.getExe pkgs.niri} msg action power-on-monitors";
            }
            {
              # Quiet when away (s2idle — deep S3 breaks TB4 xHCI on this board).
              timeout = 900;
              command = "${idleSuspend.suspend}";
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
          // Scale is owned by dendritic-retina-scale (integer Retina policy
          // from physical size + resolution). Do not hardcode `scale` here.
          output "eDP-1" {
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
                  softness ${toString windowShadow.softness}
                  spread ${toString windowShadow.spread}
                  offset x=${toString windowShadow.offsetX} y=${toString windowShadow.offsetY}
                  color "${windowShadow.color}"
              }

              struts {
                  left 4
                  right 4
                  top 0
                  bottom 4
              }
          }

          prefer-no-csd

          spawn-at-startup "mako"
          spawn-at-startup "dendritic-retina-scale"
          spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
          spawn-at-startup "xwayland-satellite" ":0"
          spawn-at-startup "sh" "-c" "wl-paste --watch cliphist store"
          // When dendritic.wallpaper manages the desktop, its apply script owns
          // swaybg (daily cycle). Otherwise fall back to stylix.image.
          ${lib.optionalString (
            wallpaper != null && !(config.dendritic.wallpaper.enable or false)
          ) ''spawn-at-startup "swaybg" "-i" "${wallpaper}" "-m" "fill"''}
          ${lib.optionalString (config.dendritic.wallpaper.enable or false
          ) ''spawn-at-startup "dendritic-appearance" "wallpaper" "daily"''}

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
              Mod+Escape { spawn "${sessionMenu}"; }
              Mod+V { spawn "sh" "-c" "cliphist list | ${pkgs.fuzzel}/bin/fuzzel --dmenu | cliphist decode | wl-copy"; }
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

              // Volume / mic (work while locked); audible click on change
              XF86AudioRaiseVolume allow-when-locked=true { spawn "${volumeAdjust}" "up"; }
              XF86AudioLowerVolume allow-when-locked=true { spawn "${volumeAdjust}" "down"; }
              XF86AudioMute        allow-when-locked=true { spawn "${volumeAdjust}" "mute"; }
              XF86AudioMicMute     allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }

              // Brightness (work while locked)
              XF86MonBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "set" "10%+"; }
              XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "set" "10%-"; }

              // Keyboard backlight: dendritic-sword-kbd-bl (HID). Sword Fn may
              // not emit KEY_KBDILLUM*; Mod+F9 cycles. Soft-fails if no HID yet.
              XF86KbdBrightnessUp   allow-when-locked=true { spawn "dendritic-sword-kbd-bl" "cycle"; }
              XF86KbdBrightnessDown allow-when-locked=true { spawn "dendritic-sword-kbd-bl" "cycle"; }
              Mod+F9 allow-when-locked=true { spawn "${kbdBacklightCycle}"; }

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
