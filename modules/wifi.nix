# Dendritic Wi-Fi — declarative known networks (pass-backed PSK).
#
# NixOS: NetworkManager + iwd backend (see linux-desktop.nix).
#   Match live Bubbles: WPA2-PSK, IPv4/IPv6 auto, DHCP DNS, autoconnect.
#   Applied by dendritic-wifi-ensure (nmcli) after pass materialize — not at rebuild.
# Darwin: nix-darwin power-on + HM ensure via networksetup (preferred + join).
#
# PSK never enters the Nix store — materialized from pass SecretSpec key
# `Bubbles` → ~/.config/dendritic/wifi/Bubbles.psk (+ optional root copy).
{
  flake.modules.nixos.dendritic =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.dendritic.wifi;
      bubbles = cfg.networks.Bubbles or null;
    in
    {
      options.dendritic.wifi = {
        enable = lib.mkEnableOption "dendritic declarative Wi-Fi (Bubbles + pass PSK)" // {
          default = true;
        };
        networks = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                options = {
                  ssid = lib.mkOption {
                    type = lib.types.str;
                    default = name;
                    description = "SSID (defaults to attr name).";
                  };
                  uuid = lib.mkOption {
                    type = lib.types.str;
                    description = "Stable NetworkManager connection UUID.";
                  };
                  passKey = lib.mkOption {
                    type = lib.types.str;
                    default = name;
                    description = "SecretSpec / pass key under secretspec/shared/default/<key>.";
                  };
                  autoconnectPriority = lib.mkOption {
                    type = lib.types.int;
                    default = 100;
                  };
                };
              }
            )
          );
          default = {
            Bubbles = {
              ssid = "Bubbles";
              # Preserve the existing sliceanddice profile identity.
              uuid = "775e836e-1345-4579-bb55-17e84423aa5b";
              passKey = "Bubbles";
              autoconnectPriority = 100;
            };
          };
          description = "Known Wi-Fi networks to ensure (PSK from pass).";
        };
        # Absolute path root uses for NM envsubst (written by wifi-ensure).
        stateDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/dendritic/wifi";
          description = "Directory for root-owned BUBBLES_PSK env files (not in Nix store).";
        };
      };

      config = lib.mkIf (cfg.enable && bubbles != null) {
        # Radio on; iwd remains the backend from linux-desktop.nix.
        networking.networkmanager.wifi.powersave = lib.mkDefault false;

        # Do NOT rewrite NM keyfiles during nixos-rebuild — that races the live
        # association (we already dropped sliceanddice once this way). Desired
        # state is applied by `dendritic-wifi-ensure` after pass materialize.
        networking.wireless.iwd.settings = {
          # NM owns IP/DNS; iwd is the Wi-Fi stack only (matches current setup).
          General.EnableNetworkConfiguration = lib.mkDefault false;
        };

        systemd.tmpfiles.rules = [
          "d ${cfg.stateDir} 0750 root root -"
        ];

        environment.systemPackages = [
          (pkgs.writeShellScriptBin "dendritic-wifi-nm-reload" ''
            set -euo pipefail
            ${pkgs.networkmanager}/bin/nmcli radio wifi on || true
            ${pkgs.networkmanager}/bin/nmcli connection reload || true
            ${pkgs.networkmanager}/bin/nmcli connection up id Bubbles || true
          '')
        ];
      };
    };

  flake.modules.darwin.dendritic =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.wifi;
    in
    {
      options.dendritic.wifi = {
        enable = lib.mkEnableOption "dendritic declarative Wi-Fi (Bubbles + pass PSK)" // {
          default = true;
        };
        networks = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                options = {
                  ssid = lib.mkOption {
                    type = lib.types.str;
                    default = name;
                  };
                  passKey = lib.mkOption {
                    type = lib.types.str;
                    default = name;
                  };
                };
              }
            )
          );
          default = {
            Bubbles = {
              ssid = "Bubbles";
              passKey = "Bubbles";
            };
          };
        };
      };

      # Actual join runs from HM wifi-ensure (needs pass/GPG). System side only
      # documents the feature; device power-on is best-effort here.
      config = lib.mkIf cfg.enable {
        system.activationScripts.postActivation.text = lib.mkAfter ''
          echo "dendritic.wifi: ensuring Wi-Fi power on (AirPort)"
          for dev in $(/usr/sbin/networksetup -listallhardwareports \
            | /usr/bin/awk '/Wi-Fi|AirPort/{getline; print $2}'); do
            /usr/sbin/networksetup -setairportpower "$dev" on 2>/dev/null || true
          done
        '';
      };
    };

  flake.modules.homeManager.dendritic =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.dendritic.wifi;
      bubbles = cfg.networks.Bubbles or null;

      pskRel = ".config/dendritic/wifi/Bubbles.psk";
      pskPath = "${config.home.homeDirectory}/${pskRel}";

      ensureBin = pkgs.writeShellScriptBin "dendritic-wifi-ensure" ''
        set -euo pipefail
        LOG_PREFIX="dendritic-wifi-ensure"
        log() { printf '%s %s: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$LOG_PREFIX" "$*"; }
        warn() { log "warning: $*" >&2; }

        PSK_FILE="${pskPath}"
        SSID="Bubbles"
        STATE_DIR="/var/lib/dendritic/wifi"

        if [[ ! -r "$PSK_FILE" ]]; then
          warn "PSK file missing ($PSK_FILE); run pass-materialize after GPG unlock"
          exit 0
        fi
        # Strip a single trailing newline; keep password bytes otherwise intact.
        PSK="$(${pkgs.coreutils}/bin/tr -d '\n' <"$PSK_FILE")"
        if [[ -z "$PSK" ]]; then
          warn "PSK empty"
          exit 0
        fi

        if [[ "$(uname -s)" == Darwin ]]; then
          DEV="$(/usr/sbin/networksetup -listallhardwareports \
            | /usr/bin/awk '/Wi-Fi|AirPort/{getline; print $2; exit}')"
          if [[ -z "''${DEV:-}" ]]; then
            warn "no Wi-Fi hardware port found"
            exit 0
          fi
          /usr/sbin/networksetup -setairportpower "$DEV" on 2>/dev/null || true
          # Prefer upsert without remove/re-add — remove requires admin and hangs
          # non-interactive agents waiting on a password dialog.
          with_timeout() {
            # usage: with_timeout SECONDS cmd...
            local secs="$1"; shift
            "$@" &
            local pid=$!
            local i=0
            while kill -0 "$pid" 2>/dev/null; do
              i=$((i + 1))
              if [[ "$i" -ge "$secs" ]]; then
                kill -9 "$pid" 2>/dev/null || true
                wait "$pid" 2>/dev/null || true
                return 124
              fi
              sleep 1
            done
            wait "$pid"
          }
          PREF="$(/usr/sbin/networksetup -listpreferredwirelessnetworks "$DEV" 2>/dev/null || true)"
          if ! printf '%s' "$PREF" | ${pkgs.gnugrep}/bin/grep -Fq "$SSID"; then
            if ! with_timeout 12 /usr/sbin/networksetup -addpreferredwirelessnetworkatindex "$DEV" "$SSID" 0 WPA2 "$PSK"; then
              warn "addpreferredwirelessnetwork failed/timed out (approve admin dialog or run once in Terminal)"
            fi
          else
            log "darwin: $SSID already preferred on $DEV"
          fi
          # macOS Sequoia+ often lies via -getairportnetwork ("not associated") while
          # en0 is up with DHCP. Skip join when the Wi-Fi iface already has IPv4.
          if ifconfig "$DEV" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q 'status: active' \
            && ifconfig "$DEV" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -Eq 'inet [0-9]'; then
            log "darwin: $DEV already active with IPv4; skipping join"
          else
            if ! with_timeout 15 /usr/sbin/networksetup -setairportnetwork "$DEV" "$SSID" "$PSK"; then
              warn "setairportnetwork failed/timed out (admin/TCC?)"
            fi
          fi
          log "darwin: preferred + join ensured for $SSID on $DEV"
          exit 0
        fi

        # ── Linux (NetworkManager + iwd) ─────────────────────────────
        if ! command -v nmcli >/dev/null 2>&1; then
          warn "nmcli missing"
          exit 0
        fi
        nmcli radio wifi on || true

        # Root copy of passphrase (0600) for optional tooling / future use.
        if [[ -d "$STATE_DIR" ]] || sudo mkdir -p "$STATE_DIR" 2>/dev/null; then
          TMP="$(${pkgs.coreutils}/bin/mktemp)"
          printf '%s\n' "$PSK" >"$TMP"
          chmod 600 "$TMP"
          if sudo cp "$TMP" "$STATE_DIR/Bubbles.psk" 2>/dev/null; then
            sudo chmod 600 "$STATE_DIR/Bubbles.psk" || true
            sudo chown root:root "$STATE_DIR/Bubbles.psk" || true
            log "wrote $STATE_DIR/Bubbles.psk"
          else
            warn "could not install $STATE_DIR/Bubbles.psk (sudo?)"
          fi
          rm -f "$TMP"
        fi

        UUID="775e836e-1345-4579-bb55-17e84423aa5b"
        # Upsert system connection matching live Bubbles (WPA2-PSK, DHCP DNS).
        if ! nmcli -t -f UUID connection show "$SSID" &>/dev/null \
          && ! nmcli -t -f UUID connection show uuid "$UUID" &>/dev/null; then
          nmcli connection add type wifi con-name "$SSID" ifname '*' ssid "$SSID" \
            wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$PSK" \
            connection.autoconnect yes connection.autoconnect-priority 100 \
            connection.uuid "$UUID" \
            ipv4.method auto ipv6.method auto ipv6.addr-gen-mode stable-privacy \
            || warn "nmcli connection add failed"
        else
          nmcli connection modify "$SSID" \
            wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$PSK" \
            connection.autoconnect yes connection.autoconnect-priority 100 \
            ipv4.method auto ipv6.method auto ipv6.addr-gen-mode stable-privacy \
            802-11-wireless.ssid "$SSID" \
            || nmcli connection modify uuid "$UUID" \
              wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$PSK" \
              connection.autoconnect yes \
            || warn "nmcli connection modify failed"
        fi

        # Prefer non-interactive up; fall back to wifi connect.
        if ! nmcli -t -f NAME,DEVICE connection show --active | ${pkgs.gnugrep}/bin/grep -q "^''${SSID}:"; then
          nmcli connection up id "$SSID" \
            || nmcli device wifi connect "$SSID" password "$PSK" \
            || warn "could not activate $SSID"
        fi
        log "linux: NM/iwd ensure attempted for $SSID"
      '';
    in
    {
      options.dendritic.wifi = {
        enable = lib.mkEnableOption "dendritic Wi-Fi ensure (pass → OS)" // {
          default = true;
        };
        networks = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                options = {
                  ssid = lib.mkOption {
                    type = lib.types.str;
                    default = name;
                  };
                  passKey = lib.mkOption {
                    type = lib.types.str;
                    default = name;
                  };
                };
              }
            )
          );
          default = {
            Bubbles = {
              ssid = "Bubbles";
              passKey = "Bubbles";
            };
          };
        };
      };

      config = lib.mkIf (cfg.enable && bubbles != null) {
        home.packages = [ ensureBin ];

        # After pass materialize, ensure OS profile + auto-join.
        home.activation.dendriticWifiEnsure = lib.hm.dag.entryAfter [ "passMaterialize" "writeBoundary" ] ''
          ${ensureBin}/bin/dendritic-wifi-ensure || echo "dendritic.wifi: ensure skipped/failed" >&2
        '';

        # User agent: re-run when PSK file changes (pass sync rematerialize).
        systemd.user.paths.dendritic-wifi-ensure = lib.mkIf pkgs.stdenv.isLinux {
          Unit.Description = "Watch dendritic Wi-Fi PSK file";
          Path.PathModified = pskPath;
          Path.PathExists = pskPath;
          Install.WantedBy = [ "default.target" ];
        };
        systemd.user.services.dendritic-wifi-ensure = lib.mkIf pkgs.stdenv.isLinux {
          Unit.Description = "Ensure declarative Wi-Fi (Bubbles) via NetworkManager/iwd";
          Service = {
            Type = "oneshot";
            ExecStart = "${ensureBin}/bin/dendritic-wifi-ensure";
          };
          Install.WantedBy = [ "default.target" ];
        };

        launchd.agents.dendritic-wifi-ensure = lib.mkIf pkgs.stdenv.isDarwin {
          enable = true;
          config = {
            Label = "com.dendritic.wifi-ensure";
            ProgramArguments = [ "${ensureBin}/bin/dendritic-wifi-ensure" ];
            RunAtLoad = true;
            WatchPaths = [ pskPath ];
            StandardOutPath = "${config.home.homeDirectory}/.cache/dendritic-wifi-ensure.log";
            StandardErrorPath = "${config.home.homeDirectory}/.cache/dendritic-wifi-ensure.err.log";
          };
        };
      };
    };
}
