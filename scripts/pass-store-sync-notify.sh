#!/usr/bin/env bash
# Near-zero-idle upstream sync: catch-up pull, then one curl JSON long-poll
# against ntfy. On each message event, run PASS_STORE_SYNC_MODE=pull.
# Keepalive/open lines are ignored (no git activity).
set -euo pipefail

LOG_PREFIX="pass-store-sync-notify"
log() { printf '%s %s: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$LOG_PREFIX" "$*"; }
warn() { log "warning: $*" >&2; }

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
SYNC_SCRIPT="${PASS_STORE_SYNC_SCRIPT:?PASS_STORE_SYNC_SCRIPT required}"
TOPIC_FILE="${PASS_STORE_NTFY_TOPIC_FILE:-}"
SERVER="${PASS_STORE_NTFY_SERVER:-https://ntfy.sh}"
DEBOUNCE_SEC="${PASS_STORE_NOTIFY_DEBOUNCE_SEC:-1}"

pull_once() {
  PASS_STORE_SYNC_MODE=pull PASSWORD_STORE_DIR="$PASSWORD_STORE_DIR" \
    bash "$SYNC_SCRIPT" || true
}

# Catch-up after long offline (ntfy does not retain months).
log "catch-up pull"
pull_once

# sops-nix may decrypt after this agent starts (launchd/systemd race).
if [[ -n $TOPIC_FILE ]]; then
  for _ in $(seq 1 60); do
    [[ -r $TOPIC_FILE ]] && break
    sleep 1
  done
fi

if [[ -z $TOPIC_FILE || ! -r $TOPIC_FILE ]]; then
  warn "ntfy topic file missing/unreadable ($TOPIC_FILE); sleeping (no subscribe)"
  exec sleep infinity
fi

topic="$(tr -d '[:space:]' <"$TOPIC_FILE")"
if [[ -z $topic || $topic == placeholder ]]; then
  warn "ntfy topic empty/placeholder; sleeping (no subscribe)"
  exec sleep infinity
fi

# Strip trailing slash from server.
server="${SERVER%/}"
url="${server}/${topic}/json"
log "subscribe $url"

last_run=0
while true; do
  # Process substitution keeps last_run in this shell (not a pipe subshell).
  # curl exits on network drop; outer loop reconnects.
  while IFS= read -r line; do
    # Only act on real publishes (ignore open/keepalive).
    case "$line" in
    *'"event":"message"'* | *'"event": "message"'*) ;;
    *) continue ;;
    esac
    now="$(date +%s)"
    if ((now - last_run < DEBOUNCE_SEC)); then
      continue
    fi
    last_run=$now
    log "ping → pull"
    pull_once
  done < <(curl -sN --fail --retry 0 "$url" || true)
  warn "curl stream ended; reconnect in 5s"
  sleep 5
done
