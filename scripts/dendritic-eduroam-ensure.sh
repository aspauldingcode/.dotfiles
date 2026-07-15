#!/usr/bin/env bash
# Apply EWU eduroam from materialized pass secrets — zero UI.
# Darwin: preferred WPA2E + Keychain 802.1X + trust CA PEMs
# Linux/Asahi: /var/lib/iwd/eduroam.8021x (PEAP/MSCHAPv2) + connect
set -euo pipefail

LOG_PREFIX="dendritic-eduroam-ensure"
log() { printf '%s %s: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$LOG_PREFIX" "$*"; }
warn() { log "warning: $*" >&2; }

HOME_DIR="${HOME:?HOME required}"
BASE="${DENDRITIC_EDUROAM_DIR:-$HOME_DIR/.config/dendritic/wifi/eduroam}"
IDENT_FILE="$BASE/identity"
PASS_FILE="$BASE/password"
CA_FILE="$BASE/ca.pem"
PROFILE_FILE="$BASE/profile.json"

SSID="eduroam"
ANON_DEFAULT="anonymous@ewu.edu"
MASK_DEFAULT="lipfence02v.eastern.ewu.edu"

if [[ ! -r $IDENT_FILE || ! -r $PASS_FILE || ! -r $CA_FILE ]]; then
  warn "missing materialize files under $BASE (need identity, password, ca.pem); run pass-materialize"
  exit 0
fi

IDENTITY="$(tr -d '\r\n' <"$IDENT_FILE")"
PASSWORD="$(tr -d '\r\n' <"$PASS_FILE")"
if [[ -z $IDENTITY || -z $PASSWORD ]]; then
  warn "empty identity or password"
  exit 0
fi

ANON="$ANON_DEFAULT"
MASK="$MASK_DEFAULT"
if [[ -r $PROFILE_FILE ]] && command -v jq >/dev/null 2>&1; then
  ANON="$(jq -r '.anonymous_identity // empty' "$PROFILE_FILE" 2>/dev/null || true)"
  MASK="$(jq -r '.server_domain_mask // empty' "$PROFILE_FILE" 2>/dev/null || true)"
  [[ -n $ANON ]] || ANON="$ANON_DEFAULT"
  [[ -n $MASK ]] || MASK="$MASK_DEFAULT"
fi

# Strip a single trailing newline from CA; keep PEM intact otherwise.
CA_PEM="$(cat "$CA_FILE")"
if [[ -z $CA_PEM ]]; then
  warn "empty CA PEM"
  exit 0
fi

with_timeout() {
  local secs=$1
  shift
  "$@" &
  local pid=$!
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    i=$((i + 1))
    if [[ $i -ge $secs ]]; then
      kill -9 "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      return 124
    fi
    sleep 1
  done
  wait "$pid"
}

if [[ "$(uname -s)" == Darwin ]]; then
  DEV="$(/usr/sbin/networksetup -listallhardwareports |
    /usr/bin/awk '/Wi-Fi|AirPort/{getline; print $2; exit}')"
  if [[ -z ${DEV:-} ]]; then
    warn "no Wi-Fi hardware port"
    exit 0
  fi
  /usr/sbin/networksetup -setairportpower "$DEV" on 2>/dev/null || true

  PREF="$(/usr/sbin/networksetup -listpreferredwirelessnetworks "$DEV" 2>/dev/null || true)"
  if ! printf '%s' "$PREF" | grep -Fq "$SSID"; then
    # WPA2 Enterprise preferred entry (no PSK). May need admin once.
    if ! with_timeout 12 /usr/sbin/networksetup -addpreferredwirelessnetworkatindex "$DEV" "$SSID" 0 WPA2E ''; then
      warn "addpreferred WPA2E timed out/failed (admin?); continuing Keychain upsert"
    fi
  else
    log "darwin: $SSID already preferred on $DEV"
  fi

  # Upsert 802.1X password for eapolclient (User Mode — matches live mba).
  /usr/bin/security delete-generic-password \
    -s 'com.apple.network.eap.user.item.wlan.ssid.eduroam' \
    -a "$IDENTITY" >/dev/null 2>&1 || true
  EAPOL="/usr/libexec/eapolclient"
  CTRL="/System/Library/SystemConfiguration/EAPOLController.bundle/Contents/MacOS/EAPOLController"
  SEC_ARGS=(
    /usr/bin/security add-generic-password
    -s 'com.apple.network.eap.user.item.wlan.ssid.eduroam'
    -a "$IDENTITY"
    -l eduroam
    -D '802.1X Password'
    -w "$PASSWORD"
  )
  [[ -x $EAPOL ]] && SEC_ARGS+=(-T "$EAPOL")
  [[ -x $CTRL ]] && SEC_ARGS+=(-T "$CTRL")
  if "${SEC_ARGS[@]}" 2>/dev/null; then
    log "darwin: Keychain 802.1X password upserted for $IDENTITY"
  else
    warn "Keychain 802.1X upsert failed"
  fi

  # Import CA PEMs into login keychain (trust for SSL). Best-effort, no sudo.
  TMPCA="$(mktemp -d)"
  # Split bundle into individual certs (prefer add-certificates — no Trust UI).
  awk -v d="$TMPCA" 'BEGIN{n=0} /BEGIN CERTIFICATE/{n++; f=sprintf("%s/c%d.pem", d, n)} {print > f}' <<<"$CA_PEM"
  KC="$HOME_DIR/Library/Keychains/login.keychain-db"
  for c in "$TMPCA"/c*.pem; do
    [[ -f $c ]] || continue
    /usr/bin/security add-certificates -k "$KC" "$c" 2>/dev/null || true
  done
  rm -rf "$TMPCA"
  log "darwin: CA import attempted into login keychain"

  # Skip join if already associated with IPv4 (may be Bubbles).
  if ifconfig "$DEV" 2>/dev/null | grep -q 'status: active' &&
    ifconfig "$DEV" 2>/dev/null | grep -Eq 'inet [0-9]'; then
    log "darwin: $DEV already active with IPv4; not forcing eduroam join"
  else
    # Enterprise join: networksetup -setairportnetwork does not take EAP password;
    # association uses Keychain. Trigger preferred-network reconnect best-effort.
    with_timeout 15 /usr/sbin/networksetup -setairportnetwork "$DEV" "$SSID" '' 2>/dev/null ||
      warn "setairportnetwork eduroam skipped/failed (Keychain EAPOL should AutJoin when in range)"
  fi
  log "darwin: eduroam ensure done"
  exit 0
fi

# ── Linux (NetworkManager + iwd) ───────────────────────────────────────
IWD_DIR="${DENDRITIC_IWD_DIR:-/var/lib/iwd}"
IWD_FILE="$IWD_DIR/eduroam.8021x"

# Escape password for iwd ini (backslash and special — keep simple: no multiline)
escape_ini() {
  printf '%s' "$1" | sed 's/\\/\\\\/g'
}

BODY="$(
  cat <<EOF
[Security]
EAP-Method=PEAP
EAP-Identity=$(escape_ini "$ANON")
EAP-PEAP-CACert=embed:eduroam_ca
EAP-PEAP-ServerDomainMask=$(escape_ini "$MASK")
EAP-PEAP-Phase2-Method=MSCHAPV2
EAP-PEAP-Phase2-Identity=$(escape_ini "$IDENTITY")
EAP-PEAP-Phase2-Password=$(escape_ini "$PASSWORD")

[Settings]
AutoConnect=true

[@pem@eduroam_ca]
$CA_PEM
EOF
)"

write_iwd() {
  local dest=$1
  local tmp
  tmp="$(mktemp)"
  printf '%s\n' "$BODY" >"$tmp"
  chmod 600 "$tmp"
  if [[ -w $IWD_DIR ]] || [[ -w $(dirname "$dest") ]]; then
    mv "$tmp" "$dest"
    chmod 600 "$dest"
    return 0
  fi
  if command -v sudo >/dev/null 2>&1; then
    sudo mkdir -p "$IWD_DIR" 2>/dev/null || true
    if sudo cp "$tmp" "$dest" 2>/dev/null; then
      sudo chmod 600 "$dest" || true
      sudo chown root:root "$dest" || true
      rm -f "$tmp"
      return 0
    fi
  fi
  rm -f "$tmp"
  return 1
}

if write_iwd "$IWD_FILE"; then
  log "linux: wrote $IWD_FILE"
else
  warn "could not write $IWD_FILE (need sudo / root ownership of $IWD_DIR)"
fi

# Reload iwd / NM best-effort
if command -v nmcli >/dev/null 2>&1; then
  nmcli radio wifi on || true
  # Prefer connect when not already on another active wifi with IPv4 we care about —
  # still try autoconnect eduroam if visible.
  nmcli connection reload 2>/dev/null || true
  if ! nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | grep -q "^${SSID}:"; then
    # iwd provisioning file is the source of truth; connect is best-effort
    # (SSID may be out of range). Avoid `cmd | true` under pipefail — SIGPIPE → 141.
    nmcli device wifi connect "$SSID" >/dev/null 2>&1 || true
    if command -v iwctl >/dev/null 2>&1; then
      while read -r _dev; do
        [[ -n $_dev ]] || continue
        iwctl station "$_dev" connect "$SSID" >/dev/null 2>&1 || true
      done < <(iwctl device list 2>/dev/null | awk '/station/{print $2}' || true)
    fi
  fi
fi
log "linux: eduroam ensure attempted"
exit 0
