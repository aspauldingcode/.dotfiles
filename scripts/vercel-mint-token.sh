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
#   vercel-mint-token.sh --write-auth # mint once + atomically write auth.json; print token
set -euo pipefail

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CACHE_DIR="${VERCEL_CACHE_DIR:-$HOME/.cache/dendritic}"
CACHE_FILE="${CACHE_DIR}/vercel-token.json"
LOCK_DIR="${CACHE_DIR}/vercel-mint.lock"
LOCK_STALE_SECS="${VERCEL_MINT_LOCK_STALE_SECS:-120}"
CURL_CONNECT_SECS="${VERCEL_MINT_CURL_CONNECT:-10}"
CURL_MAX_SECS="${VERCEL_MINT_CURL_MAX:-30}"
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
DO_WRITE_AUTH=false
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
  --write-auth) DO_WRITE_AUTH=true ;;
  -h | --help)
    sed -n '2,23p' "$0" | sed 's/^# //; s/^#//'
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
  # Bound `pass`/`gpg` — pinentry or a stuck agent used to hang every `vercel`
  # invoke forever (especially under Cursor/IDE with no TTY).
  if command -v timeout >/dev/null 2>&1; then
    timeout 15 pass show "$1" 2>/dev/null | head -n1 | tr -d '[:space:]' || true
  else
    pass show "$1" 2>/dev/null | head -n1 | tr -d '[:space:]' || true
  fi
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

lock_mtime() {
  # Portable mtime (Darwin stat -f, GNU stat -c).
  stat -f %m "$LOCK_DIR" 2>/dev/null || stat -c %Y "$LOCK_DIR" 2>/dev/null || echo 0
}

reclaim_stale_lock() {
  [[ -d $LOCK_DIR ]] || return 1
  local now age pid
  now="$(date +%s)"
  age=$((now - $(lock_mtime)))
  if [[ $age -gt $LOCK_STALE_SECS ]]; then
    pid="$(cat "$LOCK_DIR/pid" 2>/dev/null || true)"
    log "removing stale mint lock (${age}s > ${LOCK_STALE_SECS}s)${pid:+ pid=$pid} at $LOCK_DIR"
    rm -rf "$LOCK_DIR"
    return 0
  fi
  return 1
}

with_lock() {
  mkdir -p "$CACHE_DIR"
  local i=0
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    reclaim_stale_lock || true
    if mkdir "$LOCK_DIR" 2>/dev/null; then
      break
    fi
    i=$((i + 1))
    # ~15s of waits + stale reclaim; hung CLIs used to leave this forever.
    [[ $i -lt 150 ]] || die "lock busy at $LOCK_DIR (another mint <${LOCK_STALE_SECS}s old)"
    sleep 0.1
  done
  printf '%s\n' "$$" >"$LOCK_DIR/pid" 2>/dev/null || true
  trap 'rm -rf "$LOCK_DIR" 2>/dev/null || true' EXIT INT TERM HUP
}

refresh_gpg_path() {
  printf '%s/%s.gpg' "$PASSWORD_STORE_DIR" "$REFRESH_PATH"
}

refresh_gpg_stamp() {
  # mtime + size — detects peer pass-store sync without decrypting (no pinentry).
  local gpg
  gpg="$(refresh_gpg_path)"
  [[ -f $gpg ]] || {
    echo ""
    return 0
  }
  python3 - "$gpg" <<'PY'
import os, sys
st = os.stat(sys.argv[1])
print(f"{int(st.st_mtime)}:{st.st_size}")
PY
}

cache_valid() {
  [[ -f $CACHE_FILE ]] || return 1
  # Drop local access cache when pass refresh .gpg changed (peer host rotated).
  # Do NOT decrypt pass on the hot path — that hung every `vercel` invoke on
  # gpg/pinentry (esp. IDE/agent with no TTY).
  local stamp cache_stamp
  stamp="$(refresh_gpg_stamp)"
  cache_stamp="$(
    python3 - "$CACHE_FILE" <<'PY' 2>/dev/null || true
import json, sys
try:
    print(json.load(open(sys.argv[1])).get("refresh_gpg_stamp") or "")
except Exception:
    pass
PY
  )"
  if [[ -n $stamp && -n $cache_stamp && $stamp != "$cache_stamp" ]]; then
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
  local access="$1" expires_in="$2" refresh="${3:-}" stamp
  mkdir -p "$CACHE_DIR"
  umask 077
  # Pin refresh_token + .gpg stamp so peers can detect drift without decrypt.
  if [[ -z $refresh ]]; then
    refresh="$(pass_get "$REFRESH_PATH")"
  fi
  stamp="$(refresh_gpg_stamp)"
  python3 - "$CACHE_FILE" "$access" "$expires_in" "$refresh" "$stamp" <<'PY'
import json, sys, time
path, access, exp_in, refresh, stamp = (
    sys.argv[1],
    sys.argv[2],
    int(sys.argv[3] or 28800),
    sys.argv[4],
    sys.argv[5],
)
payload = {
    "access_token": access,
    "token": access,
    "expires_at": int(time.time()) + max(exp_in - 0, 60),
    "token_type": "bearer",
}
if refresh:
    payload["refresh_token"] = refresh
if stamp:
    payload["refresh_gpg_stamp"] = stamp
json.dump(payload, open(path, "w"))
PY
}

cache_refresh_token() {
  python3 - "$CACHE_FILE" <<'PY' 2>/dev/null || true
import json, sys
try:
    print(json.load(open(sys.argv[1])).get("refresh_token") or "")
except Exception:
    pass
PY
}

print_auth_json() {
  local access refresh expires_at
  # Hot path: reuse cache refresh_token — decrypt pass only on miss/rotate.
  refresh="$(cache_refresh_token)"
  if [[ -z $refresh ]]; then
    refresh="$(pass_get "$REFRESH_PATH")"
  fi
  [[ -n $refresh ]] || die "missing $REFRESH_PATH — run: nix run .#pass-vercel-bootstrap"
  access="$(cache_valid 2>/dev/null || true)"
  if [[ -z $access ]]; then
    access="$(refresh_access)" || die "could not mint access token for auth.json"
    refresh="$(cache_refresh_token)"
    [[ -n $refresh ]] || refresh="$(pass_get "$REFRESH_PATH")"
  fi
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

curl_oauth() {
  # Always bound network waits — macOS has no `timeout(1)` by default, and a
  # hung mint blocks every `vercel` invoke (wrapper held the lock).
  curl -sS -X POST \
    --connect-timeout "$CURL_CONNECT_SECS" \
    --max-time "$CURL_MAX_SECS" \
    -H "Accept: application/json" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "User-Agent: dendritic-vercel-mint" \
    "$@"
}

oauth_json() {
  local body="$1"
  curl_oauth --fail --data "$body" "$TOKEN_ENDPOINT"
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
  # Write pass first so refresh_gpg_stamp matches the post-rotate .gpg mtime.
  if [[ -n $refresh ]]; then
    pass_put "$REFRESH_PATH" "$refresh"
    pass_commit "rotate: VERCEL_REFRESH_TOKEN"
    log "updated $REFRESH_PATH in pass"
  fi
  write_cache "$access" "$expires" "$refresh"
  printf '%s\n' "$access"
}

refresh_access() {
  local cid refresh body json http_body http_code
  cid="$(client_id)"
  refresh="$(pass_get "$REFRESH_PATH")"
  [[ -n $refresh ]] || die "missing $REFRESH_PATH — run: nix run .#pass-vercel-bootstrap"

  body="client_id=${cid}&grant_type=refresh_token&refresh_token=${refresh}"
  # Capture body+status so HTTP 400 invalid_grant is visible (curl --fail alone
  # just exits 22 with an empty message when stderr is discarded by wrappers).
  http_body="$(mktemp "${TMPDIR:-/tmp}/vercel-mint.XXXXXX")"
  http_code="$(
    curl_oauth -o "$http_body" -w '%{http_code}' --data "$body" "$TOKEN_ENDPOINT" || true
  )"
  json="$(cat "$http_body" 2>/dev/null || true)"
  rm -f "$http_body"

  if [[ -z $http_code || $http_code == 000 ]]; then
    log "refresh HTTP request failed (timeout/network)"
    return 1
  fi
  if [[ $http_code -lt 200 || $http_code -ge 300 ]]; then
    log "refresh HTTP $http_code: $(printf '%s' "$json" | head -c 240)"
    # Revoked/expired refresh: drop local access cache so we don't keep serving it.
    if [[ $http_code -eq 400 || $http_code -eq 401 ]]; then
      rm -f "$CACHE_FILE"
    fi
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
    curl_oauth --fail \
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
      curl_oauth \
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
  local path dir tmp
  path="$(auth_json_path)"
  dir="$(dirname "$path")"
  mkdir -p "$dir"
  chmod 0700 "$dir" 2>/dev/null || true
  umask 077
  # Atomic replace — never truncate auth.json before mint succeeds
  # (`cmd >auth.json` was wiping the file when mint failed).
  tmp="$(mktemp "$dir/.auth.json.XXXXXX")"
  if ! print_auth_json >"$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  # Reject empty / non-JSON payloads before replacing a good file.
  if ! python3 - "$tmp" <<'PY'; then
import json, sys
d = json.load(open(sys.argv[1]))
tok = d.get("token") or d.get("access_token") or ""
if not tok:
    raise SystemExit("empty token in auth.json payload")
PY
    rm -f "$tmp"
    return 1
  fi
  chmod 0600 "$tmp"
  mv -f "$tmp" "$path"
  log "wrote auth.json: $path"
}

status() {
  local has_refresh has_team cache_left team path
  has_refresh=false
  has_team=false
  # Status must stay decrypt-free by default (gpg hang under agents).
  [[ -f $(refresh_gpg_path) ]] && has_refresh=true
  [[ -f $PASSWORD_STORE_DIR/$TEAM_PATH.gpg ]] && has_team=true
  team=""
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
  local auth_bytes lock_state stamp
  auth_bytes=0
  [[ -f $path ]] && auth_bytes="$(wc -c <"$path" | tr -d ' ')"
  lock_state=absent
  if [[ -d $LOCK_DIR ]]; then
    lock_state="held age=$(($(date +%s) - $(lock_mtime)))s"
  fi
  stamp="$(refresh_gpg_stamp)"
  echo "vercel (pass-backed OAuth)"
  echo "  refresh_token in pass: $has_refresh"
  echo "  team_id in pass: $has_team"
  echo "  access cache: $cache_left"
  echo "  auth.json: $path (${auth_bytes} bytes)"
  echo "  mint lock: $lock_state"
  echo "  refresh .gpg stamp: ${stamp:-none}"
  echo "  client_id: $(client_id | sed 's/\(.\{12\}\).*/\1…/')"
  echo "  paths: $REFRESH_PATH / $TEAM_PATH"
}

backfill_cache_stamp() {
  # Legacy caches lack refresh_gpg_stamp; pin it without decrypting pass.
  [[ -f $CACHE_FILE ]] || return 0
  local stamp
  stamp="$(refresh_gpg_stamp)"
  [[ -n $stamp ]] || return 0
  python3 - "$CACHE_FILE" "$stamp" <<'PY'
import json, sys
path, stamp = sys.argv[1], sys.argv[2]
d = json.load(open(path))
if d.get("refresh_gpg_stamp") == stamp:
    raise SystemExit(0)
d["refresh_gpg_stamp"] = stamp
json.dump(d, open(path, "w"))
PY
}

mint_access_token() {
  # Assumes with_lock already held.
  local tok=""
  if ! $FORCE_REFRESH && ! $FORCE_DEVICE; then
    if tok="$(cache_valid)"; then
      backfill_cache_stamp || true
      printf '%s\n' "$tok"
      return 0
    fi
  fi

  if $FORCE_DEVICE; then
    device_flow
    return 0
  fi

  if refresh_access; then
    return 0
  fi

  log "refresh failed; trying OAuth device flow"
  if [[ -t 0 ]] || [[ -t 2 ]]; then
    device_flow
    return 0
  fi
  die "refresh failed and no TTY — run: pass-vercel-bootstrap or vercel-mint-token --device"
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

if $DO_WRITE_AUTH; then
  with_lock
  tok="$(mint_access_token)"
  write_auth_json_file || die "failed to write auth.json"
  printf '%s\n' "$tok"
  exit 0
fi

with_lock
mint_access_token
