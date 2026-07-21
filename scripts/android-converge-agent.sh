#!/usr/bin/env bash
# Periodic nix-android converge for oneplus6t (or ANDROID_CONVERGE_DEVICE).
#
# Runs on mba (launchd) and sliceanddice (systemd). Cross-host exclusion uses a
# short lease on the phone under /data/local/tmp so only one controller applies
# at a time. Local flock prevents overlapping runs on the same host.
#
# Always writes ~/.cache/android-converge.status (tray + badges). When the phone
# is reachable, also heartbeats hosts/oneplus6t.json into the private fleet repo
# (platform=android) so README shields stay current.
#
# Env (set by the HM wrapper):
#   ANDROID_CONVERGE_HOST_ID   — mba | sliceanddice | …
#   ANDROID_CONVERGE_FLAKE     — /path/to/.dotfiles#oneplus6t-darwin
#   ANDROID_CONVERGE_DEVICE    — device.name (default oneplus6t)
#   ANDROID_CONVERGE_BIN       — path to android-rebuild
#   ANDROID_CONVERGE_ADB_WIRELESS_BIN — path to adb-wireless (optional)
#   ANDROID_CONVERGE_LEASE_TTL — seconds (default 600)
#   ANDROID_CONVERGE_APPLY     — 1 to switch (default), 0 for plan-only
#   ANDROID_CONVERGE_STATUS    — status JSON path (optional)
#   FLEET_STATUS_TOKEN_FILE / GH_TOKEN / FLEET_* — optional fleet heartbeat
set -euo pipefail

HOST_ID="${ANDROID_CONVERGE_HOST_ID:?ANDROID_CONVERGE_HOST_ID required}"
FLAKE="${ANDROID_CONVERGE_FLAKE:?ANDROID_CONVERGE_FLAKE required}"
DEVICE="${ANDROID_CONVERGE_DEVICE:-oneplus6t}"
BIN="${ANDROID_CONVERGE_BIN:?ANDROID_CONVERGE_BIN required}"
ADB_WIRELESS_BIN="${ANDROID_CONVERGE_ADB_WIRELESS_BIN:-}"
LEASE_TTL="${ANDROID_CONVERGE_LEASE_TTL:-600}"
APPLY="${ANDROID_CONVERGE_APPLY:-1}"
LOCK_DIR="${ANDROID_CONVERGE_LOCK:-$HOME/.cache/android-converge.lock}"
STATUS_FILE="${ANDROID_CONVERGE_STATUS:-$HOME/.cache/android-converge.status}"
LEASE_REMOTE="/data/local/tmp/nix-android-${DEVICE}.lease"
LOG_PREFIX="android-converge"

log() { printf '%s %s: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$LOG_PREFIX" "$*"; }
warn() { log "warning: $*" >&2; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || {
  warn "missing $1; skip"
  write_status unreachable "missing $1" "" none
  exit 0
}; }
need_bin() { [[ -x $1 ]] || {
  warn "missing executable $1; skip"
  write_status unreachable "missing $1" "" none
  exit 0
}; }

utc_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

config_rev() {
  local root="${FLAKE%%#*}"
  if [[ -n $root && -d $root/.git ]]; then
    git -C "$root" rev-parse --short=8 HEAD 2>/dev/null || echo unknown
  else
    echo unknown
  fi
}

# Persist tray/badge status. Preserves last_ok_at across skips when reachable.
write_status() {
  local state=$1 message=$2 serial=${3:-} transport=${4:-none}
  local reachable=0
  [[ $transport != "none" && -n $serial ]] && reachable=1
  local now lease_holder="" last_ok=""
  now="$(utc_now)"
  if [[ -f $STATUS_FILE ]]; then
    last_ok="$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d.get("last_ok_at") or "")' "$STATUS_FILE" 2>/dev/null || true)"
  fi
  if [[ $state == "synced" ]]; then
    last_ok="$now"
  fi
  if [[ -n $serial ]] && command -v adb >/dev/null 2>&1; then
    lease_holder="$(read_lease "$serial" | sed -n 's/^hostId=//p' | head -1 || true)"
  fi
  mkdir -p "$(dirname "$STATUS_FILE")"
  python3 - "$STATUS_FILE" "$DEVICE" "$state" "$message" "$serial" "$transport" "$reachable" "$now" "$last_ok" "$HOST_ID" "$(config_rev)" "$lease_holder" <<'PY'
import json, sys
from pathlib import Path
(
    path, device, state, message, serial, transport, reachable, now, last_ok,
    controller, config_rev, lease_holder,
) = sys.argv[1:]
out = {
    "schema": 1,
    "updated_at": now,
    "device": device,
    "serial": serial,
    "transport": transport,
    "reachable": reachable == "1",
    "state": state,
    "message": message,
    "lease_holder": lease_holder or "",
    "last_ok_at": last_ok or "",
    "controller": controller,
    "config_rev": config_rev,
}
Path(path).write_text(json.dumps(out, indent=2) + "\n")
PY
}

# Public-safe phone presence → private dendritic-fleet-status hosts/<device>.json
fleet_heartbeat_android() {
  command -v gh >/dev/null 2>&1 || return 0
  command -v jq >/dev/null 2>&1 || return 0
  if [[ -n ${FLEET_STATUS_TOKEN_FILE:-} && -r ${FLEET_STATUS_TOKEN_FILE} ]]; then
    token="$(tr -d '[:space:]' <"$FLEET_STATUS_TOKEN_FILE")"
    if [[ -n $token && $token != placeholder ]]; then
      export GH_TOKEN="$token"
    fi
  fi
  if ! gh auth status -h github.com >/dev/null 2>&1 && [[ -z ${GH_TOKEN:-} ]]; then
    return 0
  fi
  local owner="${FLEET_STATUS_OWNER:-aspauldingcode}"
  local repo="${FLEET_STATUS_REPO:-dendritic-fleet-status}"
  local path_in_repo="hosts/${DEVICE}.json"
  local seen_at rev payload api sha b64 body
  seen_at="$(utc_now)"
  rev="$(config_rev)"
  [[ $rev =~ ^[0-9a-f]{7,40}$ ]] || rev="00000000"
  payload="$(jq -nc \
    --arg host "$DEVICE" \
    --arg platform "android" \
    --arg flake_rev "$rev" \
    --arg seen_at "$seen_at" \
    '{host:$host, platform:$platform, flake_rev:$flake_rev, seen_at:$seen_at, schema:1}')"
  api="repos/${owner}/${repo}/contents/${path_in_repo}"
  sha=""
  if meta="$(gh api "$api" 2>/dev/null)"; then
    sha="$(printf '%s' "$meta" | jq -r '.sha // empty')"
  fi
  b64="$(printf '%s' "$payload" | base64 | tr -d '\n')"
  body="$(jq -nc \
    --arg msg "heartbeat: ${DEVICE} ${seen_at}" \
    --arg content "$b64" \
    --arg sha "$sha" \
    'if $sha != "" then {message:$msg, content:$content, sha:$sha} else {message:$msg, content:$content} end')"
  if ! printf '%s' "$body" | gh api --method PUT "$api" --input - >/dev/null 2>&1; then
    warn "fleet heartbeat for $DEVICE failed (non-fatal)"
    return 0
  fi
  log "fleet heartbeat ok $DEVICE tip=$rev"
}

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
# Prints: SERIAL<TAB>TRANSPORT
resolve_serial() {
  local usb w serial
  usb=$(adb devices | awk 'NR>1 && $2=="device" && $1 !~ /:/ { print $1; exit }')
  if [[ -n ${usb:-} ]]; then
    printf '%s\tusb\n' "$usb"
    return 0
  fi

  if [[ -n $ADB_WIRELESS_BIN && -x $ADB_WIRELESS_BIN ]]; then
    "$ADB_WIRELESS_BIN" connect >/dev/null 2>&1 || true
    w=$("$ADB_WIRELESS_BIN" serial 2>/dev/null || true)
    if [[ -n ${w:-} ]]; then
      printf '%s\twireless\n' "$w"
      return 0
    fi
  fi

  serial=$(adb devices | awk 'NR>1 && $2=="device" && $1 ~ /:/ { print $1; exit }')
  if [[ -n ${serial:-} ]]; then
    printf '%s\twireless\n' "$serial"
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
  if [[ -n $body ]]; then
    holder=$(printf '%s\n' "$body" | sed -n 's/^hostId=//p' | head -1)
    exp=$(printf '%s\n' "$body" | sed -n 's/^expires=//p' | head -1)
    if [[ -n $holder && -n $exp && $exp =~ ^[0-9]+$ && $exp -gt $now ]]; then
      if [[ $holder == "$HOST_ID" ]]; then
        write_lease "$serial" "$expires"
        return 0
      fi
      log "skip: lease held by $holder until $exp"
      write_status skipped "lease held by $holder" "$serial" "${TRANSPORT:-wireless}"
      return 1
    fi
  fi
  write_lease "$serial" "$expires"
  body=$(read_lease "$serial")
  holder=$(printf '%s\n' "$body" | sed -n 's/^hostId=//p' | head -1)
  if [[ $holder != "$HOST_ID" ]]; then
    log "skip: lost lease race to ${holder:-unknown}"
    write_status skipped "lost lease race" "$serial" "${TRANSPORT:-wireless}"
    return 1
  fi
  return 0
}

main() {
  need_cmd adb
  need_bin "$BIN"

  if ! acquire_local_lock; then
    log "skip: another converge running on this host"
    write_status skipped "local lock held" "" none
    exit 0
  fi
  # shellcheck disable=SC2064
  trap release_local_lock EXIT

  local serial_line serial
  TRANSPORT=none
  if ! serial_line=$(resolve_serial); then
    log "skip: no adb device (USB or wireless)"
    write_status unreachable "no adb device" "" none
    exit 0
  fi
  serial="${serial_line%%$'\t'*}"
  TRANSPORT="${serial_line#*$'\t'}"
  log "serial=$serial transport=$TRANSPORT host=$HOST_ID flake=$FLAKE"

  # Phone is up → refresh public badge source (even if we skip apply).
  fleet_heartbeat_android || true

  if ! acquire_device_lease "$serial"; then
    exit 0
  fi
  # shellcheck disable=SC2064
  trap "clear_lease $(printf '%q' "$serial"); release_local_lock" EXIT

  local cmd=("$BIN")
  if [[ $APPLY == "1" ]]; then
    cmd+=(switch)
  else
    cmd+=(plan)
  fi
  cmd+=(--flake "$FLAKE" --serial "$serial")

  log "running: ${cmd[*]}"
  write_status running "converge ${cmd[1]}" "$serial" "$TRANSPORT"
  if "${cmd[@]}"; then
    log "ok"
    write_status synced "converge ok" "$serial" "$TRANSPORT"
  else
    warn "converge failed (exit $?)"
    write_status error "converge failed" "$serial" "$TRANSPORT"
    exit 0 # timer should not flap
  fi
}

main "$@"
