#!/usr/bin/env bash
# Mint a Vercel CLI access token from pass-backed OAuth credentials.
#
# Fully automated after one-time bootstrap (`pass-vercel-bootstrap`):
#   refresh_token (pass) → access_token (cache + stdout) + auth.json rewrite
# When refresh fails and stdin is a TTY (or --device), re-runs OAuth device
# flow and writes a new refresh_token back to pass.
#
# Pass paths (Alex-only; not CI dual-encrypt):
#   secretspec/shared/default/VERCEL_REFRESH_TOKEN
#   secretspec/shared/default/VERCEL_TOKEN          # static PAT fallback (not used here)
#   secretspec/shared/default/VERCEL_TEAM_ID        # optional
#
# Usage:
#   vercel-mint-token.sh              # print access token to stdout
#   vercel-mint-token.sh --refresh    # force refresh even if cache valid
#   vercel-mint-token.sh --device     # force OAuth device re-auth
#   vercel-mint-token.sh --status     # show cache / pass state (no secrets)
#   vercel-mint-token.sh --auth-json  # print auth.json body to stdout
set -euo pipefail

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CACHE_DIR="${VERCEL_CACHE_DIR:-$HOME/.cache/dendritic}"
CACHE_FILE="${CACHE_DIR}/vercel-token.json"
LOCK_DIR="${CACHE_DIR}/vercel-mint.lock"
REFRESH_PATH="secretspec/shared/default/VERCEL_REFRESH_TOKEN"
TEAM_PATH="secretspec/shared/default/VERCEL_TEAM_ID"
# Public OAuth client shipped with Vercel CLI (packages/cli oauth.ts).
DEFAULT_CLIENT_ID="cl_HYyOPBNtFMfHhaUn9L4QPfTZz6TP47bp"
DEVICE_ENDPOINT="https://api.vercel.com/login/oauth/device-authorization"
TOKEN_ENDPOINT="https://api.vercel.com/login/oauth/token"
FORCE_REFRESH=false
FORCE_DEVICE=false
DO_STATUS=false
DO_AUTH_JSON=false
SKEW_SECS=300

export PASSWORD_STORE_DIR

die() {
  echo "vercel-mint: error: $*" >&2
  exit 1
}
log() { echo "vercel-mint: $*" >&2; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing $1"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
  --refresh) FORCE_REFRESH=true ;;
  --device) FORCE_DEVICE=true ;;
  --status) DO_STATUS=true ;;
  --auth-json) DO_AUTH_JSON=true ;;
  -h | --help)
    sed -n '2,22p' "$0" | sed 's/^# //; s/^#//'
    exit 0
    ;;
  *) die "unknown arg: $1" ;;
  esac
  shift
done

need pass
need curl
need python3
need git

pass_get() {
  pass show "$1" 2>/dev/null | head -n1 | tr -d '[:space:]' || true
}

pass_put() {
  local path="$1" value="$2"
  printf '%s\n' "$value" | pass insert -e -f "$path" >/dev/null
}

pass_commit() {
  local msg="$1"
  git -C "$PASSWORD_STORE_DIR" add -A
  if git -C "$PASSWORD_STORE_DIR" status --porcelain | grep -q .; then
    # Prefer explicit identity: hosts without git user.* fail useConfigOnly and
    # can leave rotates uncommitted (breaks multi-host refresh sync).
    git -C "$PASSWORD_STORE_DIR" -c user.name="pass-store-sync" \
      -c user.email="pass-store-sync@localhost" commit -m "$msg" >/dev/null 2>&1 ||
      git -C "$PASSWORD_STORE_DIR" -c user.useConfigOnly=true commit -m "$msg" >/dev/null 2>&1 || true
    git -C "$PASSWORD_STORE_DIR" push >/dev/null 2>&1 || true
  fi
}

client_id() {
  printf '%s' "${VERCEL_CLIENT_ID:-$DEFAULT_CLIENT_ID}"
}

auth_json_path() {
  if [[ -n ${VERCEL_AUTH_JSON:-} ]]; then
    printf '%s' "$VERCEL_AUTH_JSON"
  elif [[ "$(uname -s)" == Darwin ]]; then
    printf '%s' "$HOME/Library/Application Support/com.vercel.cli/auth.json"
  else
    printf '%s' "${XDG_DATA_HOME:-$HOME/.local/share}/com.vercel.cli/auth.json"
  fi
}

with_lock() {
  mkdir -p "$CACHE_DIR"
  local i=0
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    i=$((i + 1))
    [[ $i -lt 100 ]] || die "lock busy at $LOCK_DIR"
    sleep 0.1
  done
  trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT
}

cache_valid() {
  [[ -f $CACHE_FILE ]] || return 1
  # Drop local access cache when pass refresh_token moved (peer host rotated).
  # Serving a pre-rotation access token races with Vercel refresh-token reuse.
  local pass_refresh cache_refresh
  pass_refresh="$(pass_get "$REFRESH_PATH")"
  cache_refresh="$(
    python3 - "$CACHE_FILE" <<'PY' 2>/dev/null || true
import json, sys
try:
    print(json.load(open(sys.argv[1])).get("refresh_token") or "")
except Exception:
    pass
PY
  )"
  if [[ -n $pass_refresh && -n $cache_refresh && $pass_refresh != "$cache_refresh" ]]; then
    rm -f "$CACHE_FILE"
    return 1
  fi
  python3 - "$CACHE_FILE" "$SKEW_SECS" <<'PY'
import json, sys, time
path, skew = sys.argv[1], int(sys.argv[2])
try:
    d = json.load(open(path))
except Exception:
    raise SystemExit(1)
tok = d.get("access_token") or d.get("token") or ""
exp = int(d.get("expires_at") or 0)
if not tok or time.time() + skew >= exp:
    raise SystemExit(1)
print(tok)
PY
}

write_cache() {
  local access="$1" expires_in="$2" refresh="${3:-}"
  mkdir -p "$CACHE_DIR"
  umask 077
  # Always pin the refresh_token we minted with so peers can detect drift.
  if [[ -z $refresh ]]; then
    refresh="$(pass_get "$REFRESH_PATH")"
  fi
  python3 - "$CACHE_FILE" "$access" "$expires_in" "$refresh" <<'PY'
import json, sys, time
path, access, exp_in, refresh = sys.argv[1], sys.argv[2], int(sys.argv[3] or 28800), sys.argv[4]
payload = {
    "access_token": access,
    "token": access,
    "expires_at": int(time.time()) + max(exp_in - 0, 60),
    "token_type": "bearer",
}
if refresh:
    payload["refresh_token"] = refresh
json.dump(payload, open(path, "w"))
PY
}

print_auth_json() {
  local access refresh expires_at
  refresh="$(pass_get "$REFRESH_PATH")"
  [[ -n $refresh ]] || die "missing $REFRESH_PATH — run: nix run .#pass-vercel-bootstrap"
  access="$(cache_valid 2>/dev/null || true)"
  if [[ -z $access ]]; then
    access="$(refresh_access)" || die "could not mint access token for auth.json"
  fi
  # Prefer refreshed refresh_token from pass after apply_token_response.
  refresh="$(pass_get "$REFRESH_PATH")"
  expires_at="$(
    python3 - "$CACHE_FILE" <<'PY'
import json,sys,time
try:
  d=json.load(open(sys.argv[1]))
  print(int(d.get("expires_at") or (time.time()+28800)))
except Exception:
  print(int(time.time())+28800)
PY
  )"
  python3 - "$access" "$refresh" "$expires_at" <<'PY'
import json, sys
access, refresh, exp = sys.argv[1], sys.argv[2], int(sys.argv[3])
json.dump(
    {
        "token": access,
        "expiresAt": exp,
        "refreshToken": refresh,
    },
    sys.stdout,
)
print()
PY
}

oauth_json() {
  local body="$1"
  curl -fsS -X POST \
    -H "Accept: application/json" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "User-Agent: dendritic-vercel-mint" \
    --data "$body" \
    "$TOKEN_ENDPOINT"
}

parse_token_response() {
  local json="$1"
  printf '%s\n' "$json" | python3 -c '
import json, sys
d = json.load(sys.stdin)
err = d.get("error")
if err:
    desc = d.get("error_description") or err
    print(f"ERR\t{desc}", file=sys.stderr)
    raise SystemExit(2)
access = d.get("access_token") or ""
refresh = d.get("refresh_token") or ""
expires = str(d.get("expires_in") or 28800)
if not access:
    print("ERR\tmissing access_token", file=sys.stderr)
    raise SystemExit(2)
print(f"ACCESS\t{access}")
print(f"REFRESH\t{refresh}")
print(f"EXPIRES\t{expires}")
'
}

apply_token_response() {
  local json="$1" access="" refresh="" expires="28800" kind val
  while IFS=$'\t' read -r kind val; do
    case "$kind" in
    ACCESS) access="$val" ;;
    REFRESH) refresh="$val" ;;
    EXPIRES) expires="$val" ;;
    esac
  done < <(parse_token_response "$json")

  [[ -n $access ]] || return 1
  write_cache "$access" "$expires" "$refresh"
  if [[ -n $refresh ]]; then
    pass_put "$REFRESH_PATH" "$refresh"
    pass_commit "rotate: VERCEL_REFRESH_TOKEN"
    log "updated $REFRESH_PATH in pass"
  fi
  printf '%s\n' "$access"
}

refresh_access() {
  local cid refresh body json
  cid="$(client_id)"
  refresh="$(pass_get "$REFRESH_PATH")"
  [[ -n $refresh ]] || die "missing $REFRESH_PATH — run: nix run .#pass-vercel-bootstrap"

  body="client_id=${cid}&grant_type=refresh_token&refresh_token=${refresh}"
  if ! json="$(oauth_json "$body")"; then
    log "refresh HTTP request failed"
    return 1
  fi
  if ! apply_token_response "$json"; then
    log "refresh response rejected or unparseable"
    return 1
  fi
}

open_url() {
  local url="$1"
  if command -v open >/dev/null 2>&1; then
    open "$url" >/dev/null 2>&1 || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" >/dev/null 2>&1 || true
  fi
}

device_flow() {
  local cid json device_code user_code interval verification expires_at access
  cid="$(client_id)"
  log "Starting Vercel OAuth device flow (browser once)…"
  json="$(
    curl -fsS -X POST \
      -H "Accept: application/json" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -H "User-Agent: dendritic-vercel-mint" \
      --data "client_id=${cid}&scope=openid%20offline_access" \
      "$DEVICE_ENDPOINT"
  )" || die "device authorization request failed"

  eval "$(printf '%s\n' "$json" | python3 -c '
import json,sys,shlex,time
d=json.load(sys.stdin)
for k,out in (
    ("device_code","DEVICE_CODE"),
    ("user_code","USER_CODE"),
    ("verification_uri_complete","VERIFY_URL"),
    ("verification_uri","VERIFY_BASE"),
    ("interval","INTERVAL"),
    ("expires_in","EXPIRES_IN"),
):
    if d.get(k) is not None:
        print(f"{out}={shlex.quote(str(d[k]))}")
')"

  device_code="${DEVICE_CODE:-}"
  user_code="${USER_CODE:-}"
  interval="${INTERVAL:-5}"
  verification="${VERIFY_URL:-${VERIFY_BASE:-}}"
  [[ -n $device_code && -n $user_code && -n $verification ]] || die "device authorization response incomplete"

  log "Authorize in browser: $verification"
  log "User code: $user_code"
  open_url "$verification"

  expires_at="$(
    python3 -c "import time; print(int(time.time()) + int('${EXPIRES_IN:-900}'))"
  )"
  while true; do
    if [[ $(python3 -c "import time; print(int(time.time()))") -ge $expires_at ]]; then
      die "device code expired — re-run pass-vercel-bootstrap"
    fi
    sleep "$interval"
    json="$(
      curl -sS -X POST \
        -H "Accept: application/json" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -H "User-Agent: dendritic-vercel-mint" \
        --data "client_id=${cid}&grant_type=urn:ietf:params:oauth:grant-type:device_code&device_code=${device_code}" \
        "$TOKEN_ENDPOINT"
    )" || true
    poll_rc=0
    printf '%s' "$json" | python3 -c '
import json,sys
d=json.load(sys.stdin)
err=d.get("error")
if err in ("authorization_pending", "slow_down"):
    raise SystemExit(3 if err == "authorization_pending" else 4)
if err:
    print(err + (": " + (d.get("error_description") or "")), file=sys.stderr)
    raise SystemExit(2)
if not d.get("access_token"):
    raise SystemExit(2)
' || poll_rc=$?
    if [[ $poll_rc -eq 3 ]]; then
      continue
    fi
    if [[ $poll_rc -eq 4 ]]; then
      interval=$((interval + 5))
      continue
    fi
    if [[ $poll_rc -ne 0 ]]; then
      die "device token poll failed: $(printf '%s' "$json" | head -c 200)"
    fi

    access="$(apply_token_response "$json")" || die "device token response unparseable"
    log "OAuth device flow complete"
    printf '%s\n' "$access"
    return 0
  done
}

write_auth_json_file() {
  local path dir
  path="$(auth_json_path)"
  dir="$(dirname "$path")"
  mkdir -p "$dir"
  umask 077
  print_auth_json >"$path"
  chmod 0600 "$path"
  log "wrote auth.json: $path"
}

status() {
  local has_refresh has_team cache_left team path
  has_refresh=false
  has_team=false
  [[ -n $(pass_get "$REFRESH_PATH") ]] && has_refresh=true
  team="$(pass_get "$TEAM_PATH")"
  [[ -n $team ]] && has_team=true
  path="$(auth_json_path)"
  cache_left="$(
    python3 - "$CACHE_FILE" <<'PY' 2>/dev/null || echo none
import json,sys,time
p=sys.argv[1]
try:
  d=json.load(open(p))
  left=int(d.get("expires_at",0))-int(time.time())
  print(f"{left}s" if left>0 else "expired")
except Exception:
  print("none")
PY
  )"
  echo "vercel (pass-backed OAuth)"
  echo "  refresh_token in pass: $has_refresh"
  echo "  team_id in pass: $has_team${team:+ ($team)}"
  echo "  access cache: $cache_left"
  echo "  auth.json: $path"
  echo "  client_id: $(client_id | sed 's/\(.\{12\}\).*/\1…/')"
  echo "  paths: $REFRESH_PATH / $TEAM_PATH"
}

if $DO_STATUS; then
  status
  exit 0
fi

if $DO_AUTH_JSON; then
  with_lock
  print_auth_json
  exit 0
fi

with_lock

if ! $FORCE_REFRESH && ! $FORCE_DEVICE; then
  if tok="$(cache_valid)"; then
    printf '%s\n' "$tok"
    exit 0
  fi
fi

if $FORCE_DEVICE; then
  device_flow
  exit 0
fi

if refresh_access; then
  exit 0
fi

log "refresh failed; trying OAuth device flow"
if [[ -t 0 ]] || [[ -t 2 ]]; then
  device_flow
else
  die "refresh failed and no TTY — run: pass-vercel-bootstrap or vercel-mint-token --device"
fi
