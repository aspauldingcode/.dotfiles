#!/usr/bin/env bash
# Wireless adb helpers for nix-android / android-rebuild.
#
#   adb-wireless pair HOST:PAIR_PORT [CODE]   # Android 11+ Wireless debugging
#   adb-wireless connect [HOST:PORT]          # connect (default: last used)
#   adb-wireless tcpip [PORT]                # USB → enable TCP; then connect
#   adb-wireless disconnect [HOST:PORT|all]
#   adb-wireless status
#   adb-wireless serial                      # print connected wireless serial
#
# After connect, use the printed IP:PORT as --serial for android-rebuild.
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/adb-wireless"
LAST_FILE="$STATE_DIR/last-endpoint"
DEFAULT_TCPIP_PORT=5555

die() {
  echo "error: $*" >&2
  exit 1
}
log() { echo "$*" >&2; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing $1 (install android-tools)"; }

usage() {
  sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
}

is_endpoint() {
  [[ ${1:-} =~ ^[0-9a-fA-F.:]+:[0-9]+$ ]]
}

save_last() {
  mkdir -p "$STATE_DIR"
  printf '%s\n' "$1" >"$LAST_FILE"
}

load_last() {
  [[ -f $LAST_FILE ]] || die "no saved endpoint; pass HOST:PORT or run pair/tcpip first"
  cat "$LAST_FILE"
}

usb_serials() {
  adb devices | awk 'NR>1 && $2=="device" && $1 !~ /:/ { print $1 }'
}

wireless_serials() {
  adb devices | awk 'NR>1 && $2=="device" && $1 ~ /:/ { print $1 }'
}

print_rebuild_hint() {
  local serial=$1 flake_ref
  flake_ref="${ADB_WIRELESS_FLAKE:-}"
  if [[ -z $flake_ref ]]; then
    case "$(uname -s)-$(uname -m)" in
    Darwin-arm64) flake_ref=".#oneplus6t-darwin" ;;
    Linux-x86_64) flake_ref=".#oneplus6t-linux" ;;
    *) flake_ref=".#oneplus6t-darwin" ;;
    esac
  fi
  log ""
  log "Wireless serial: $serial"
  log "Example:"
  log "  nix run .#android-rebuild -- plan --flake $flake_ref --serial $serial"
}

cmd_status() {
  need adb
  log "adb devices -l"
  adb devices -l
  if [[ -f $LAST_FILE ]]; then
    log ""
    log "last endpoint: $(cat "$LAST_FILE")"
  fi
  local w
  w=$(wireless_serials || true)
  if [[ -n ${w:-} ]]; then
    log ""
    log "wireless (use as --serial):"
    printf '%s\n' "$w" >&2
  fi
}

cmd_serial() {
  need adb
  local w
  w=$(wireless_serials | head -n1 || true)
  [[ -n ${w:-} ]] || die "no wireless device connected (run: adb-wireless connect)"
  printf '%s\n' "$w"
}

cmd_pair() {
  need adb
  local endpoint=${1:-} code=${2:-}
  is_endpoint "$endpoint" || die "usage: adb-wireless pair HOST:PAIR_PORT [CODE]"
  if [[ -z $code ]]; then
    log "Enter the 6-digit pairing code shown under Wireless debugging → Pair device with pairing code"
    read -r -p "pairing code: " code
  fi
  [[ $code =~ ^[0-9]{6}$ ]] || die "pairing code must be 6 digits"
  log "pairing $endpoint ..."
  adb pair "$endpoint" "$code"
  log "Paired. In Wireless debugging, note the IP and port under 'IP address & Port', then:"
  log "  adb-wireless connect HOST:PORT"
}

cmd_connect() {
  need adb
  local endpoint=${1:-}
  if [[ -z $endpoint ]]; then
    endpoint=$(load_last)
  else
    is_endpoint "$endpoint" || die "usage: adb-wireless connect [HOST:PORT]"
  fi
  log "connecting $endpoint ..."
  adb connect "$endpoint"
  # Wait briefly for device to show as "device"
  local i
  for i in 1 2 3 4 5 6 7 8 9 10; do
    if adb devices | awk -v e="$endpoint" '$1==e && $2=="device" { found=1 } END { exit !found }'; then
      save_last "$endpoint"
      print_rebuild_hint "$endpoint"
      return 0
    fi
    sleep 0.5
  done
  adb devices -l >&2 || true
  die "connected but device not ready (authorize the RSA prompt on the phone if shown)"
}

cmd_tcpip() {
  need adb
  local port=${1:-$DEFAULT_TCPIP_PORT}
  [[ $port =~ ^[0-9]+$ ]] || die "usage: adb-wireless tcpip [PORT]"

  local serial ip endpoint usb_count=0 first_usb=""
  while IFS= read -r line; do
    [[ -z $line ]] && continue
    usb_count=$((usb_count + 1))
    [[ -z $first_usb ]] && first_usb=$line
  done < <(usb_serials)
  if [[ $usb_count -eq 0 ]]; then
    die "no USB adb device online — plug in once, authorize debugging, then retry"
  fi
  if [[ $usb_count -gt 1 ]]; then
    log "multiple USB devices; using ${first_usb} (set ANDROID_SERIAL to pick)"
  fi
  serial="${ANDROID_SERIAL:-$first_usb}"

  log "enabling tcpip on $serial (port $port) ..."
  adb -s "$serial" tcpip "$port"
  sleep 1

  ip=$(adb -s "$serial" shell ip -f inet addr show wlan0 2>/dev/null |
    awk '/inet / { sub(/\/.*/, "", $2); print $2; exit }' || true)
  if [[ -z ${ip:-} ]]; then
    ip=$(adb -s "$serial" shell ip route 2>/dev/null |
      awk '/wlan0/ { for (i=1;i<=NF;i++) if ($i=="src") { print $(i+1); exit } }' || true)
  fi
  [[ -n ${ip:-} ]] || die "could not read wlan0 IP — phone on Wi-Fi? then: adb-wireless connect IP:$port"

  endpoint="${ip}:${port}"
  log "phone Wi-Fi IP: $ip"
  cmd_connect "$endpoint"
}

cmd_disconnect() {
  need adb
  local target=${1:-}
  if [[ -z $target || $target == "all" ]]; then
    adb disconnect
    return 0
  fi
  is_endpoint "$target" || die "usage: adb-wireless disconnect [HOST:PORT|all]"
  adb disconnect "$target"
}

main() {
  local cmd=${1:-status}
  shift || true
  case "$cmd" in
  -h | --help | help) usage ;;
  status | devices) cmd_status "$@" ;;
  serial) cmd_serial "$@" ;;
  pair) cmd_pair "$@" ;;
  connect) cmd_connect "$@" ;;
  tcpip) cmd_tcpip "$@" ;;
  disconnect) cmd_disconnect "$@" ;;
  *)
    usage
    die "unknown command: $cmd"
    ;;
  esac
}

main "$@"
