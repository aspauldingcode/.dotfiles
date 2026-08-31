#!/usr/bin/env bash
# Push an allowlisted fleet heartbeat to private dendritic-fleet-status.
# Never collect or send IP / FQDN / SSID / geo / home paths.
set -euo pipefail

LOG_PREFIX="fleet-heartbeat"
log() { printf '%s %s: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$LOG_PREFIX" "$*"; }
warn() { log "warning: $*" >&2; }
die() {
  log "error: $*" >&2
  exit 1
}

HOST_ID="${FLEET_HOST_ID:?FLEET_HOST_ID required}"
PLATFORM="${FLEET_PLATFORM:?FLEET_PLATFORM required}"
OWNER="${FLEET_STATUS_OWNER:-aspauldingcode}"
REPO="${FLEET_STATUS_REPO:-dendritic-fleet-status}"
PATH_IN_REPO="hosts/${HOST_ID}.json"
DOTFILES_ROOT="${FLEET_DOTFILES_ROOT:-}"

case "$PLATFORM" in
darwin | nixos | linux | android) ;;
*) die "invalid FLEET_PLATFORM=$PLATFORM" ;;
esac

[[ $HOST_ID =~ ^[a-z0-9][a-z0-9-]{0,62}$ ]] || die "invalid FLEET_HOST_ID=$HOST_ID"

# Optional dedicated token (sops); else rely on existing gh auth / GH_TOKEN.
# Race: sops-nix may decrypt after RunAtLoad / timer fire — wait briefly.
if [[ -n ${FLEET_STATUS_TOKEN_FILE:-} ]]; then
  wait_sec="${FLEET_STATUS_TOKEN_WAIT_SEC:-120}"
  deadline=$((SECONDS + wait_sec))
  while [[ ! -r ${FLEET_STATUS_TOKEN_FILE} ]]; do
    if ((SECONDS >= deadline)); then
      die "sops token not readable after ${wait_sec}s: ${FLEET_STATUS_TOKEN_FILE}"
    fi
    sleep 2
  done
  token="$(tr -d '[:space:]' <"$FLEET_STATUS_TOKEN_FILE")"
  if [[ -n $token && $token != placeholder ]]; then
    export GH_TOKEN="$token"
  fi
fi

command -v gh >/dev/null 2>&1 || die "gh not in PATH"
command -v jq >/dev/null 2>&1 || die "jq not in PATH"
command -v git >/dev/null 2>&1 || die "git not in PATH"

if ! gh auth status -h github.com >/dev/null 2>&1 && [[ -z ${GH_TOKEN:-} ]]; then
  die "gh not authenticated and no GH_TOKEN / fleet file"
fi

flake_rev="unknown"
if [[ -n $DOTFILES_ROOT && -d $DOTFILES_ROOT/.git ]]; then
  flake_rev="$(git -C "$DOTFILES_ROOT" rev-parse --short=8 HEAD 2>/dev/null || true)"
fi
if [[ ! $flake_rev =~ ^[0-9a-f]{7,40}$ ]]; then
  flake_rev="$(git -C "${DOTFILES_ROOT:-.}" rev-parse --short=8 HEAD 2>/dev/null || echo 00000000)"
fi
[[ $flake_rev =~ ^[0-9a-f]{7,40}$ ]] || flake_rev="00000000"

seen_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

payload="$(jq -nc \
  --arg host "$HOST_ID" \
  --arg platform "$PLATFORM" \
  --arg flake_rev "$flake_rev" \
  --arg seen_at "$seen_at" \
  '{host:$host, platform:$platform, flake_rev:$flake_rev, seen_at:$seen_at, schema:1}')"

# Defense in depth: reject accidental IPv4 / full IPv6 before upload.
# Do not use a loose IPv6 regex — timestamps like 18:41:54 false-positive.
if printf '%s' "$payload" | grep -EIq \
  '(^|[^0-9])([0-9]{1,3}\.){3}[0-9]{1,3}([^0-9]|$)|([0-9a-fA-F]{1,4}:){5,7}[0-9a-fA-F]{1,4}'; then
  die "payload contains IP-like string; abort"
fi

# Only allowlisted keys may appear.
keys="$(printf '%s' "$payload" | jq -r 'keys[]' | sort | tr '\n' ' ')"
[[ $keys == "flake_rev host platform schema seen_at " ]] || die "unexpected keys: $keys"

tmp="$(mktemp)"
chmod 600 "$tmp"
printf '%s\n' "$payload" >"$tmp"

# Create or update via Contents API (no full clone).
api="repos/${OWNER}/${REPO}/contents/${PATH_IN_REPO}"
b64="$(base64 <"$tmp" | tr -d '\n')"
rm -f "$tmp"

max_attempts=3
attempt=1
success=false

while ((attempt <= max_attempts)); do
  log "Attempting heartbeat upload (attempt ${attempt}/${max_attempts})..."

  # Fetch latest SHA, bypassing CDN cache
  sha=""
  if meta="$(gh api -H "Cache-Control: no-cache" -H "Pragma: no-cache" "${api}?t=$(date +%s)" 2>/dev/null)"; then
    sha="$(printf '%s' "$meta" | jq -r '.sha // empty')"
  fi

  body="$(jq -nc \
    --arg msg "heartbeat: ${HOST_ID} ${seen_at}" \
    --arg content "$b64" \
    --arg sha "$sha" \
    'if $sha != "" then {message:$msg, content:$content, sha:$sha} else {message:$msg, content:$content} end')"

  put_err="$(mktemp)"
  if printf '%s' "$body" | gh api --method PUT "$api" --input - >/dev/null 2>"$put_err"; then
    success=true
    rm -f "$put_err"
    break
  fi

  # Check failure reason
  if grep -qiE 'rate limit|API rate limit|HTTP 403' "$put_err"; then
    warn "GitHub API rate-limited; skipping PUT ${PATH_IN_REPO}"
    rm -f "$put_err"
    exit 0
  fi

  # Check if conflict (HTTP 409)
  if grep -qiE 'conflict|HTTP 409|is at .* but expected' "$put_err"; then
    warn "Conflict updating ${PATH_IN_REPO} (HTTP 409). Retrying in 2s..."
    rm -f "$put_err"
    sleep 2
    attempt=$((attempt + 1))
    continue
  fi

  cat "$put_err" >&2 || true
  rm -f "$put_err"
  die "failed to PUT ${PATH_IN_REPO}"
done

if [[ $success != true ]]; then
  die "failed to PUT ${PATH_IN_REPO} after ${max_attempts} attempts"
fi

log "ok ${HOST_ID} tip=${flake_rev} seen_at=${seen_at}"
exit 0
