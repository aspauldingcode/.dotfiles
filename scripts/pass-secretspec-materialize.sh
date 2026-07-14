#!/usr/bin/env bash
# Materialize secretspec → $HOME files (0600). Never writes into the Nix store
# or secrets.yaml. Shared by HM activation and post-sync hooks.
set -euo pipefail

LOG_PREFIX="pass-materialize"
log() { printf '%s %s: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$LOG_PREFIX" "$*"; }
warn() { log "warning: $*" >&2; }

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
STATUS_FILE="${PASS_STORE_SYNC_STATUS:-$HOME/.cache/pass-store-sync.status}"
MAP_FILE="${PASS_MATERIALIZE_MAP:-}"
SECRETSPEC_TOML="${PASS_SECRETSPEC_TOML:-}"
HOME_DIR="${HOME:?HOME required}"

command -v secretspec >/dev/null 2>&1 || {
  warn "secretspec not in PATH"
  exit 0
}
command -v jq >/dev/null 2>&1 || {
  warn "jq not in PATH"
  exit 0
}

if [[ -z $MAP_FILE || ! -f $MAP_FILE ]]; then
  warn "PASS_MATERIALIZE_MAP missing or unreadable"
  exit 0
fi
if [[ -z $SECRETSPEC_TOML || ! -f $SECRETSPEC_TOML ]]; then
  warn "PASS_SECRETSPEC_TOML missing or unreadable"
  exit 0
fi

export PASSWORD_STORE_DIR

materialized='[]'
count=0
while IFS= read -r key; do
  [[ -n $key ]] || continue
  rel="$(jq -r --arg k "$key" '.[$k] // empty' "$MAP_FILE")"
  [[ -n $rel ]] || continue
  # Reject absolute / traversal paths.
  case "$rel" in
  /* | *..*)
    warn "skip unsafe path for $key: $rel"
    continue
    ;;
  esac
  out="${HOME_DIR}/${rel}"
  val="$(secretspec get -f "$SECRETSPEC_TOML" "$key" 2>/dev/null || true)"
  if [[ -z $val ]]; then
    warn "$key not available yet; skip $out"
    continue
  fi
  umask 077
  mkdir -p "$(dirname "$out")"
  printf '%s\n' "$val" >"$out"
  chmod 600 "$out"
  materialized="$(jq -nc --argjson arr "$materialized" --arg p "$rel" '$arr + [$p]')"
  count=$((count + 1))
  log "wrote $out"
done < <(jq -r 'keys[]' "$MAP_FILE")

# Merge materialize fields into status if present (best-effort; no plaintext).
if [[ -f $STATUS_FILE ]] && command -v jq >/dev/null 2>&1; then
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  tmp="$(mktemp "${STATUS_FILE}.XXXXXX")"
  if jq -nc \
    --slurpfile prev "$STATUS_FILE" \
    --argjson materialized "$materialized" \
    --arg now "$now" \
    --arg msg "materialized ${count} file(s)" \
    '
      ($prev[0] // {})
      + {
          last_materialize_at: $now,
          materialized: $materialized,
          updated_at: $now,
          message: $msg
        }
    ' >"$tmp" 2>/dev/null; then
    mv "$tmp" "$STATUS_FILE"
  else
    rm -f "$tmp"
  fi
fi

log "done (${count} file(s))"
exit 0
