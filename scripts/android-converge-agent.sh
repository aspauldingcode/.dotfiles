#!/usr/bin/env bash
# Periodic nix-android converge for oneplus6t (or ANDROID_CONVERGE_DEVICE).
#
# Runs on mba (launchd) and sliceanddice (systemd). Cross-host exclusion uses a
# short lease on the phone under /data/local/tmp so only one controller applies
# at a time. Local flock prevents overlapping runs on the same host.
#
# Env (set by the HM wrapper):
#   ANDROID_CONVERGE_HOST_ID   — mba | sliceanddice | …
#   ANDROID_CONVERGE_FLAKE     — /path/to/.dotfiles#oneplus6t-darwin
#   ANDROID_CONVERGE_DEVICE    — device.name (default oneplus6t)
#   ANDROID_CONVERGE_BIN       — path to android-rebuild
#   ANDROID_CONVERGE_ADB_WIRELESS_BIN — path to adb-wireless (optional)
#   ANDROID_CONVERGE_LEASE_TTL — seconds (default 600)
#   ANDROID_CONVERGE_APPLY     — 1 to switch (default), 0 for plan-only
set -euo pipefail

HOST_ID="${ANDROID_CONVERGE_HOST_ID:?ANDROID_CONVERGE_HOST_ID required}"
FLAKE="${ANDROID_CONVERGE_FLAKE:?ANDROID_CONVERGE_FLAKE required}"
DEVICE="${ANDROID_CONVERGE_DEVICE:-oneplus6t}"
BIN="${ANDROID_CONVERGE_BIN:?ANDROID_CONVERGE_BIN required}"
ADB_WIRELESS_BIN="${ANDROID_CONVERGE_ADB_WIRELESS_BIN:-}"
LEASE_TTL="${ANDROID_CONVERGE_LEASE_TTL:-600}"
APPLY="${ANDROID_CONVERGE_APPLY:-1}"
LOCK_DIR="${ANDROID_CONVERGE_LOCK:-$HOME/.cache/android-converge.lock}"
LEASE_REMOTE="/data/local/tmp/nix-android-${DEVICE}.lease"
LOG_PREFIX="android-converge"

log() { printf '%s %s: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$LOG_PREFIX" "$*"; }
warn() { log "warning: $*" >&2; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || {
  warn "missing $1; skip"
  exit 0
}; }
need_bin() { [[ -x "$1" ]] || {
  warn "missing executable $1; skip"
  exit 0
}; }

acquire_local_lock() {
  mkdir -p "$(dirname "$LOCK_DIR")"
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    printf '%s\n' "$$" >"$LOCK_DIR/pid"
    return 0
  fi
  if [[ -f $LOCK_DIR/pid ]]; then
    local old
    old="$(tr -d '[:space:]' <"$LOCK_DIR/pid" 2>/dev/null || true)"
    if [[ -n $old ]] && ! kill -0 "$old" 2>/dev/null; then
      warn "removing stale local lock (pid $old dead)"
      rm -rf "$LOCK_DIR"
      mkdir "$LOCK_DIR"
      printf '%s\n' "$$" >"$LOCK_DIR/pid"
      return 0
    fi
  fi
  return 1
}

release_local_lock() {
  rm -rf "$LOCK_DIR" 2>/dev/null || true
}

now_epoch() { date +%s; }

# Resolve a live serial: USB first, else wireless (saved endpoint / connect).
resolve_serial() {
  local usb w serial
  usb=$(adb devices | awk 'NR>1 && $2=="device" && $1 !~ /:/ { print $1; exit }')
  if [[ -n "${usb:-}" ]]; then
    printf '%s\n' "$usb"
    return 0
  fi

  if [[ -n "$ADB_WIRELESS_BIN" && -x "$ADB_WIRELESS_BIN" ]]; then
    "$ADB_WIRELESS_BIN" connect >/dev/null 2>&1 || true
    w=$("$ADB_WIRELESS_BIN" serial 2>/dev/null || true)
    if [[ -n "${w:-}" ]]; then
      printf '%s\n' "$w"
      return 0
    fi
  fi

  # Fallback: any wireless device already in adb
  serial=$(adb devices | awk 'NR>1 && $2=="device" && $1 ~ /:/ { print $1; exit }')
  if [[ -n "${serial:-}" ]]; then
    printf '%s\n' "$serial"
    return 0
  fi
  return 1
}

read_lease() {
  local serial=$1
  adb -s "$serial" shell "cat $(printf '%q' "$LEASE_REMOTE") 2>/dev/null" | tr -d '\r' || true
}

write_lease() {
  local serial=$1 expires=$2
  adb -s "$serial" shell "printf 'hostId=%s\nexpires=%s\ndevice=%s\n' $(printf '%q' "$HOST_ID") $(printf '%q' "$expires") $(printf '%q' "$DEVICE") >$(printf '%q' "$LEASE_REMOTE")"
}

clear_lease() {
  local serial=$1
  adb -s "$serial" shell "rm -f $(printf '%q' "$LEASE_REMOTE")" >/dev/null 2>&1 || true
}

# Returns 0 if we hold / acquired the lease.
acquire_device_lease() {
  local serial=$1 now expires holder exp body
  now=$(now_epoch)
  expires=$((now + LEASE_TTL))
  body=$(read_lease "$serial")
  if [[ -n "$body" ]]; then
    holder=$(printf '%s\n' "$body" | sed -n 's/^hostId=//p' | head -1)
    exp=$(printf '%s\n' "$body" | sed -n 's/^expires=//p' | head -1)
    if [[ -n "$holder" && -n "$exp" && "$exp" =~ ^[0-9]+$ && "$exp" -gt "$now" ]]; then
      if [[ "$holder" == "$HOST_ID" ]]; then
        write_lease "$serial" "$expires"
        return 0
      fi
      log "skip: lease held by $holder until $exp"
      return 1
    fi
  fi
  write_lease "$serial" "$expires"
  # Re-read to detect a race (two controllers writing).
  body=$(read_lease "$serial")
  holder=$(printf '%s\n' "$body" | sed -n 's/^hostId=//p' | head -1)
  if [[ "$holder" != "$HOST_ID" ]]; then
    log "skip: lost lease race to ${holder:-unknown}"
    return 1
  fi
  return 0
}

main() {
  need_cmd adb
  need_bin "$BIN"

  if ! acquire_local_lock; then
    log "skip: another converge running on this host"
    exit 0
  fi
  # shellcheck disable=SC2064
  trap release_local_lock EXIT

  local serial
  if ! serial=$(resolve_serial); then
    log "skip: no adb device (USB or wireless)"
    exit 0
  fi
  log "serial=$serial host=$HOST_ID flake=$FLAKE"

  if ! acquire_device_lease "$serial"; then
    exit 0
  fi
  # shellcheck disable=SC2064
  trap "clear_lease $(printf '%q' "$serial"); release_local_lock" EXIT

  local cmd=( "$BIN" )
  if [[ "$APPLY" == "1" ]]; then
    cmd+=(switch)
  else
    cmd+=(plan)
  fi
  cmd+=(--flake "$FLAKE" --serial "$serial")

  log "running: ${cmd[*]}"
  if "${cmd[@]}"; then
    log "ok"
  else
    warn "converge failed (exit $?)"
    exit 0 # timer should not flap
  fi
}

main "$@"
