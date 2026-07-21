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
      w="${key} empty → ~/${rel} (stale file)"
      warn "$w"
      warnings="$(jq -nc --argjson arr "$warnings" --arg w "$w" '$arr + [$w]')"
    else
      w="${key} empty → ~/${rel}"
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
# Refresh ahead/behind so tray does not keep a stale "pass ahead N" after push.
ahead_behind="unknown"
if [[ -d ${PASSWORD_STORE_DIR:-}/.git ]]; then
  ab="$(git -C "$PASSWORD_STORE_DIR" rev-list --left-right --count HEAD...origin/HEAD 2>/dev/null || true)"
  if [[ -n $ab ]]; then
    ahead_behind="$(printf 'ahead %s, behind %s' "$(printf '%s' "$ab" | cut -f1)" "$(printf '%s' "$ab" | cut -f2)")"
  fi
fi
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
  --arg ahead_behind "$ahead_behind" \
  '
    ($prev[0] // {})
    + {
        last_materialize_at: $now,
        materialized: $materialized,
        materialize_warnings: $materialize_warnings,
        updated_at: $now,
        message: $msg,
        ahead_behind: $ahead_behind
      }
  ' >"$tmp" 2>/dev/null; then
  mv "$tmp" "$STATUS_FILE"
else
  rm -f "$tmp"
fi

# Optional: KEY=value env files (e.g. ~/.config/guildforge/env).
# Map shape: { "<relpath>": { "ENV_NAME": "SECRETSPEC_KEY", ... } }
ENV_MAP_FILE="${PASS_MATERIALIZE_ENV_MAP:-}"
if [[ -n $ENV_MAP_FILE && -f $ENV_MAP_FILE ]]; then
  while IFS= read -r rel; do
    [[ -n $rel ]] || continue
    case "$rel" in
    /* | *..*)
      warn "skip unsafe env path: $rel"
      warnings="$(jq -nc --argjson arr "$warnings" --arg w "skip unsafe env path: $rel" '$arr + [$w]')"
      continue
      ;;
    esac
    out="${HOME_DIR}/${rel}"
    missing=0
    found=0
    body=""
    missing_keys=()
    while IFS= read -r env_name; do
      [[ -n $env_name ]] || continue
      key="$(jq -r --arg p "$rel" --arg e "$env_name" '.[$p][$e] // empty' "$ENV_MAP_FILE")"
      [[ -n $key ]] || continue
      val="$(secretspec get -f "$SECRETSPEC_TOML" "$key" 2>/dev/null || true)"
      if [[ -z $val ]]; then
        missing=1
        missing_keys+=("$key")
        continue
      fi
      found=1
      # Escape for shell env files: quote if needed.
      body+="${env_name}=${val}"$'\n'
    done < <(jq -r --arg p "$rel" '.[$p] | keys[]' "$ENV_MAP_FILE")
    if [[ $missing -eq 0 && -n $body ]]; then
      umask 077
      mkdir -p "$(dirname "$out")"
      printf '%s' "$body" >"$out"
      chmod 600 "$out"
      materialized="$(jq -nc --argjson arr "$materialized" --arg p "$rel" '$arr + [$p]')"
      count=$((count + 1))
      log "wrote env $out"
    elif [[ $found -eq 0 && $missing -ne 0 && ! -e $out ]]; then
      # Optional feature not bootstrapped (e.g. guildforge) — keep tray quiet.
      log "skip optional env ~/${rel} (no secrets yet)"
    elif [[ $missing -ne 0 ]]; then
      for key in "${missing_keys[@]}"; do
        w="${key} empty → ~/${rel}"
        warn "$w"
        warnings="$(jq -nc --argjson arr "$warnings" --arg w "$w" '$arr + [$w]')"
      done
      if [[ -e $out ]]; then
        w="stale env remains → ~/${rel}"
        warn "$w"
        warnings="$(jq -nc --argjson arr "$warnings" --arg w "$w" '$arr + [$w]')"
      fi
    fi
  done < <(jq -r 'keys[]' "$ENV_MAP_FILE")

  # Refresh status after env materialize.
  warn_count="$(jq -nr --argjson w "$warnings" '$w | length')"
  ahead_behind="unknown"
  if [[ -d ${PASSWORD_STORE_DIR:-}/.git ]]; then
    ab="$(git -C "$PASSWORD_STORE_DIR" rev-list --left-right --count HEAD...origin/HEAD 2>/dev/null || true)"
    if [[ -n $ab ]]; then
      ahead_behind="$(printf 'ahead %s, behind %s' "$(printf '%s' "$ab" | cut -f1)" "$(printf '%s' "$ab" | cut -f2)")"
    fi
  fi
  tmp="$(mktemp "${STATUS_FILE}.XXXXXX")"
  if jq -nc \
    --slurpfile prev "$STATUS_FILE" \
    --argjson materialized "$materialized" \
    --argjson materialize_warnings "$warnings" \
    --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg msg "materialized ${count} file(s); ${warn_count} warning(s)" \
    --arg ahead_behind "$ahead_behind" \
    '
      ($prev[0] // {})
      + {
          last_materialize_at: $now,
          materialized: $materialized,
          materialize_warnings: $materialize_warnings,
          updated_at: $now,
          message: $msg,
          ahead_behind: $ahead_behind
        }
    ' >"$tmp" 2>/dev/null; then
    mv "$tmp" "$STATUS_FILE"
  else
    rm -f "$tmp"
  fi
fi

log "done (${count} file(s), ${warn_count} warning(s))"

# Single sentinel touches for systemd.path units (avoid PathModified storms on
# every .psk write). Ensure scripts below still run directly for sync hooks.
wifi_dir="${HOME_DIR}/.config/dendritic/wifi"
eduroam_dir="${wifi_dir}/eduroam"
if compgen -G "${wifi_dir}/*.psk" >/dev/null 2>&1; then
  mkdir -p "$wifi_dir"
  : >"${wifi_dir}/.ready"
fi
if [[ -e ${eduroam_dir}/password ]]; then
  mkdir -p "$eduroam_dir"
  : >"${eduroam_dir}/.ready"
fi

# Optional: apply Wi-Fi profiles after PSK materialize (dendritic.wifi).
if command -v dendritic-wifi-ensure >/dev/null 2>&1; then
  dendritic-wifi-ensure || warn "dendritic-wifi-ensure failed"
fi
# EWU eduroam (dendritic.eduroam) — Keychain / iwd after identity+CA materialize.
if command -v dendritic-eduroam-ensure >/dev/null 2>&1; then
  dendritic-eduroam-ensure || warn "dendritic-eduroam-ensure failed"
fi
# WireGuard overlay (dendritic.wireguard) — rewrite conf after key/endpoint sync.
if command -v dendritic-wg-ensure >/dev/null 2>&1; then
  WG_SUDO_INTERACTIVE=0 dendritic-wg-ensure || warn "dendritic-wg-ensure failed"
fi

exit 0
