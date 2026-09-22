{
  # niri — scrollable-tiling Wayland compositor + rice (HM) and system
  # session (NixOS: programs.niri, greetd+gtkgreet or autologin, gtklock PAM).
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
      options.dendritic.apps.niri = {
        enable = lib.mkEnableOption "niri Wayland compositor (system session + greeter)";

        autologinUser = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = ''
            If set, greetd starts niri as this user on boot — no gtkgreet
            password prompt. Logout still returns to gtkgreet (default_session).
            Lid/idle lock stays gtklock.
          '';
        };
      };

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
          settings = {
            default_session = {
              command = "${pkgs.sway}/bin/sway --config ${swayGreeterConfig}";
              user = "greeter";
            };
          }
          // lib.optionalAttrs (cfg.autologinUser != null) {
            initial_session = {
              command = "${lib.getExe' config.programs.niri.package "niri-session"}";
              user = cfg.autologinUser;
            };
          };
        };

        # NixOS greetd defaults to Type=idle (start only after every other
        # job is idle). That parks the session behind Home Manager / NM /
        # CUDA daemons. Start as soon as systemd-user-sessions is up.
        systemd.services.greetd.serviceConfig.Type = lib.mkForce "simple";

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
      # Spokane / en_US 12-hour (glibc %-I drops the leading zero).
      gtklockTimeFmt = "%-I:%M %p";
      gtklockDateFmt = "%A, %B %-d";
      gtklockClockArgs = "-t ${lib.escapeShellArg gtklockTimeFmt} -D ${lib.escapeShellArg gtklockDateFmt}";
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

      # Idle-timeout lock.
      # gtklock does not speak ext-idle-notify. While it is up, swayidle keeps
      # counting idle, so the 300s timeout is already expired at unlock and
      # the next command runs immediately (unlock → lock → unlock → lock).
      # A second gtklock then hits niri "already locked" (Failed to lock session).
      # Fix: flock + post-unlock grace + restart swayidle to reset idle clocks.
      # Do NOT hold sleep:block for the whole gtklock lifetime — if gtklock dies
      # (Wayland protocol error) niri stays session-locked with no UI while the
      # inhibitor also blocks lid/logind suspend (orange cursor-only brick).
      lock = "${pkgs.writeShellScript "gtklock-auth" ''
        set -euo pipefail
        export XDG_DATA_DIRS=${lib.escapeShellArg "${pkgs.adwaita-icon-theme}/share"}''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}
        export XDG_CONFIG_HOME=${lib.escapeShellArg gtklockGtkConfig}
        runtime="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
        ${pkgs.coreutils}/bin/mkdir -p "$runtime"
        exec 9>"$runtime/dendritic-gtklock.lock"
        ${pkgs.util-linux}/bin/flock -n 9 || exit 0
        if ${pkgs.procps}/bin/pgrep -x gtklock >/dev/null 2>&1; then
          exit 0
        fi
        grace="$runtime/dendritic-suspend-grace"
        if [ -r "$grace" ]; then
          ts="$(${pkgs.coreutils}/bin/cat "$grace" 2>/dev/null || echo 0)"
          now="$(${pkgs.coreutils}/bin/date +%s)"
          if [ $((now - ts)) -lt 180 ]; then
            exit 0
          fi
        fi
        css="$(${gtklockPrep})"
        ${lib.getExe pkgs.gtklock} -s "$css" ${gtklockClockArgs} || true
        ${pkgs.coreutils}/bin/date +%s >"$grace"
        ${lib.getExe pkgs.niri} msg action power-on-monitors >/dev/null 2>&1 || true
        # Heal gamma after unlock (wlsunset/EVDI often leaves a warm LUT).
        if ${pkgs.systemd}/bin/systemctl --user is-active --quiet wlsunset.service 2>/dev/null; then
          ${pkgs.systemd}/bin/systemctl --user try-restart wlsunset.service 2>/dev/null || true
        fi
        if ${pkgs.systemd}/bin/systemd-inhibit --list --no-pager 2>/dev/null \
          | ${pkgs.gnugrep}/bin/grep -E 'gtklock|dendritic' \
          | ${pkgs.gnugrep}/bin/grep -qi 'block'; then
          :
        else
          ${pkgs.procps}/bin/pkill -f 'dendritic-post-unlock-inhibit' 2>/dev/null || true
          ${pkgs.systemd}/bin/systemd-inhibit \
            --what=sleep --who=dendritic --why='post-unlock grace' --mode=block \
            ${pkgs.coreutils}/bin/sleep 180 &
        fi
        # Deferred so this -w child can exit before swayidle is restarted.
        (
          ${pkgs.coreutils}/bin/sleep 2
          ${pkgs.systemd}/bin/systemctl --user try-restart swayidle.service
        ) >/dev/null 2>&1 &
      ''}";

      # before-sleep: daemonize so swayidle -w can return before InhibitDelayMaxSec;
      # do not hold sleep:block here (that would fight logind suspend).
      # Do not stop wlsunset here — tearing gamma down mid-lock races niri and
      # contributed to dead-lock + stuck orange LUT; resume mark heals instead.
      lockBeforeSleep = "${pkgs.writeShellScript "gtklock-before-sleep" ''
        set -euo pipefail
        export XDG_DATA_DIRS=${lib.escapeShellArg "${pkgs.adwaita-icon-theme}/share"}''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}
        export XDG_CONFIG_HOME=${lib.escapeShellArg gtklockGtkConfig}
        runtime="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
        ${pkgs.coreutils}/bin/mkdir -p "$runtime"
        exec 9>"$runtime/dendritic-gtklock.lock"
        ${pkgs.util-linux}/bin/flock -n 9 || exit 0
        if ${pkgs.procps}/bin/pgrep -x gtklock >/dev/null 2>&1; then
          exit 0
        fi
        css="$(${gtklockPrep})"
        exec ${lib.getExe pkgs.gtklock} -d -s "$css" ${gtklockClockArgs}
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
          # Shared post-unlock / post-resume grace + gamma heal.
          # `recoverLock=1` only on after-resume — on unlock gtklock has just
          # exited and must not be relaunched.
          mark =
            let
              mkMark =
                recoverLock:
                pkgs.writeShellScript "dendritic-suspend-grace-mark${if recoverLock then "-resume" else ""}" ''
                  set -euo pipefail
                  runtime="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
                  ${pkgs.coreutils}/bin/date +%s >"$runtime/dendritic-suspend-grace"
                  ${lib.getExe pkgs.niri} msg action power-on-monitors >/dev/null 2>&1 || true
                  ${lib.optionalString recoverLock ''
                    # Resume recovery only for a *dead* lock: niri still holds
                    # ext-session-lock but gtklock is gone (orange cursor-only).
                    # Do not lock a healthy unlocked session on every resume.
                    if ! ${pkgs.procps}/bin/pgrep -x gtklock >/dev/null 2>&1; then
                      locked="$(${pkgs.systemd}/bin/loginctl show-session "''${XDG_SESSION_ID:-}" -p LockedHint --value 2>/dev/null || true)"
                      if [ "$locked" = yes ]; then
                        export XDG_DATA_DIRS=${lib.escapeShellArg "${pkgs.adwaita-icon-theme}/share"}''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}
                        export XDG_CONFIG_HOME=${lib.escapeShellArg gtklockGtkConfig}
                        css="$(${gtklockPrep})"
                        ${lib.getExe pkgs.gtklock} -d -s "$css" ${gtklockClockArgs} || true
                      fi
                    fi
                  ''}
                  ${pkgs.coreutils}/bin/rm -f "$runtime/dendritic-wlsunset-was-active"
                  if ${pkgs.systemd}/bin/systemctl --user is-active --quiet wlsunset.service 2>/dev/null; then
                    ${pkgs.systemd}/bin/systemctl --user try-restart wlsunset.service 2>/dev/null || true
                  fi
                  if ${pkgs.systemd}/bin/systemd-inhibit --list --no-pager 2>/dev/null \
                    | ${pkgs.gnugrep}/bin/grep -E 'gtklock|dendritic' \
                    | ${pkgs.gnugrep}/bin/grep -qi 'block'; then
                    exit 0
                  fi
                  ${pkgs.procps}/bin/pkill -f 'dendritic-post-unlock-inhibit' 2>/dev/null || true
                  ${postUnlockInhibit} &
                '';
            in
            {
              unlock = mkMark false;
              resume = mkMark true;
            };
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

      # Niri window shadows are compositor-side (true Gaussian). Waybar
      # islands cannot copy these values — GTK3 box-shadow is a clipped
      # cairo triple-box blur (see waybar style).
      windowShadow = {
        softness = 30;
        spread = 4;
        offsetX = 0;
        offsetY = 6;
        color = "#00000060";
      };
      # Shared layout rhythm: tiled windows and waybar islands use the same
      # gap / edge inset. Window left edge is strut + gap from the screen.
      niriGap = 12;
      niriStrut = {
        left = 4;
        right = 4;
        top = 0;
        bottom = 4;
      };
      # GTK3 clip for the island shadow stack in waybar style (blur 4 →
      # ~8px + 1). Plus the outward hover ring so the last island's
      # right stroke is not sheared by the waybar surface.
      waybarIslandShadowInset = 9;
      # Shared with niri `layout.focus-ring` and waybar module :hover.
      windowFocusRing = {
        width = 3;
        from = c.base0D;
        to = c.base0E;
        angle = 45;
      };
      # Bar-box pad: leftover horizontal drop-shadow clip at the surface.
      waybarBoxPadX = waybarIslandShadowInset;
      # Island drop-shadow (must match the CSS `box-shadow` layers below).
      # Used for both clip padding and exclusive-zone compensation.
      waybarShadowLayers = [
        {
          x = 0;
          y = 1;
          blur = 2;
          spread = 0;
          rgba = "rgba(0, 0, 0, 0.22)";
        }
        {
          x = 0;
          y = 2;
          blur = 4;
          spread = 0;
          rgba = "rgba(0, 0, 0, 0.14)";
        }
      ];
      gtkBlurClip = blur: builtins.floor (blur * 1.879 + 0.5);
      waybarShadowPad =
        lib.foldl
          (
            acc: layer:
            let
              clip = gtkBlurClip layer.blur;
              xPos = lib.max 0 (layer.x + layer.spread + clip);
              xNeg = lib.max 0 ((-layer.x) + layer.spread + clip);
              yPos = lib.max 0 (layer.y + layer.spread + clip);
              yNeg = lib.max 0 ((-layer.y) + layer.spread + clip);
            in
            {
              top = lib.max acc.top yNeg;
              right = lib.max acc.right xPos;
              bottom = lib.max acc.bottom yPos;
              left = lib.max acc.left xNeg;
            }
          )
          {
            top = 0;
            right = 0;
            bottom = 0;
            left = 0;
          }
          waybarShadowLayers;
      # +1px so the blur tail is not sheared by the surface clip.
      islandMarginTop = waybarShadowPad.top + 1;
      islandMarginBottom = waybarShadowPad.bottom + 1;
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
            # Height hugs content + vertical shadow pad (waybar warns below 34).
            # Fill-to-fill gap = 2*ring + spacing = niri gaps.
            spacing = niriGap - 2 * windowFocusRing.width;
            # gtk-layer-shell auto exclusive zone for a top bar is
            #   height + margin-bottom
            # (non-anchored edge). Niri then adds strut.top + gaps below
            # that. Subtract the CSS island margins so the visible pill
            # sits in the same niriGap rhythm as tiled windows:
            #   screen → pill = strut.top + gaps
            #   pill → window = strut.top + gaps
            margin-top = niriStrut.top + niriGap - islandMarginTop;
            margin-bottom = -islandMarginBottom;
            margin-left = niriStrut.left + niriGap - waybarBoxPadX - windowFocusRing.width;
            margin-right = niriStrut.right + niriGap - waybarBoxPadX - windowFocusRing.width;

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
              format = "<span color=\"${c.base0D}\">󰥔 {0:%I:%M %p}</span>  <span color=\"${c.base05}\">{0:%a · %d %b}</span>";
              format-alt = "<span color=\"${c.base0D}\">󰥔 {0:%I:%M:%S %p}</span>  <span color=\"${c.base05}\">{0:%Y-%m-%d}</span>";
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
              # usage 0–100 → 001.0 … 100.0 (ints; waybar rejects .1f)
              format = "󰍛 {usage:03}.0%";
              interval = 2;
            };
            memory = {
              # percentage 0–100
              format = "󰘚 {percentage:03}.0%";
              interval = 5;
            };
            battery = {
              states = {
                warning = 30;
                critical = 15;
              };
              # capacity 0–100
              format = "{icon} {capacity:03}.0%";
              format-charging = "󰂄 {capacity:03}.0%";
              format-plugged = "󰚥 {capacity:03}.0%";
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
              # brightness 0–100
              format = "{icon} {percent:03}.0%";
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
              # wpctl -l 1.0 → volume 0–100
              format = "{icon} {volume:03}.0%";
              format-muted = "󰝟 {volume:03}.0%";
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
              spacing = 6;
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
                  echo '{"text":"󰓅 00.0W","tooltip":"dendritic-powerd starting"}'
                  exit 0
                fi
                pl1="$(${pkgs.coreutils}/bin/printf '%04.1f' "$(${pkgs.jq}/bin/jq -r '.pl1_w // 0' "$f")")"
                ${pkgs.jq}/bin/jq -c --arg pl1 "$pl1" '
                  {
                    text: (
                      (if .state == "quiet" then "󰒮 "
                       elif .state == "audible" then "󰓅 "
                       else "󰈸 " end)
                      + $pl1 + "W"
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
              # Outer island radius (module pills). Tighter than 12 so a
              # compact row still reads as a capsule, not a rounded box.
              islandRadius = 10;
              # Uniform inset between island edge and nested chip (all sides).
              nestGap = 2;
              # Inner chip radius — concentric with island.
              chipRadius = lib.max 0 (islandRadius - nestGap);
              # Calendar / module tooltips: match island radius. GTK keeps a
              # separate `decoration` node square unless styled the same —
              # that causes weird corners on first hover (Waybar #5130).
              tooltipRadius = islandRadius;
              # Optional inset between tooltip chrome and label content.
              tooltipPad = 6;
              tooltipLabelRadius = lib.max 0 (tooltipRadius - tooltipPad);
              islandPadX = 8;
              ring = windowFocusRing.width;
              px = n: "${toString n}px";
              # Outline (not inset): rest keeps the 3px as *margin* outside
              # the fill. Hover turns that margin into a border so the ring
              # grows outward and the pill does not shrink. Sum is constant.
              islandMargin = "${px islandMarginTop} ${px ring} ${px islandMarginBottom} ${px ring}";
              islandMarginHover = "${px (islandMarginTop - ring)} 0 ${px (islandMarginBottom - ring)} 0";
              islandShadow = lib.concatMapStringsSep ", " (
                s: "${toString s.x}px ${toString s.y}px ${toString s.blur}px ${toString s.spread}px ${s.rgba}"
              ) waybarShadowLayers;
              # Same face as Ghostty (`font-family = Maple Mono NF` / Stylix
              # monospace). Size stays desktop pt so the compact bar does not
              # jump if terminal pt differs. Snowflake keeps a symbol fallback.
              fontSans = config.stylix.fonts.sansSerif.name;
              fontMono = config.stylix.fonts.monospace.name;
              fontDesktopPt = toString config.stylix.fonts.sizes.desktop;
            in
            lib.mkAfter ''
              /* Module text = terminal mono. pt tracks output scale. */
              * {
                  font-family: "${fontMono}", monospace;
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
                  padding: 0 ${px waybarBoxPadX};
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
                  border: none;
                  border-radius: ${px islandRadius};
                  box-shadow: ${islandShadow};
                  background-image: none;
                  background-clip: padding-box;
                  background-origin: padding-box;
              }
              #custom-nixos:hover,
              #workspaces:hover,
              #window:hover,
              #clock:hover,
              #cpu:hover,
              #memory:hover,
              #battery:hover,
              #backlight:hover,
              #pulseaudio:hover,
              #custom-power:hover,
              #custom-appearance:hover,
              #tray:hover,
              label.module:hover,
              box.module:hover {
                  /* Outward niri ring: margin → border (fill size unchanged).
                     Same 3px 45° base0D→base0E as layout.focus-ring. */
                  margin: ${islandMarginHover};
                  border: ${px ring} solid transparent;
                  background-image: linear-gradient(alpha(@base01, 0.92), alpha(@base01, 0.92)),
                                    linear-gradient(${toString windowFocusRing.angle}deg, ${windowFocusRing.from}, ${windowFocusRing.to});
                  background-origin: padding-box, border-box;
                  background-clip: padding-box, border-box;
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
                 so r_chip = r_island − gap holds around the full corner.
                 GTK3/Waybar rejects `overflow` (fatal parse), so chips stay
                 in-box via the button reset below instead. */
              #workspaces {
                  padding: ${px nestGap};
              }
              /* Reset GTK/waybar button defaults (inherit + inset shadow)
                 so a chip hover cannot steal the group's gradient border. */
              #workspaces button,
              #workspaces button:hover,
              #workspaces button.active,
              #workspaces button.focused,
              #workspaces button.urgent,
              #workspaces button label {
                  background-image: none;
                  background-origin: padding-box;
                  background-clip: padding-box;
                  border: none;
                  margin: 0;
                  box-shadow: none;
                  text-shadow: none;
              }
              #workspaces button {
                  padding: 0 6px;
                  color: @base04;
                  background: transparent;
                  border-radius: ${px chipRadius};
                  transition-property: background-color, color;
                  transition-duration: 0.2s;
                  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
              }
              #workspaces button:hover {
                  background-color: alpha(@base0D, 0.2);
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
                  background-image: none;
                  border: none;
                  box-shadow: none;
              }
              window#waybar.empty #window:hover {
                  background-image: none;
                  border: none;
                  margin: ${islandMargin};
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
        dconf.settings."org/gnome/desktop/interface".clock-format = "12h";

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
            after-resume = "${idleSuspend.mark.resume}";
            unlock = "${idleSuspend.mark.unlock}";
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
              focus-follows-mouse
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
              gaps ${toString niriGap}
              center-focused-column "never"
              preset-column-widths {
                  proportion 0.33333
                  proportion 0.5
                  proportion 0.66667
              }
              default-column-width { proportion 0.5; }

              focus-ring {
                  width ${toString windowFocusRing.width}
                  active-gradient from="${windowFocusRing.from}" to="${windowFocusRing.to}" angle=${toString windowFocusRing.angle}
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
                  left ${toString niriStrut.left}
                  right ${toString niriStrut.right}
                  top ${toString niriStrut.top}
                  bottom ${toString niriStrut.bottom}
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

          // Browser picture-in-picture (Firefox, Brave, Chrome, Chromium, …).
          window-rule {
              match title="(?i)^Picture[- ]in[- ][Pp]icture$"
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

              // Floating (niri default Mod+V is cliphist here)
              Mod+Shift+V { toggle-window-floating; }
              Mod+Alt+V { switch-focus-between-floating-and-tiling; }

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

              // Screenshots (niri built-in) + annotate region (grim→satty)
              Print { screenshot; }
              Ctrl+Print { screenshot-screen; }
              Alt+Print { screenshot-window; }
              Mod+Shift+S { spawn "dendritic-annotate"; }

              // Session (wrapper sets bold reveal icons + style)
              Super+Alt+L { spawn "${lock}"; }
              Mod+Shift+E { quit; }
          }
        '';
      };
    };
}
