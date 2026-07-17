# Dendritic Wi-Fi — declarative known networks (pass-backed PSK).
#
# NixOS: NetworkManager + iwd (linux-desktop.nix). Profiles applied by
#   dendritic-wifi-ensure after pass materialize — never during nixos-rebuild.
# Darwin: networksetup preferred-network upsert + join (HM ensure / launchd).
#
# PSK never enters the Nix store — materialized from pass SecretSpec keys →
#   ~/.config/dendritic/wifi/<passKey>.psk
#
# Bootstrap Keychain → pass (mba): nix run .#pass-wifi-bootstrap
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
    in
    {
      options.dendritic.wifi = {
        enable = lib.mkEnableOption "dendritic declarative Wi-Fi (pass PSK)" // {
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
                    type = lib.types.nullOr lib.types.str;
                    default = name;
                    description = "SecretSpec key under secretspec/shared/default/ (null if open).";
                  };
                  keyMgmt = lib.mkOption {
                    type = lib.types.enum [
                      "wpa-psk"
                      "none"
                    ];
                    default = "wpa-psk";
                    description = "Wi-Fi security: wpa-psk or open (captive portal).";
                  };
                  autoconnectPriority = lib.mkOption {
                    type = lib.types.int;
                    default = 50;
                  };
                };
              }
            )
          );
          default = { };
          description = "Known Wi-Fi networks (shared defaults come from HM module).";
        };
        stateDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/dendritic/wifi";
          description = "Root-owned directory for optional PSK copies (not in Nix store).";
        };
      };

      config = lib.mkIf cfg.enable {
        networking.networkmanager.wifi.powersave = lib.mkDefault false;
        networking.wireless.iwd.settings = {
          General.EnableNetworkConfiguration = lib.mkDefault false;
        };
        systemd.tmpfiles.rules = [
          "d ${cfg.stateDir} 0750 root root -"
        ];

        # Soft-unblock + force radio on at boot (before user session).
        # Without this, some machines come up with WIFI soft-blocked / nm radio off.
        systemd.services.dendritic-wifi-radio = {
          description = "Unblock Wi-Fi radio and enable NetworkManager wifi";
          after = [
            "NetworkManager.service"
            "iwd.service"
          ];
          wants = [ "NetworkManager.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "dendritic-wifi-radio" ''
              set -euo pipefail
              ${pkgs.util-linux}/bin/rfkill unblock wifi || true
              ${pkgs.util-linux}/bin/rfkill unblock wlan || true
              ${pkgs.networkmanager}/bin/nmcli radio wifi on || true
            '';
          };
        };

        environment.systemPackages = [
          (pkgs.writeShellScriptBin "dendritic-wifi-nm-reload" ''
            set -euo pipefail
            ${pkgs.util-linux}/bin/rfkill unblock wifi || true
            ${pkgs.networkmanager}/bin/nmcli radio wifi on || true
            ${pkgs.networkmanager}/bin/nmcli connection reload || true
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
        enable = lib.mkEnableOption "dendritic declarative Wi-Fi (pass PSK)" // {
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
                  uuid = lib.mkOption {
                    type = lib.types.str;
                    default = "";
                  };
                  passKey = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = name;
                  };
                  keyMgmt = lib.mkOption {
                    type = lib.types.enum [
                      "wpa-psk"
                      "none"
                    ];
                    default = "wpa-psk";
                  };
                  autoconnectPriority = lib.mkOption {
                    type = lib.types.int;
                    default = 50;
                  };
                };
              }
            )
          );
          default = { };
        };
      };

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

      # Shared fleet defaults — SSIDs/UUIDs/pass keys (never PSKs) live in JSON.
      defaultNetworksList = builtins.fromJSON (builtins.readFile ../home/wifi-networks.json);
      defaultNetworks = lib.listToAttrs (
        map (n: {
          name = n.id;
          value = {
            inherit (n)
              ssid
              uuid
              passKey
              keyMgmt
              autoconnectPriority
              ;
          };
        }) defaultNetworksList
      );

      networks = defaultNetworks // cfg.networks;

      networksJson = pkgs.writeText "dendritic-wifi-networks.json" (
        builtins.toJSON (
          lib.mapAttrsToList (_name: net: {
            inherit (net) ssid uuid autoconnectPriority;
            keyMgmt = net.keyMgmt or "wpa-psk";
            passKey = if (net.passKey or null) == null then null else net.passKey;
          }) networks
        )
      );

      wifiDir = "${config.home.homeDirectory}/.config/dendritic/wifi";

      ensureBin = pkgs.writeShellScriptBin "dendritic-wifi-ensure" ''
                set -euo pipefail
                LOG_PREFIX="dendritic-wifi-ensure"
                log() { printf '%s %s: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$LOG_PREFIX" "$*"; }
                warn() { log "warning: $*" >&2; }

                NETWORKS_JSON="${networksJson}"
                WIFI_DIR="${wifiDir}"
                STATE_DIR="/var/lib/dendritic/wifi"
                PYTHON="${pkgs.python3}/bin/python3"
                GREP="${pkgs.gnugrep}/bin/grep"
                TR="${pkgs.coreutils}/bin/tr"
                MKTEMP="${pkgs.coreutils}/bin/mktemp"

                with_timeout() {
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

                read_psk() {
                  local key="$1"
                  local f="$WIFI_DIR/''${key}.psk"
                  if [[ ! -r "$f" ]]; then
                    return 1
                  fi
                  "$TR" -d '\n' <"$f"
                }

                ensure_one_darwin() {
                  local ssid="$1" key_mgmt="$2" psk="''${3:-}" pass_key="''${4:-}"
                  local dev pref
                  dev="$(/usr/sbin/networksetup -listallhardwareports \
                    | /usr/bin/awk '/Wi-Fi|AirPort/{getline; print $2; exit}')"
                  if [[ -z "''${dev:-}" ]]; then
                    warn "no Wi-Fi hardware port found"
                    return 0
                  fi
                  /usr/sbin/networksetup -setairportpower "$dev" on 2>/dev/null || true
                  pref="$(/usr/sbin/networksetup -listpreferredwirelessnetworks "$dev" 2>/dev/null || true)"
                  if ! printf '%s' "$pref" | "$GREP" -Fq "$ssid"; then
                    if [[ "$key_mgmt" == none ]]; then
                      # Open / captive — add as Open system if supported; else skip password.
                      if ! with_timeout 12 /usr/sbin/networksetup -addpreferredwirelessnetworkatindex \
                        "$dev" "$ssid" 0 Open; then
                        warn "addpreferred (Open) failed for $ssid"
                      fi
                    else
                      if [[ -z "$psk" ]]; then
                        warn "PSK missing for $ssid (passKey=$pass_key); run pass-wifi-bootstrap"
                        return 0
                      fi
                      if ! with_timeout 12 /usr/sbin/networksetup -addpreferredwirelessnetworkatindex \
                        "$dev" "$ssid" 0 WPA2 "$psk"; then
                        warn "addpreferred failed for $ssid (approve admin dialog?)"
                      fi
                    fi
                  else
                    log "darwin: $ssid already preferred on $dev"
                  fi
                }

                ensure_one_linux() {
                  local ssid="$1" uuid="$2" key_mgmt="$3" prio="$4" psk="''${5:-}" pass_key="''${6:-}"
                  local have=0

                  if [[ "$key_mgmt" != none && -z "$psk" ]]; then
                    warn "PSK missing for $ssid (passKey=$pass_key); skip NM upsert"
                    return 0
                  fi

                  if [[ -n "$psk" ]]; then
                    if [[ -d "$STATE_DIR" ]] || sudo mkdir -p "$STATE_DIR" 2>/dev/null; then
                      local tmp
                      tmp="$("$MKTEMP")"
                      printf '%s\n' "$psk" >"$tmp"
                      chmod 600 "$tmp"
                      if sudo cp "$tmp" "$STATE_DIR/''${pass_key}.psk" 2>/dev/null; then
                        sudo chmod 600 "$STATE_DIR/''${pass_key}.psk" || true
                        sudo chown root:root "$STATE_DIR/''${pass_key}.psk" || true
                      fi
                      rm -f "$tmp"
                    fi
                  fi

                  # Prefer UUID match (stable) so we don't create duplicates when
                  # an old same-SSID profile already exists with a different UUID.
                  if [[ -n "$uuid" ]] && nmcli -t -f UUID connection show 2>/dev/null | "$GREP" -Fxq "$uuid"; then
                    have=1
                  elif nmcli -t -f NAME connection show 2>/dev/null | "$GREP" -Fxq "$ssid"; then
                    have=1
                  fi

                  # System profile + NM-owned PSK (psk-flags=0). Agent-owned (1)
                  # makes nmtui/GUIs re-prompt and leaves /var/lib/iwd/*.psk without
                  # a Passphrase — Wi-Fi then fails across reboot / before login.
                  # See: https://networkmanager.dev/docs/api/latest/nm-settings-nmcli.html
                  if [[ "$have" -eq 0 ]]; then
                    if [[ "$key_mgmt" == none ]]; then
                      nmcli connection add type wifi con-name "$ssid" ifname '*' ssid "$ssid" \
                        wifi-sec.key-mgmt none \
                        connection.autoconnect yes connection.autoconnect-priority "$prio" \
                        connection.uuid "$uuid" connection.permissions "" \
                        ipv4.method auto ipv6.method auto ipv6.addr-gen-mode stable-privacy \
                        || warn "nmcli add failed for $ssid"
                    else
                      nmcli connection add type wifi con-name "$ssid" ifname '*' ssid "$ssid" \
                        wifi-sec.key-mgmt wpa-psk \
                        wifi-sec.psk "$psk" wifi-sec.psk-flags 0 \
                        connection.autoconnect yes connection.autoconnect-priority "$prio" \
                        connection.uuid "$uuid" connection.permissions "" \
                        ipv4.method auto ipv6.method auto ipv6.addr-gen-mode stable-privacy \
                        || warn "nmcli add failed for $ssid"
                      # NM 1.46+ may omit psk-flags=0 from the keyfile unless forced.
                      nmcli connection modify uuid "$uuid" \
                        wifi-sec.psk "$psk" wifi-sec.psk-flags 0 \
                        connection.permissions "" 2>/dev/null || true
                    fi
                  else
                    if [[ "$key_mgmt" == none ]]; then
                      nmcli connection modify id "$ssid" \
                        wifi-sec.key-mgmt none \
                        connection.autoconnect yes connection.autoconnect-priority "$prio" \
                        connection.permissions "" \
                        802-11-wireless.ssid "$ssid" \
                        || nmcli connection modify uuid "$uuid" \
                          connection.autoconnect yes connection.permissions "" \
                        || warn "nmcli modify failed for $ssid"
                    else
                      nmcli connection modify id "$ssid" \
                        wifi-sec.key-mgmt wpa-psk \
                        wifi-sec.psk "$psk" wifi-sec.psk-flags 0 \
                        connection.autoconnect yes connection.autoconnect-priority "$prio" \
                        connection.permissions "" \
                        ipv4.method auto ipv6.method auto ipv6.addr-gen-mode stable-privacy \
                        802-11-wireless.ssid "$ssid" \
                        || nmcli connection modify uuid "$uuid" \
                          wifi-sec.key-mgmt wpa-psk \
                          wifi-sec.psk "$psk" wifi-sec.psk-flags 0 \
                          connection.autoconnect yes connection.permissions "" \
                        || warn "nmcli modify failed for $ssid"
                    fi
                  fi

                  # Drop stale same-SSID duplicates (legacy Bubbles.nmconnection, etc.)
                  if [[ -n "$uuid" ]]; then
                    while IFS=: read -r name other_uuid file; do
                      [[ "$name" == "$ssid" ]] || continue
                      [[ "$other_uuid" == "$uuid" ]] && continue
                      log "linux: deleting duplicate profile $name uuid=$other_uuid"
                      nmcli connection delete uuid "$other_uuid" 2>/dev/null || true
                    done < <(nmcli -t -f NAME,UUID,FILENAME connection show 2>/dev/null || true)
                  fi
                }

                # Parse JSON → lines: ssid|uuid|keyMgmt|prio|passKey
                mapfile -t ROWS < <("$PYTHON" - "$NETWORKS_JSON" <<'PY'
        import json, sys
        for n in json.load(open(sys.argv[1])):
            pk = n.get("passKey") or ""
            # SSID must not contain '|'; fleet SSIDs are clean.
            print("|".join([
                n["ssid"],
                n.get("uuid") or "",
                n.get("keyMgmt") or "wpa-psk",
                str(n.get("autoconnectPriority") or 50),
                pk,
            ]))
        PY
                )

                ${lib.optionalString pkgs.stdenv.isDarwin ''
                  DEV="$(/usr/sbin/networksetup -listallhardwareports \
                    | /usr/bin/awk '/Wi-Fi|AirPort/{getline; print $2; exit}')"
                  [[ -n "''${DEV:-}" ]] && /usr/sbin/networksetup -setairportpower "$DEV" on 2>/dev/null || true

                  for row in "''${ROWS[@]}"; do
                    IFS='|' read -r ssid uuid key_mgmt prio pass_key <<<"$row"
                    psk=""
                    if [[ "$key_mgmt" != none && -n "$pass_key" ]]; then
                      psk="$(read_psk "$pass_key" || true)"
                    fi
                    ensure_one_darwin "$ssid" "$key_mgmt" "$psk" "$pass_key"
                  done

                  # Join only if iface has no IPv4 yet — prefer highest-prio available later via OS.
                  if [[ -n "''${DEV:-}" ]]; then
                    if ifconfig "$DEV" 2>/dev/null | "$GREP" -q 'status: active' \
                      && ifconfig "$DEV" 2>/dev/null | "$GREP" -Eq 'inet [0-9]'; then
                      log "darwin: $DEV already active with IPv4; profiles ensured"
                    else
                      # Try home first (Bubbles), then others — best-effort.
                      for row in "''${ROWS[@]}"; do
                        IFS='|' read -r ssid uuid key_mgmt prio pass_key <<<"$row"
                        [[ "$key_mgmt" == none ]] && continue
                        psk="$(read_psk "$pass_key" || true)"
                        [[ -n "$psk" ]] || continue
                        if with_timeout 12 /usr/sbin/networksetup -setairportnetwork "$DEV" "$ssid" "$psk"; then
                          log "darwin: joined $ssid"
                          break
                        fi
                      done
                    fi
                  fi
                ''}

                ${lib.optionalString pkgs.stdenv.isLinux ''
                  # ── Linux (NetworkManager + iwd) ─────────────────────────────
                  if ! command -v nmcli >/dev/null 2>&1; then
                    warn "nmcli missing"
                    exit 0
                  fi
                  nmcli radio wifi on || true
                  ${pkgs.util-linux}/bin/rfkill unblock wifi 2>/dev/null || true

                  for row in "''${ROWS[@]}"; do
                    IFS='|' read -r ssid uuid key_mgmt prio pass_key <<<"$row"
                    psk=""
                    if [[ "$key_mgmt" != none && -n "$pass_key" ]]; then
                      psk="$(read_psk "$pass_key" || true)"
                    fi
                    ensure_one_linux "$ssid" "$uuid" "$key_mgmt" "$prio" "$psk" "$pass_key"
                    log "linux: ensured $ssid"
                  done

                  # Prefer root reload — unprivileged D-Bus ReloadConnections is polkit-denied.
                  if command -v sudo >/dev/null 2>&1; then
                    sudo -n ${pkgs.networkmanager}/bin/nmcli connection reload 2>/dev/null \
                      || ${pkgs.networkmanager}/bin/nmcli connection reload 2>/dev/null \
                      || true
                  else
                    ${pkgs.networkmanager}/bin/nmcli connection reload 2>/dev/null || true
                  fi
                ''}
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
                  uuid = lib.mkOption {
                    type = lib.types.str;
                    default = "";
                  };
                  passKey = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = name;
                  };
                  keyMgmt = lib.mkOption {
                    type = lib.types.enum [
                      "wpa-psk"
                      "none"
                    ];
                    default = "wpa-psk";
                  };
                  autoconnectPriority = lib.mkOption {
                    type = lib.types.int;
                    default = 50;
                  };
                };
              }
            )
          );
          default = { };
          description = ''
            Extra / override networks. Fleet defaults (Bubbles, Luke Skydumper,
            coffee shops, PF Guest, …) are always merged in.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [
          ensureBin
          (pkgs.writeShellScriptBin "pass-wifi-bootstrap" ''
            export WIFI_NETWORKS_JSON=${../home/wifi-networks.json}
            exec bash ${../scripts/pass-wifi-bootstrap.sh} "$@"
          '')
        ];

        home.activation.dendriticWifiEnsure = lib.hm.dag.entryAfter [ "passMaterialize" "writeBoundary" ] ''
          ${ensureBin}/bin/dendritic-wifi-ensure || echo "dendritic.wifi: ensure skipped/failed" >&2
        '';

        systemd.user.paths.dendritic-wifi-ensure = lib.mkIf pkgs.stdenv.isLinux {
          Unit.Description = "Watch dendritic Wi-Fi PSK directory";
          Path = {
            # Sentinel from pass-secretspec-materialize (not every .psk write).
            PathModified = "${wifiDir}/.ready";
            TriggerLimitIntervalSec = 120;
            TriggerLimitBurst = 6;
          };
          Install.WantedBy = [ "default.target" ];
        };
        # Path unit + HM activation start this — no WantedBy (avoids start-limit storms).
        systemd.user.services.dendritic-wifi-ensure = lib.mkIf pkgs.stdenv.isLinux {
          Unit = {
            Description = "Ensure declarative Wi-Fi profiles via NetworkManager/iwd";
            StartLimitIntervalSec = 120;
            StartLimitBurst = 3;
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.util-linux}/bin/flock -n %t/dendritic-wifi-ensure.lock ${ensureBin}/bin/dendritic-wifi-ensure";
          };
        };

        launchd.agents.dendritic-wifi-ensure = lib.mkIf pkgs.stdenv.isDarwin {
          enable = true;
          config = {
            Label = "com.dendritic.wifi-ensure";
            ProgramArguments = [ "${ensureBin}/bin/dendritic-wifi-ensure" ];
            RunAtLoad = true;
            WatchPaths = [ "${wifiDir}/.ready" ];
            StandardOutPath = "${config.home.homeDirectory}/.cache/dendritic-wifi-ensure.log";
            StandardErrorPath = "${config.home.homeDirectory}/.cache/dendritic-wifi-ensure.err.log";
          };
        };
      };
    };
}
