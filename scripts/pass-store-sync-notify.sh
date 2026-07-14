#!/usr/bin/env bash
# Near-zero-idle upstream sync: wait for sops topic → catch-up pull →
# one curl JSON long-poll. On each message event, PASS_STORE_SYNC_MODE=pull.
# Keepalive/open lines are ignored (no git activity).
#
# Race model:
#   - Topic file comes from sops-nix (may appear after this agent starts).
#   - Wait up to PASS_STORE_NTFY_WAIT_SEC (default 120), then exit 1 so
#     KeepAlive / systemd Restart re-runs (and Darwin WatchPaths restarts
#     when the secrets dir changes).
#   - Never sleep-infinity on missing topic (that hid permanent misconfig
#     and blocked WatchPaths-driven recovery until manual kickstart).
set -euo pipefail

LOG_PREFIX="pass-store-sync-notify"
log() { printf '%s %s: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$LOG_PREFIX" "$*"; }
warn() { log "warning: $*" >&2; }

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
SYNC_SCRIPT="${PASS_STORE_SYNC_SCRIPT:?PASS_STORE_SYNC_SCRIPT required}"
TOPIC_FILE="${PASS_STORE_NTFY_TOPIC_FILE:-}"
SERVER="${PASS_STORE_NTFY_SERVER:-https://ntfy.sh}"
DEBOUNCE_SEC="${PASS_STORE_NOTIFY_DEBOUNCE_SEC:-1}"
WAIT_SEC="${PASS_STORE_NTFY_WAIT_SEC:-120}"

still_behind() {
  local remote local_head
  remote="$(git -C "$PASSWORD_STORE_DIR" ls-remote origin -q HEAD 2>/dev/null | cut -f1 || true)"
  local_head="$(git -C "$PASSWORD_STORE_DIR" rev-parse HEAD 2>/dev/null || true)"
  [[ -n $remote && -n $local_head && $remote != "$local_head" ]]
}

pull_once() {
  # Sync waits up to 45s for the lock. Extra retries only if still behind
  # (lock race that timed out, or brief GitHub ref lag after push).
  local i=0
  while ((i < 3)); do
    PASS_STORE_SYNC_MODE=pull PASSWORD_STORE_DIR="$PASSWORD_STORE_DIR" \
      bash "$SYNC_SCRIPT" || true
    i=$((i + 1))
    if ! still_behind; then
      return 0
    fi
    if ((i < 3)); then
      warn "still behind after pull; retry ${i}/2 in 2s"
      sleep 2
    fi
  done
  warn "still behind after retries; next ping/catch-up will retry"
}

wait_for_topic() {
  local i=0
  if [[ -z $TOPIC_FILE ]]; then
    warn "PASS_STORE_NTFY_TOPIC_FILE unset"
    return 1
  fi
  log "waiting up to ${WAIT_SEC}s for topic file: $TOPIC_FILE"
  while ((i < WAIT_SEC)); do
    if [[ -r $TOPIC_FILE ]]; then
      local topic
      topic="$(tr -d '[:space:]' <"$TOPIC_FILE" || true)"
      if [[ -n $topic && $topic != placeholder ]]; then
        log "topic file ready (${#topic} chars)"
        return 0
      fi
    fi
    sleep 1
    i=$((i + 1))
  done
  return 1
}

if ! wait_for_topic; then
  warn "ntfy topic not ready after ${WAIT_SEC}s ($TOPIC_FILE); exit for restart"
  exit 1
fi

topic="$(tr -d '[:space:]' <"$TOPIC_FILE")"

# Catch-up after long offline (ntfy does not retain months) — after sops ready.
log "catch-up pull"
pull_once

# Strip trailing slash from server.
server="${SERVER%/}"
url="${server}/${topic}/json"
log "subscribe $url"

last_run=0
backoff=5
while true; do
  # Process substitution keeps last_run in this shell (not a pipe subshell).
  while IFS= read -r line; do
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
    backoff=5
  done < <(curl -sN --fail --retry 0 --max-time 0 "$url" || true)
  warn "curl stream ended; reconnect in ${backoff}s"
  sleep "$backoff"
  if ((backoff < 60)); then
    backoff=$((backoff + 5))
  fi
done
