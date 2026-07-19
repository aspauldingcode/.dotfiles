#!/usr/bin/env bash
# Import remembered Wi-Fi PSKs from macOS Keychain (or stdin) into pass SecretSpec.
#
#   pass-wifi-bootstrap                 # Keychain → pass for all declared nets
#   pass-wifi-bootstrap --from-clipboard --ssid "Indaba Guest"
#   pass-wifi-bootstrap --dry-run
#
# Then: pass-materialize && dendritic-wifi-ensure
#
# macOS will prompt Keychain Access — choose "Always Allow" for security(1).
# Each missing SSID waits up to KEYCHAIN_TIMEOUT secs (default 90).
set -euo pipefail

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
export PASSWORD_STORE_DIR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NETWORKS_JSON="${WIFI_NETWORKS_JSON:-$REPO_ROOT/home/wifi-networks.json}"
KEYCHAIN_TIMEOUT="${KEYCHAIN_TIMEOUT:-90}"

DRY=false
FROM_CLIPBOARD=false
ONLY_SSID=""
YES=false

die() {
  echo "error: $*" >&2
  exit 1
}
log() { echo "$*"; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing $1"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
  --dry-run) DRY=true ;;
  --from-clipboard) FROM_CLIPBOARD=true ;;
  --ssid)
    ONLY_SSID="${2:?}"
    shift
    ;;
  --yes | -y) YES=true ;;
  --timeout)
    KEYCHAIN_TIMEOUT="${2:?}"
    shift
    ;;
  -h | --help)
    sed -n '2,14p' "$0" | sed 's/^# //; s/^#//'
    exit 0
    ;;
  *) die "unknown arg: $1" ;;
  esac
  shift
done

need pass
need git
need python3
[[ -r $NETWORKS_JSON ]] || die "missing networks JSON: $NETWORKS_JSON"

# Keychain ACL dialogs can hang forever — kill after N seconds.
with_timeout() {
  local secs="$1"
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

find_psk() {
  local ssid="$1" psk=""
  if [[ "$(uname -s)" != Darwin ]]; then
    return 1
  fi
  # One primary lookup (System.keychain AirPort). Approve Always Allow when prompted.
  psk=$(with_timeout "$KEYCHAIN_TIMEOUT" security find-generic-password \
    -a "$ssid" -s AirPort -w /Library/Keychains/System.keychain 2>/dev/null || true)
  [[ -n $psk ]] || psk=$(with_timeout 15 security find-generic-password \
    -D "AirPort network password" -a "$ssid" -w 2>/dev/null || true)
  [[ -n $psk ]] || return 1
  printf '%s' "$psk"
}

pass_put() {
  local key="$1" value="$2"
  local path="secretspec/shared/default/$key"
  if $DRY; then
    log "dry-run: would write pass:$path (len=${#value})"
    return 0
  fi
  printf '%s\n' "$value" | pass insert -e -f "$path" >/dev/null
  log "pass: wrote $path (len=${#value})"
}

pass_commit() {
  $DRY && return 0
  git -C "$PASSWORD_STORE_DIR" add -A
  if git -C "$PASSWORD_STORE_DIR" status --porcelain | grep -q .; then
    git -C "$PASSWORD_STORE_DIR" -c user.useConfigOnly=true commit -m "$1" >/dev/null 2>&1 ||
      git -C "$PASSWORD_STORE_DIR" -c user.name="pass-wifi-bootstrap" \
        -c user.email="pass-wifi-bootstrap@localhost" commit -m "$1" >/dev/null
    git -C "$PASSWORD_STORE_DIR" push >/dev/null 2>&1 ||
      log "warning: pass git push failed (peers catch up via sync)"
  fi
}

mapfile -t ROWS < <(
  python3 - "$NETWORKS_JSON" <<'PY'
import json, sys
for n in json.load(open(sys.argv[1])):
    print("|".join([
        n["ssid"],
        n.get("passKey") or "",
        n.get("keyMgmt") or "wpa-psk",
    ]))
PY
)

if [[ "$(uname -s)" == Darwin ]] && ! $FROM_CLIPBOARD; then
  log "Keychain export: for each missing SSID, click Always Allow (timeout ${KEYCHAIN_TIMEOUT}s)."
  if command -v osascript >/dev/null 2>&1; then
    osascript -e 'display notification "Approve Keychain Access: Always Allow for each Wi-Fi PSK" with title "pass-wifi-bootstrap"' 2>/dev/null || true
  fi
fi

imported=0
skipped=0
missing=0

for row in "${ROWS[@]}"; do
  IFS='|' read -r ssid key mgmt <<<"$row"
  if [[ -n $ONLY_SSID && $ssid != "$ONLY_SSID" ]]; then
    continue
  fi

  if [[ $mgmt == none ]]; then
    log "open/captive: $ssid (no PSK — keyMgmt=none)"
    skipped=$((skipped + 1))
    continue
  fi

  # Prefer existing pass entry (skip Keychain hang) unless --yes / clipboard.
  if ! $FROM_CLIPBOARD && ! $YES && pass show "secretspec/shared/default/$key" >/dev/null 2>&1; then
    existing="$(pass show "secretspec/shared/default/$key" 2>/dev/null | head -n1 | tr -d '\r\n' || true)"
    if [[ -n $existing ]]; then
      log "ok: $ssid already in pass ($key)"
      skipped=$((skipped + 1))
      continue
    fi
  fi

  psk=""
  if $FROM_CLIPBOARD; then
    if command -v pbpaste >/dev/null 2>&1; then
      psk="$(pbpaste | tr -d '\r\n')"
    elif command -v wl-paste >/dev/null 2>&1; then
      psk="$(wl-paste | tr -d '\r\n')"
    else
      die "no clipboard tool"
    fi
  else
    log "keychain: $ssid (click Always Allow if prompted)…"
    psk="$(find_psk "$ssid" || true)"
  fi

  if [[ -z $psk ]]; then
    log "MISSING: $ssid (pass key $key) — approve Keychain Always Allow, or:"
    log "  printf '%s\\n' 'PSK' | pass insert -e secretspec/shared/default/$key"
    log "  pass-wifi-bootstrap --ssid \"$ssid\" --from-clipboard"
    missing=$((missing + 1))
    continue
  fi

  pass_put "$key" "$psk"
  imported=$((imported + 1))
  $FROM_CLIPBOARD && ONLY_SSID="$ssid" && break
done

pass_commit "wifi: import remembered SSIDs into secretspec"

log "done. imported=$imported skipped=$skipped missing=$missing"
log "Next: pass-materialize && dendritic-wifi-ensure"
