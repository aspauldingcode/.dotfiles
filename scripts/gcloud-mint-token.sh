#!/usr/bin/env bash
# Mint a Google Cloud access token from pass-backed OAuth credentials.
#
# Fully automated after one-time bootstrap (`pass-gcloud-bootstrap`):
#   refresh_token (pass) → access_token (cache + stdout)
# When refresh fails and stdin is a TTY (or --device), re-runs localhost OAuth
# and writes a new refresh_token back to pass.
#
# Pass paths (Alex-only; not CI dual-encrypt):
#   secretspec/shared/default/GCLOUD_CLIENT_ID       # optional — defaults to gcloud SDK client
#   secretspec/shared/default/GCLOUD_CLIENT_SECRET   # optional — defaults to gcloud SDK secret
#   secretspec/shared/default/GCLOUD_REFRESH_TOKEN
#   secretspec/shared/default/GCLOUD_ACCOUNT         # email (set by bootstrap)
#
# Usage:
#   gcloud-mint-token.sh              # print access token to stdout
#   gcloud-mint-token.sh --refresh    # force refresh even if cache valid
#   gcloud-mint-token.sh --device     # force localhost OAuth re-auth
#   gcloud-mint-token.sh --status     # show cache / pass state (no secrets)
#   gcloud-mint-token.sh --adc        # print authorized_user ADC JSON to stdout
set -euo pipefail

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CACHE_DIR="${GCLOUD_CACHE_DIR:-$HOME/.cache/dendritic}"
CACHE_FILE="${CACHE_DIR}/gcloud-token.json"
LOCK_DIR="${CACHE_DIR}/gcloud-mint.lock"
CLIENT_ID_PATH="secretspec/shared/default/GCLOUD_CLIENT_ID"
CLIENT_SECRET_PATH="secretspec/shared/default/GCLOUD_CLIENT_SECRET"
REFRESH_PATH="secretspec/shared/default/GCLOUD_REFRESH_TOKEN"
ACCOUNT_PATH="secretspec/shared/default/GCLOUD_ACCOUNT"
# Public OAuth client shipped with Google Cloud SDK (same as `gcloud auth login`).
# Secret from googlecloudsdk.core.config.CLOUDSDK_CLIENT_NOTSOSECRET — not a private secret.
DEFAULT_CLIENT_ID="32555940559.apps.googleusercontent.com"
DEFAULT_CLIENT_SECRET="ZmssLNjJy2998hD4CTg2ejr2"
OAUTH_SERVER_PY="${OAUTH_SERVER_PY:-$DOTFILES_ROOT/scripts/gcloud-oauth-server.py}"
FORCE_REFRESH=false
FORCE_DEVICE=false
DO_STATUS=false
DO_ADC=false
SKEW_SECS=300

export PASSWORD_STORE_DIR

die() {
  echo "gcloud-mint: error: $*" >&2
  exit 1
}
log() { echo "gcloud-mint: $*" >&2; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing $1"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
  --refresh) FORCE_REFRESH=true ;;
  --device) FORCE_DEVICE=true ;;
  --status) DO_STATUS=true ;;
  --adc) DO_ADC=true ;;
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
    git -C "$PASSWORD_STORE_DIR" -c user.useConfigOnly=true commit -m "$msg" >/dev/null 2>&1 ||
      git -C "$PASSWORD_STORE_DIR" -c user.name="pass-store-sync" \
        -c user.email="pass-store-sync@localhost" commit -m "$msg" >/dev/null
    git -C "$PASSWORD_STORE_DIR" push >/dev/null 2>&1 || true
  fi
}

client_id() {
  local v
  v="$(pass_get "$CLIENT_ID_PATH")"
  if [[ -n $v ]]; then
    printf '%s' "$v"
  else
    printf '%s' "$DEFAULT_CLIENT_ID"
  fi
}

client_secret() {
  local v
  v="$(pass_get "$CLIENT_SECRET_PATH")"
  if [[ -n $v ]]; then
    printf '%s' "$v"
  else
    printf '%s' "$DEFAULT_CLIENT_SECRET"
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
  python3 - "$CACHE_FILE" "$SKEW_SECS" <<'PY'
import json, sys, time
path, skew = sys.argv[1], int(sys.argv[2])
try:
    d = json.load(open(path))
except Exception:
    raise SystemExit(1)
tok = d.get("access_token") or ""
exp = int(d.get("expires_at") or 0)
if not tok or time.time() + skew >= exp:
    raise SystemExit(1)
print(tok)
PY
}

write_cache() {
  local access="$1" expires_in="$2"
  mkdir -p "$CACHE_DIR"
  umask 077
  python3 - "$CACHE_FILE" "$access" "$expires_in" <<'PY'
import json, sys, time
path, access, exp_in = sys.argv[1], sys.argv[2], int(sys.argv[3] or 3600)
json.dump(
    {
        "access_token": access,
        "expires_at": int(time.time()) + max(exp_in - 0, 60),
        "token_type": "bearer",
    },
    open(path, "w"),
)
PY
}

print_adc() {
  local cid csec refresh
  cid="$(client_id)"
  csec="$(client_secret)"
  refresh="$(pass_get "$REFRESH_PATH")"
  [[ -n $refresh ]] || die "missing $REFRESH_PATH — run: nix run .#pass-gcloud-bootstrap"
  python3 - "$cid" "$csec" "$refresh" <<'PY'
import json, sys
cid, csec, refresh = sys.argv[1], sys.argv[2], sys.argv[3]
json.dump(
    {
        "type": "authorized_user",
        "client_id": cid,
        "client_secret": csec,
        "refresh_token": refresh,
        "universe_domain": "googleapis.com",
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
    --data "$body" \
    "https://oauth2.googleapis.com/token"
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
expires = str(d.get("expires_in") or 3600)
if not access:
    print("ERR\tmissing access_token", file=sys.stderr)
    raise SystemExit(2)
print(f"ACCESS\t{access}")
print(f"REFRESH\t{refresh}")
print(f"EXPIRES\t{expires}")
'
}

apply_token_response() {
  local json="$1" access="" refresh="" expires="3600" kind val
  while IFS=$'\t' read -r kind val; do
    case "$kind" in
    ACCESS) access="$val" ;;
    REFRESH) refresh="$val" ;;
    EXPIRES) expires="$val" ;;
    esac
  done < <(parse_token_response "$json")

  [[ -n $access ]] || return 1
  write_cache "$access" "$expires"
  if [[ -n $refresh ]]; then
    pass_put "$REFRESH_PATH" "$refresh"
    pass_commit "rotate: GCLOUD_REFRESH_TOKEN"
    log "updated $REFRESH_PATH in pass"
  fi
  printf '%s\n' "$access"
}

refresh_access() {
  local cid csec refresh body json
  cid="$(client_id)"
  csec="$(client_secret)"
  refresh="$(pass_get "$REFRESH_PATH")"
  [[ -n $refresh ]] || die "missing $REFRESH_PATH — run: nix run .#pass-gcloud-bootstrap"

  body="client_id=${cid}&client_secret=${csec}&grant_type=refresh_token&refresh_token=${refresh}"
  if ! json="$(oauth_json "$body")"; then
    log "refresh HTTP request failed"
    return 1
  fi
  if ! apply_token_response "$json"; then
    log "refresh response rejected or unparseable"
    return 1
  fi
}

device_flow() {
  local cid csec json access refresh expires email
  need python3
  [[ -f $OAUTH_SERVER_PY ]] || die "missing oauth server: $OAUTH_SERVER_PY"
  cid="$(client_id)"
  csec="$(client_secret)"
  log "Starting localhost OAuth (browser once)…"
  json="$(
    GCLOUD_CLIENT_ID="$cid" GCLOUD_CLIENT_SECRET="$csec" \
      python3 "$OAUTH_SERVER_PY"
  )" || die "OAuth failed"

  eval "$(printf '%s\n' "$json" | python3 -c '
import json,sys,shlex
d=json.load(sys.stdin)
for k,out in (("access_token","ACCESS"),("refresh_token","REFRESH"),
              ("expires_in","EXPIRES"),("email","EMAIL"),
              ("client_id","CID"),("client_secret","CSEC")):
    if d.get(k) is not None:
        print(f"{out}={shlex.quote(str(d[k]))}")
')"

  access="${ACCESS:-}"
  refresh="${REFRESH:-}"
  expires="${EXPIRES:-3600}"
  email="${EMAIL:-}"
  [[ -n $access && -n $refresh ]] || die "OAuth response incomplete"

  # Persist client if not already customized (so ADC rebuild is deterministic).
  if [[ -z $(pass_get "$CLIENT_ID_PATH") ]]; then
    pass_put "$CLIENT_ID_PATH" "${CID:-$cid}"
  fi
  if [[ -z $(pass_get "$CLIENT_SECRET_PATH") ]]; then
    pass_put "$CLIENT_SECRET_PATH" "${CSEC:-$csec}"
  fi
  pass_put "$REFRESH_PATH" "$refresh"
  if [[ -n $email ]]; then
    pass_put "$ACCOUNT_PATH" "$email"
  fi
  pass_commit "rotate: GCLOUD_REFRESH_TOKEN (OAuth bootstrap)"
  write_cache "$access" "$expires"
  log "OAuth complete${email:+ for $email}"
  printf '%s\n' "$access"
}

status() {
  local has_refresh has_account cache_left account
  has_refresh=false
  has_account=false
  [[ -n $(pass_get "$REFRESH_PATH") ]] && has_refresh=true
  account="$(pass_get "$ACCOUNT_PATH")"
  [[ -n $account ]] && has_account=true
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
  echo "gcloud (pass-backed OAuth)"
  echo "  refresh_token in pass: $has_refresh"
  echo "  account in pass: $has_account${account:+ ($account)}"
  echo "  access cache: $cache_left"
  echo "  client_id: $(client_id | sed 's/\(.\{12\}\).*/\1…/')"
  echo "  paths: $REFRESH_PATH / $ACCOUNT_PATH"
}

if $DO_STATUS; then
  status
  exit 0
fi

if $DO_ADC; then
  print_adc
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

log "refresh failed; trying localhost OAuth"
if [[ -t 0 ]] || [[ -t 2 ]]; then
  device_flow
else
  die "refresh failed and no TTY — run: pass-gcloud-bootstrap or gcloud-mint-token --device"
fi
