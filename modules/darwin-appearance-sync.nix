{
  flake.modules.darwin.dendritic =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      user = config.system.primaryUser;
      host = config.networking.hostName;
      normalizeHex = hex: lib.toLower (lib.removePrefix "#" hex);
      themePalette = lib.mapAttrs (_: value: normalizeHex value) config.lib.stylix.colors.withHashtag;

      # ── macOS Tahoe tint colors derived from Stylix blue accent ─────────
      # Convert a 2-char lowercase hex string to an integer (0-255).
      hexDigits = {
        "0" = 0;
        "1" = 1;
        "2" = 2;
        "3" = 3;
        "4" = 4;
        "5" = 5;
        "6" = 6;
        "7" = 7;
        "8" = 8;
        "9" = 9;
        "a" = 10;
        "b" = 11;
        "c" = 12;
        "d" = 13;
        "e" = 14;
        "f" = 15;
      };
      hexToDec =
        hex:
        let
          chars = lib.stringToCharacters (lib.toLower hex);
        in
        builtins.foldl' (acc: ch: acc * 16 + hexDigits.${ch}) 0 chars;
      hexToRgb = hex: [
        (hexToDec (builtins.substring 0 2 hex))
        (hexToDec (builtins.substring 2 2 hex))
        (hexToDec (builtins.substring 4 2 hex))
      ];
      # Convert a 0-255 integer to a 4-decimal float string (e.g. 40 → "0.1569")
      intToFloat =
        n:
        let
          # Fixed-point: multiply by 10000, divide by 255, format as X.XXXX
          scaled = builtins.floor (n * 10000 / 255);
          whole = builtins.floor (scaled / 10000);
          frac = scaled - whole * 10000;
          pad4 =
            s:
            let
              l = builtins.stringLength s;
            in
            if l >= 4 then s else lib.concatStrings (lib.replicate (4 - l) "0") + s;
        in
        "${toString whole}.${pad4 (toString frac)}";
      # Convert a 6-char hex color to a "R G B 1.00" float string for macOS defaults.
      hexToTintStr =
        hex:
        let
          rgb = hexToRgb hex;
        in
        "${intToFloat (builtins.elemAt rgb 0)} ${intToFloat (builtins.elemAt rgb 1)} ${intToFloat (builtins.elemAt rgb 2)} 1.00";

      # Pre-computed Tahoe tint string from active Stylix blue accent.
      tahoeTint = hexToTintStr themePalette.base0D;

      # Brave variant reload is owned by `modules/apps/brave.nix` and exposed
      # as `config.dendritic.brave.reloadScript`. The script knows how to
      # quit Brave, re-materialize the Stylix manifest, update the
      # Preferences variant, and relaunch the wrapper app. This module just
      # invokes it as part of the post-flip hook chain.
      braveReloadScript = config.dendritic.brave.reloadScript;
    in
    {
      config = {
        environment.etc."dendritic-appearance-sync.sh".text = ''
          #!/bin/sh
          set -eu

          state_dir="/var/lib/dendritic"
          lock_dir="/var/run/dendritic-appearance-sync.lock"
          status_file="$state_dir/appearance-status.txt"
          applied_file="$state_dir/appearance-variant"
          requested_file="$state_dir/appearance-requested"
          pending_file="$state_dir/appearance-pending"
          dark_path_file="$state_dir/prebuilt-dark-path"
          light_path_file="$state_dir/prebuilt-light-path"
          dark_rev_file="$state_dir/prebuilt-dark-rev"
          light_rev_file="$state_dir/prebuilt-light-rev"
          restart_hints_file="$state_dir/restart-hints.txt"
          log_file="/var/log/dendritic-appearance-sync.log"
          err_log_file="/var/log/dendritic-appearance-sync.err.log"
          source_flake_dir="/private/etc/nix-darwin/.dotfiles"
          mirror_flake_dir="/private/var/lib/dendritic/flake-source"

          user="${user}"
          uid="$(${pkgs.coreutils}/bin/id -u "$user")"
          launchctl="/bin/launchctl"
          now_cmd="/bin/date"
          current_rev="unknown"

          mkdir -p "$state_dir"
          chmod 755 "$state_dir"

          sync_flake_source() {
            mkdir -p "$mirror_flake_dir"
            /usr/bin/rsync -a --delete --delete-excluded \
              --exclude=".git/" \
              --exclude=".cache/" \
              --exclude=".cursor/" \
              --exclude="agent-tools/" \
              --exclude="agent-transcripts/" \
              --exclude="terminals/" \
              --exclude="*.sock" \
              --exclude="result" \
              "$source_flake_dir/" "$mirror_flake_dir/"
          }

          detect_rev() {
            rev="$(/usr/bin/git -C "$source_flake_dir" rev-parse --verify HEAD 2>/dev/null || true)"
            if [ -n "$rev" ]; then
              if /usr/bin/git -C "$source_flake_dir" diff --quiet --ignore-submodules=all 2>/dev/null; then
                printf "%s\n" "$rev"
              else
                printf "%s-dirty\n" "$rev"
              fi
              return
            fi
            # Keep fallback stable when source is not a git checkout.
            # A timestamp here causes false stale-cache mismatches every run.
            printf "nogit\n"
          }

          detect_desired() {
            # No osascript: use dendritic-appearance (defaults / host state).
            if command -v dendritic-appearance >/dev/null 2>&1; then
              mode="$("$launchctl" asuser "$uid" /usr/bin/sudo -u "$user" \
                /usr/bin/env HOME="/Users/$user" dendritic-appearance detect 2>/dev/null || true)"
              case "$mode" in
                dark|light) printf '%s\n' "$mode"; return ;;
              esac
            fi
            if /usr/bin/defaults read "/Users/$user/Library/Preferences/.GlobalPreferences" AppleInterfaceStyle 2>/dev/null | /usr/bin/grep -qi dark; then
              printf "dark\n"
            else
              printf "light\n"
            fi
          }

          notify() {
            # Prefer terminal-notifier / log — never osascript.
            title="$1"
            message="$2"
            subtitle="$3"
            if command -v terminal-notifier >/dev/null 2>&1; then
              "$launchctl" asuser "$uid" /usr/bin/sudo -u "$user" \
                terminal-notifier -title "$title" -subtitle "$subtitle" -message "$message" >/dev/null 2>&1 || true
            fi
            printf '%s\n' "notify: $title — $message ($subtitle)" >>"$log_file"
          }

          write_status() {
            phase="$1"
            detail="$2"
            desired="$3"
            applied="unknown"
            [ -f "$applied_file" ] && applied="$(cat "$applied_file" 2>/dev/null || true)"

            {
              echo "phase=$phase"
              echo "detail=$detail"
              echo "desired=$desired"
              echo "applied=$applied"
              echo "current_rev=$current_rev"
              echo "time=$("$now_cmd" -u +"%Y-%m-%dT%H:%M:%SZ")"
              echo "dark_prebuilt=$( [ -f "$dark_path_file" ] && cat "$dark_path_file" || echo missing )"
              echo "light_prebuilt=$( [ -f "$light_path_file" ] && cat "$light_path_file" || echo missing )"
              echo ""
              echo "tail_log:"
              /usr/bin/tail -n 25 "$log_file" 2>/dev/null || true
              echo ""
              echo "tail_err_log:"
              /usr/bin/tail -n 25 "$err_log_file" 2>/dev/null || true
              echo ""
              echo "restart_hints:"
              [ -f "$restart_hints_file" ] && /bin/cat "$restart_hints_file" || true
            } > "$status_file"

            chmod 644 "$status_file"
          }

          resolve_prebuilt() {
            mode="$1"
            path_file="$dark_path_file"
            rev_file="$dark_rev_file"
            if [ "$mode" = "light" ]; then
              path_file="$light_path_file"
              rev_file="$light_rev_file"
            fi

            if [ ! -f "$path_file" ] || [ ! -f "$rev_file" ]; then
              return 1
            fi

            built_rev="$(cat "$rev_file" 2>/dev/null || true)"
            built_path="$(cat "$path_file" 2>/dev/null || true)"
            if [ -z "$built_rev" ] || [ -z "$built_path" ]; then
              return 1
            fi
            if [ "$built_rev" != "$current_rev" ]; then
              return 1
            fi
            if [ ! -x "$built_path/activate" ]; then
              return 1
            fi

            printf "%s\n" "$built_path"
          }

          activate_prebuilt() {
            desired="$1"
            prebuilt_path="$2"
            tmp_out="$(/usr/bin/mktemp -t dendritic-activate-out)"
            tmp_err="$(/usr/bin/mktemp -t dendritic-activate-err)"
            fast_activate_flag="$state_dir/fast-activate"

            write_status "switching" "activating prebuilt profile ($prebuilt_path)" "$desired"
            : > "$fast_activate_flag"
            chmod 644 "$fast_activate_flag"
            set +e
            "$prebuilt_path/activate" >"$tmp_out" 2>"$tmp_err"
            rc="$?"
            set -e
            /bin/rm -f "$fast_activate_flag"
            /bin/cat "$tmp_out" >> "$log_file" 2>/dev/null || true
            /bin/cat "$tmp_err" >> "$err_log_file" 2>/dev/null || true
            /bin/rm -f "$tmp_out" "$tmp_err"

            if [ "$rc" -eq 0 ]; then
              printf "%s\n" "$desired" > "$applied_file"
              chmod 644 "$applied_file"
              /bin/sh /etc/dendritic-appearance-reload-hooks.sh >>"$log_file" 2>>"$err_log_file" || true
              # Match wallpaper + palette variant to host appearance (no rebuild).
              "$launchctl" asuser "$uid" /usr/bin/sudo -u "$user" /usr/bin/env \
                HOME="/Users/$user" \
                DENDRITIC_THEME_VARIANT="$desired" \
                dendritic-appearance apply --variant "$desired" --wallpaper current \
                >>"$log_file" 2>>"$err_log_file" || true
              /usr/bin/printf '%s\n' \
                "Applications with limited hot-reload may still need restart." \
                "Common candidates: Firefox, some Electron apps, GTK apps." > "$restart_hints_file"
              chmod 644 "$restart_hints_file"
              write_status "done" "activated prebuilt profile successfully" "$desired"
              notify "Dendritic Appearance" "Stylix + system now in $desired mode." "Activation complete (no build)"
              return 0
            fi

            [ "$rc" -eq 0 ] && rc=1
            write_status "failed" "activation failed with exit code $rc" "$desired"
            notify "Dendritic Appearance" "Activation failed for $desired mode." "Open status for details"
            return "$rc"
          }

          acquire_lock() {
            if mkdir "$lock_dir" 2>/dev/null; then
              printf "%s\n" "$$" > "$lock_dir/pid"
              return 0
            fi

            if [ -f "$lock_dir/pid" ]; then
              old_pid="$(cat "$lock_dir/pid" 2>/dev/null || true)"
              if [ -n "$old_pid" ] && ! /bin/kill -0 "$old_pid" 2>/dev/null; then
                rm -rf "$lock_dir"
                if mkdir "$lock_dir" 2>/dev/null; then
                  printf "%s\n" "$$" > "$lock_dir/pid"
                  return 0
                fi
              fi
            fi

            return 1
          }

          cleanup() {
            if [ -f "$lock_dir/pid" ] && [ "$(cat "$lock_dir/pid" 2>/dev/null || true)" = "$$" ]; then
              rm -rf "$lock_dir"
            fi
          }
          trap cleanup EXIT INT TERM

          latest="$(detect_desired)"
          printf "%s\n" "$latest" > "$requested_file"

          if ! acquire_lock; then
            printf "1\n" > "$pending_file"
            exit 0
          fi
          rm -f "$pending_file"

          while true; do
            desired="$(cat "$requested_file" 2>/dev/null || detect_desired)"
            applied=""
            [ -f "$applied_file" ] && applied="$(cat "$applied_file" 2>/dev/null || true)"

            if [ "$desired" = "$applied" ]; then
              write_status "idle" "already converged" "$desired"
              break
            fi

            current_rev="$(detect_rev)"
            sync_flake_source
            write_status "detected" "detected system appearance change" "$desired"
            notify "Dendritic Appearance" "Detected $desired mode; preparing activation." "Activation-only mode (prebuilt)"

            prebuilt_path="$(resolve_prebuilt "$desired" || true)"
            if [ -z "$prebuilt_path" ]; then
              write_status "failed" "prebuilt profile missing/stale; run nh darwin switch to refresh dark+light prebuilds" "$desired"
              notify "Dendritic Appearance" "Prebuilt profile unavailable for $desired mode." "Run nh darwin switch to refresh prebuild cache"
              exit 1
            fi

            activate_prebuilt "$desired" "$prebuilt_path" || exit "$?"

            recheck="$(cat "$requested_file" 2>/dev/null || detect_desired)"
            if [ "$recheck" = "$desired" ]; then
              if [ -f "$pending_file" ]; then
                rm -f "$pending_file"
              fi
              break
            fi
            printf "1\n" > "$pending_file"
          done
        '';

        environment.etc."dendritic-appearance-reload-hooks.sh".text = ''
          #!/bin/sh
          # App reload hooks after fast activation.
          set -eu

          user="${user}"
          uid="$(${pkgs.coreutils}/bin/id -u "$user")"
          launchctl="/bin/launchctl"

          # ── macOS Tahoe tinting (base0D blue accent from Stylix palette) ─────
          # Tint string is pre-computed at Nix eval time from Stylix colors.
          apply_tahoe_tinting() {
            _tint="${tahoeTint}"
            # Icon / widget / folder tint color
            "$launchctl" asuser "$uid" /usr/bin/sudo -u "$user" \
              /usr/bin/defaults write -g AppleIconAppearanceTintColor -string "Other"
            "$launchctl" asuser "$uid" /usr/bin/sudo -u "$user" \
              /usr/bin/defaults write -g AppleIconAppearanceCustomTintColor -string "$_tint"
            # Text highlight color
            "$launchctl" asuser "$uid" /usr/bin/sudo -u "$user" \
              /usr/bin/defaults write -g AppleHighlightColor -string "$_tint"
            # Accent / theme color (explicit macOS blue + custom variant tint)
            "$launchctl" asuser "$uid" /usr/bin/sudo -u "$user" \
              /usr/bin/defaults write -g AppleAccentColor -int 4
            "$launchctl" asuser "$uid" /usr/bin/sudo -u "$user" \
              /usr/bin/defaults write -g AppleAccentColorVariant -string "$_tint"
            # Icon style = tinted, auto light/dark switch
            "$launchctl" asuser "$uid" /usr/bin/sudo -u "$user" \
              /usr/bin/defaults write -g AppleIconAppearanceStyle -string "Tinted"
            "$launchctl" asuser "$uid" /usr/bin/sudo -u "$user" \
              /usr/bin/defaults write -g AppleIconAppearanceMode -string "Auto"
            # Bounce UI services so the tint takes effect immediately.
            "$launchctl" asuser "$uid" /usr/bin/sudo -u "$user" \
              /usr/bin/killall Dock Finder SystemUIServer >/dev/null 2>&1 || true
          }

          apply_tahoe_tinting

          # Prefer live tint from today's wallpaper palette (colors.toml).
          if command -v dendritic-appearance >/dev/null 2>&1; then
            "$launchctl" asuser "$uid" /usr/bin/sudo -u "$user" \
              /usr/bin/env HOME="/Users/$user" dendritic-appearance tint >/dev/null 2>&1 || true
          fi

          # Force Ghostty config/theme reload after each mode switch.
          # Preferred path for newer Ghostty builds (no osascript).
          if "$launchctl" asuser "$uid" /usr/bin/sudo -u "$user" /usr/bin/pkill -USR2 -x "Ghostty" >/dev/null 2>&1; then
            :
          fi

          # VS Code / Cursor / Antigravity: settings.json hot-reload (no AppleScript).

          # Neovim watches ~/colors.toml directly for Stylix palette changes.

          # Spotify/Spicetify: refresh via CLI; quit with pkill (no osascript).
          "$launchctl" asuser "$uid" /usr/bin/sudo -u "$user" /bin/zsh -lc '
            export PATH="/etc/profiles/per-user/'"${user}"'/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
            spicetify_bin="${
              config.home-manager.users.${user}.programs.spicetify.spicetifyPackage
            }/bin/spicetify"
            spotify_app="$HOME/Applications/Home Manager Apps/Spotify.app"
            was_running=0
            if /usr/bin/pgrep -x "Spotify" >/dev/null 2>&1; then
              was_running=1
              /usr/bin/pkill -x "Spotify" >/dev/null 2>&1 || true
              i=0
              while /usr/bin/pgrep -x "Spotify" >/dev/null 2>&1 && [ "$i" -lt 40 ]; do
                /bin/sleep 0.25
                i=$((i + 1))
              done
            fi

            if [ -x "$spicetify_bin" ]; then
              "$spicetify_bin" refresh --style --no-restart >/dev/null 2>&1 \
                || "$spicetify_bin" apply --no-restart >/dev/null 2>&1 \
                || "$spicetify_bin" apply >/dev/null 2>&1 \
                || true
            fi

            if [ "$was_running" -eq 1 ]; then
              /bin/sleep 0.5
              if [ -d "$spotify_app" ]; then
                /usr/bin/open "$spotify_app" >/dev/null 2>&1 || true
              else
                /usr/bin/open -a "Spotify" >/dev/null 2>&1 || true
              fi
            fi
          ' >/dev/null 2>&1 || true

          # Brave: re-materialize the Stylix manifest + variant for the
          # newly active appearance, then quit and relaunch the wrapper
          # app so Brave re-reads the theme on startup. The reload
          # script is generated by `modules/apps/brave.nix` so the
          # exact same theme pipeline runs at HM activation time AND
          # at runtime — no duplicated logic.
          ${braveReloadScript}/bin/brave-stylix-reload >/dev/null 2>&1 || true

          exit 0
        '';

        environment.etc."dendritic-appearance-status.sh".text = ''
          #!/bin/sh
          set -eu
          status_file="/var/lib/dendritic/appearance-status.txt"
          log_file="/var/log/dendritic-appearance-sync.log"
          err_log_file="/var/log/dendritic-appearance-sync.err.log"

          if [ -f "$status_file" ]; then
            /usr/bin/open -a TextEdit "$status_file" >/dev/null 2>&1 || /usr/bin/open "$status_file" >/dev/null 2>&1 || true
          fi
          if [ -f "$log_file" ]; then
            /usr/bin/open -a Console "$log_file" >/dev/null 2>&1 || true
          fi
          if [ -f "$err_log_file" ]; then
            /usr/bin/open -a Console "$err_log_file" >/dev/null 2>&1 || true
          fi
        '';

        launchd.daemons.dendritic-appearance-sync = {
          serviceConfig = {
            ProgramArguments = [
              "/bin/sh"
              "/etc/dendritic-appearance-sync.sh"
            ];
            RunAtLoad = true;
            WatchPaths = [ "/Users/${user}/Library/Preferences/.GlobalPreferences.plist" ];
            StandardOutPath = "/var/log/dendritic-appearance-sync.log";
            StandardErrorPath = "/var/log/dendritic-appearance-sync.err.log";
          };
        };

        # Ensure these steps run in a guaranteed activation phase.
        system.activationScripts.postActivation.text = lib.mkAfter ''
          mkdir -p /var/lib/dendritic
          state_dir="/var/lib/dendritic"

          # Fast-activate path (triggered by appearance sync prebuilt activation):
          # skip cache prebuilds and daemon kick to avoid recursive activations.
          skip_prebuild=0
          if [ -f "$state_dir/fast-activate" ]; then
            skip_prebuild=1
          fi

          if [ "$skip_prebuild" -eq 0 ]; then
            printf '%s\n' "${config.dendritic.theme.variant}" > /var/lib/dendritic/appearance-variant
            chmod 644 /var/lib/dendritic/appearance-variant

            # Prebuild both dark and light profiles during a normal switch,
            # so runtime appearance toggles only need to activate prebuilt outputs.
            set -eu
            src_real="/private/etc/nix-darwin/.dotfiles"
            src_mirror="/private/var/lib/dendritic/flake-source"
            src="$src_mirror"
            nix_bin="${pkgs.nix}/bin/nix"
            # `darwinConfigurations.${host}` is light by default.
            dark_attr="path:$src#darwinConfigurations.${host}-dark.config.system.build.toplevel"
            light_attr="path:$src#darwinConfigurations.${host}.config.system.build.toplevel"

            mkdir -p "$state_dir"
            mkdir -p "$src_mirror"
            if /usr/bin/rsync -a --delete --delete-excluded \
              --exclude=".git/" \
              --exclude=".cache/" \
              --exclude=".cursor/" \
              --exclude="agent-tools/" \
              --exclude="agent-transcripts/" \
              --exclude="terminals/" \
              --exclude="*.sock" \
              --exclude="result" \
              "$src_real/" "$src_mirror/" \
              && dark_out="$("$nix_bin" build --no-link --print-out-paths "$dark_attr")" \
              && light_out="$("$nix_bin" build --no-link --print-out-paths "$light_attr")"
            then
              rev="$(/usr/bin/git -C "$src_real" rev-parse --verify HEAD 2>/dev/null || true)"
              if [ -n "$rev" ]; then
                if ! /usr/bin/git -C "$src_real" diff --quiet --ignore-submodules=all 2>/dev/null; then
                  rev="$rev-dirty"
                fi
              else
                rev="nogit"
              fi

              printf '%s\n' "$dark_out" > "$state_dir/prebuilt-dark-path"
              printf '%s\n' "$light_out" > "$state_dir/prebuilt-light-path"
              printf '%s\n' "$rev" > "$state_dir/prebuilt-dark-rev"
              printf '%s\n' "$rev" > "$state_dir/prebuilt-light-rev"
              chmod 644 \
                "$state_dir/prebuilt-dark-path" \
                "$state_dir/prebuilt-light-path" \
                "$state_dir/prebuilt-dark-rev" \
                "$state_dir/prebuilt-light-rev"
            else
              echo "warning: dendritic appearance prebuild failed; keeping previous prebuilt cache" >&2
            fi

            # macOS appearance is the source of truth (no osascript).
            desired_variant="$(
              /bin/launchctl asuser "$(${pkgs.coreutils}/bin/id -u "${user}")" \
                /usr/bin/sudo -u "${user}" \
                /usr/bin/env HOME="/Users/${user}" dendritic-appearance detect 2>/dev/null || true
            )"
            case "$desired_variant" in dark|light) ;; *)
              if /usr/bin/defaults read "/Users/${user}/Library/Preferences/.GlobalPreferences" AppleInterfaceStyle 2>/dev/null | /usr/bin/grep -qi dark; then
                desired_variant="dark"
              else
                desired_variant="light"
              fi
            ;; esac
            printf '%s\n' "$desired_variant" > "$state_dir/appearance-requested"
            chmod 644 "$state_dir/appearance-requested"

            /bin/launchctl kickstart -k system/dendritic-appearance-sync >/dev/null 2>&1 || true

            # Apply Tahoe tinting immediately on activation (before the sync daemon
            # finishes its first run). The hook reads appearance-variant which was
            # written above, so the correct light/dark tint is used right away.
            /bin/sh /etc/dendritic-appearance-reload-hooks.sh >>/var/log/dendritic-appearance-sync.log 2>&1 || true
          fi
        '';
      };
    };
}
