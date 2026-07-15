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
warnings='[]'
count=0
while IFS= read -r key; do
  [[ -n $key ]] || continue
  rel="$(jq -r --arg k "$key" '.[$k] // empty' "$MAP_FILE")"
  [[ -n $rel ]] || continue
  # Reject absolute / traversal paths.
  case "$rel" in
  /* | *..*)
    warn "skip unsafe path for $key: $rel"
    warnings="$(jq -nc --argjson arr "$warnings" --arg w "skip unsafe path: $key" '$arr + [$w]')"
    continue
    ;;
  esac
  out="${HOME_DIR}/${rel}"
  val="$(secretspec get -f "$SECRETSPEC_TOML" "$key" 2>/dev/null || true)"
  if [[ -z $val ]]; then
    if [[ -e $out ]]; then
      # Edge case: removed from pass but home file still present (stale secret).
      w="$key missing from pass; stale file remains (~/$rel)"
      warn "$w"
      warnings="$(jq -nc --argjson arr "$warnings" --arg w "$w" '$arr + [$w]')"
    else
      w="$key missing from pass; not materialized (~/$rel)"
      warn "$w"
      warnings="$(jq -nc --argjson arr "$warnings" --arg w "$w" '$arr + [$w]')"
    fi
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

# Merge materialize fields into status (best-effort; no plaintext).
# Create the status file if missing so tray can still see warnings.
now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
warn_count="$(jq -nr --argjson w "$warnings" '$w | length')"
mkdir -p "$(dirname "$STATUS_FILE")"
if [[ ! -f $STATUS_FILE ]]; then
  printf '%s\n' '{"state":"idle","direction":"none","message":"materialize only"}' >"$STATUS_FILE"
fi
tmp="$(mktemp "${STATUS_FILE}.XXXXXX")"
if jq -nc \
  --slurpfile prev "$STATUS_FILE" \
  --argjson materialized "$materialized" \
  --argjson materialize_warnings "$warnings" \
  --arg now "$now" \
  --arg msg "materialized ${count} file(s); ${warn_count} warning(s)" \
  '
    ($prev[0] // {})
    + {
        last_materialize_at: $now,
        materialized: $materialized,
        materialize_warnings: $materialize_warnings,
        updated_at: $now,
        message: $msg
      }
  ' >"$tmp" 2>/dev/null; then
  mv "$tmp" "$STATUS_FILE"
else
  rm -f "$tmp"
fi

log "done (${count} file(s), ${warn_count} warning(s))"

# Optional: apply Wi-Fi profiles after PSK materialize (dendritic.wifi).
if command -v dendritic-wifi-ensure >/dev/null 2>&1; then
  dendritic-wifi-ensure || warn "dendritic-wifi-ensure failed"
fi
# EWU eduroam (dendritic.eduroam) — Keychain / iwd after identity+CA materialize.
if command -v dendritic-eduroam-ensure >/dev/null 2>&1; then
  dendritic-eduroam-ensure || warn "dendritic-eduroam-ensure failed"
fi

exit 0
