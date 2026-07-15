#!/usr/bin/env bash
# Refresh EWU eduroam trust (CA PEMs) into pass when online; re-apply via ensure.
# Password rotation is "change pass entry → materialize → ensure" (no fetch needed).
set -euo pipefail

LOG_PREFIX="dendritic-eduroam-rotate"
log() { printf '%s %s: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$LOG_PREFIX" "$*"; }
warn() { log "warning: $*" >&2; }

have_uplink() {
  # Any default route / ping — Bubbles, ethernet, tether.
  if command -v ping >/dev/null 2>&1; then
    ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 && return 0
    ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 && return 0
  fi
  return 1
}

if ! have_uplink; then
  warn "no uplink; skip CA refresh (offline apply still uses cached pass CA)"
  if command -v dendritic-eduroam-ensure >/dev/null 2>&1; then
    dendritic-eduroam-ensure || true
  fi
  exit 0
fi

PASS_BIN="${PASS_BIN:-pass}"
CA_KEY="secretspec/shared/default/EDUROAM_CA"
HOST="${EDUROAM_RADIUS_HOST:-lipfence02v.eastern.ewu.edu}"
PORT="${EDUROAM_RADIUS_TLS_PORT:-443}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Prefer openssl s_client to fetch current leaf when host reachable;
# fall back to keeping existing pass CA if fetch fails.
FETCHED=0
if command -v openssl >/dev/null 2>&1; then
  if echo | openssl s_client -connect "${HOST}:${PORT}" -servername "$HOST" -showcerts 2>/dev/null |
    awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{print}' >"$TMP/fetched.pem" &&
    grep -q 'BEGIN CERTIFICATE' "$TMP/fetched.pem"; then
    # Keep existing intermediate/root from pass if present; prepend new leaf.
    OLD=""
    if command -v "$PASS_BIN" >/dev/null 2>&1; then
      OLD="$("$PASS_BIN" show "$CA_KEY" 2>/dev/null || true)"
    fi
    {
      cat "$TMP/fetched.pem"
      printf '%s\n' "$OLD"
    } | awk '
      /BEGIN CERTIFICATE/{n++; buf=$0; next}
      {buf=buf ORS $0}
      /END CERTIFICATE/{
        if (!(buf in seen)) { seen[buf]=1; print buf; print "" }
        buf=""
      }
    ' >"$TMP/bundle.pem"
    if grep -q 'BEGIN CERTIFICATE' "$TMP/bundle.pem"; then
      if command -v "$PASS_BIN" >/dev/null 2>&1; then
        "$PASS_BIN" insert -m -f "$CA_KEY" <"$TMP/bundle.pem" >/dev/null 2>&1 &&
          log "updated $CA_KEY from ${HOST}:${PORT}" &&
          FETCHED=1 ||
          warn "pass insert CA failed"
      fi
    fi
  else
    warn "could not fetch certs from ${HOST}:${PORT}"
  fi
fi

if [[ $FETCHED -eq 0 ]]; then
  log "CA unchanged (using existing pass entry)"
fi

# Rematerialize + ensure
if command -v pass-materialize >/dev/null 2>&1; then
  pass-materialize || warn "pass-materialize failed"
fi
if command -v dendritic-eduroam-ensure >/dev/null 2>&1; then
  dendritic-eduroam-ensure || warn "dendritic-eduroam-ensure failed"
fi
log "done"
exit 0
