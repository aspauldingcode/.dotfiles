#!/usr/bin/env bash
# Mint a GitHub user access token from pass-backed GitHub App credentials.
#
# Fully automated after one-time bootstrap (`pass-github-app-bootstrap`):
#   refresh_token (pass) → access_token (cache + stdout)
# When refresh is expired/revoked and stdin is a TTY (or --device), runs device
# flow and writes new refresh_token back to pass.
#
# Pass paths (Alex-only; not CI dual-encrypt):
#   secretspec/shared/default/GH_APP_CLIENT_ID
#   secretspec/shared/default/GH_APP_CLIENT_SECRET   # optional for device-originated refresh
#   secretspec/shared/default/GH_REFRESH_TOKEN
#
# Usage:
#   github-app-mint-token.sh              # print access token to stdout
#   github-app-mint-token.sh --refresh    # force refresh even if cache valid
#   github-app-mint-token.sh --device     # force device-flow re-auth
#   github-app-mint-token.sh --status     # show cache / pass state (no secrets)
set -euo pipefail

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
CACHE_DIR="${GH_APP_CACHE_DIR:-$HOME/.cache/dendritic}"
CACHE_FILE="${CACHE_DIR}/gh-app-token.json"
LOCK_DIR="${CACHE_DIR}/gh-app-mint.lock"
CLIENT_ID_PATH="secretspec/shared/default/GH_APP_CLIENT_ID"
CLIENT_SECRET_PATH="secretspec/shared/default/GH_APP_CLIENT_SECRET"
REFRESH_PATH="secretspec/shared/default/GH_REFRESH_TOKEN"
REFRESH_GPG="${PASSWORD_STORE_DIR}/${REFRESH_PATH}.gpg"
FORCE_REFRESH=false
FORCE_DEVICE=false
DO_STATUS=false
# Skew: refresh 5 minutes before expiry
SKEW_SECS=300
# Re-probe cached access tokens against api.github.com at most this often
VERIFY_SECS="${GH_APP_VERIFY_SECS:-600}"

export PASSWORD_STORE_DIR

die() {
  echo "github-app-mint: error: $*" >&2
  exit 1
}
log() { echo "github-app-mint: $*" >&2; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing $1"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
  --refresh) FORCE_REFRESH=true ;;
  --device) FORCE_DEVICE=true ;;
  --status) DO_STATUS=true ;;
  -h | --help)
    sed -n '2,20p' "$0" | sed 's/^# //; s/^#//'
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

invalidate_cache() {
  rm -f "$CACHE_FILE"
}

# True when pass refresh ciphertext is newer than the access cache (cross-host rotate).
refresh_newer_than_cache() {
  [[ -f $CACHE_FILE && -f $REFRESH_GPG && $REFRESH_GPG -nt $CACHE_FILE ]]
}

cache_valid() {
  [[ -f $CACHE_FILE ]] || return 1
  if refresh_newer_than_cache; then
    log "refresh token in pass newer than access cache — invalidating"
    invalidate_cache
    return 1
  fi
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

# Exit 0 if cache verified_at is fresh enough to skip an API probe.
cache_verified_fresh() {
  [[ -f $CACHE_FILE ]] || return 1
  python3 - "$CACHE_FILE" "$VERIFY_SECS" <<'PY'
import json, sys, time
path, verify = sys.argv[1], int(sys.argv[2])
try:
    d = json.load(open(path))
except Exception:
    raise SystemExit(1)
verified = int(d.get("verified_at") or 0)
if verified <= 0 or time.time() - verified >= verify:
    raise SystemExit(1)
raise SystemExit(0)
PY
}

mark_verified() {
  [[ -f $CACHE_FILE ]] || return 0
  python3 - "$CACHE_FILE" <<'PY'
import json, sys, time
path = sys.argv[1]
try:
    d = json.load(open(path))
except Exception:
    raise SystemExit(0)
d["verified_at"] = int(time.time())
json.dump(d, open(path, "w"))
PY
}

# Probe cached access token; 0 = usable, 1 = dead/unreachable (caller should refresh).
probe_access_token() {
  local tok="$1" code
  code="$(
    curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 5 --max-time 10 \
      -H "Authorization: Bearer ${tok}" \
      -H "Accept: application/vnd.github+json" \
      -H "User-Agent: dendritic-github-app-mint" \
      "https://api.github.com/user" 2>/dev/null || echo 000
  )"
  case "$code" in
  2*) return 0 ;;
  *)
    log "cached access token rejected by GitHub (HTTP ${code}) — refreshing"
    return 1
    ;;
  esac
}

write_cache() {
  local access="$1" expires_in="$2"
  mkdir -p "$CACHE_DIR"
  umask 077
  python3 - "$CACHE_FILE" "$access" "$expires_in" <<'PY'
import json, sys, time
path, access, exp_in = sys.argv[1], sys.argv[2], int(sys.argv[3] or 28800)
now = int(time.time())
data = {
    "access_token": access,
    "expires_at": now + max(exp_in - 0, 60),
    "token_type": "bearer",
    "verified_at": now,
}
json.dump(data, open(path, "w"))
PY
}

oauth_json() {
  # POST form body to GitHub OAuth; print JSON body
  local body="$1"
  curl -fsS -X POST \
    -H "Accept: application/json" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data "$body" \
    "https://github.com/login/oauth/access_token"
}

parse_token_response() {
  # $1: JSON from oauth → prints ACCESS/REFRESH/EXPIRES lines (tab-separated)
  # NOTE: must not use a stdin heredoc for python — that would swallow piped JSON.
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
  # Persist refresh before access cache so REFRESH_GPG is not -nt CACHE_FILE.
  if [[ -n $refresh ]]; then
    pass_put "$REFRESH_PATH" "$refresh"
    pass_commit "rotate: GH_REFRESH_TOKEN (GitHub App)"
    log "updated $REFRESH_PATH in pass"
  fi
  write_cache "$access" "$expires"
  printf '%s\n' "$access"
}

refresh_access() {
  local client_id client_secret refresh body json
  client_id="$(pass_get "$CLIENT_ID_PATH")"
  client_secret="$(pass_get "$CLIENT_SECRET_PATH")"
  refresh="$(pass_get "$REFRESH_PATH")"
  [[ -n $client_id ]] || die "missing $CLIENT_ID_PATH — run: nix run .#pass-github-app-bootstrap"
  [[ -n $refresh ]] || die "missing $REFRESH_PATH — run: nix run .#pass-github-app-bootstrap"

  body="client_id=${client_id}&grant_type=refresh_token&refresh_token=${refresh}"
  if [[ -n $client_secret ]]; then
    body+="&client_secret=${client_secret}"
  fi

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
  local client_id client_secret json device_code user_code verify_url interval expires_in http_code
  client_id="$(pass_get "$CLIENT_ID_PATH")"
  client_secret="$(pass_get "$CLIENT_SECRET_PATH")"
  [[ -n $client_id ]] || die "missing $CLIENT_ID_PATH — run bootstrap first"

  # Prefer Device Flow when enabled; otherwise localhost OAuth (callback registered at bootstrap).
  http_code="$(
    curl -sS -o /tmp/gh-device-code.json -w '%{http_code}' -X POST \
      -H "Accept: application/json" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data "client_id=${client_id}" \
      "https://github.com/login/device/code" || true
  )"
  json="$(cat /tmp/gh-device-code.json 2>/dev/null || true)"
  rm -f /tmp/gh-device-code.json

  if [[ $http_code != 200 ]] || printf '%s' "$json" | grep -q 'device_flow_disabled'; then
    log "Device Flow unavailable (HTTP ${http_code:-?}) — using localhost OAuth"
    oauth_localhost_flow
    return
  fi

  eval "$(python3 -c '
import json,sys,shlex
d=json.load(sys.stdin)
for k in ("device_code","user_code","verification_uri","interval","expires_in"):
    if k in d: print(f"{k.upper()}={shlex.quote(str(d[k]))}")
' <<<"$json")"

  device_code="${DEVICE_CODE:-}"
  user_code="${USER_CODE:-}"
  verify_url="${VERIFICATION_URI:-https://github.com/login/device}"
  interval="${INTERVAL:-5}"
  expires_in="${EXPIRES_IN:-900}"

  [[ -n $device_code && -n $user_code ]] || die "device/code failed: $json"

  log "Authorize this device at: $verify_url"
  log "User code: $user_code"
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"Code ${user_code} — open ${verify_url}\" with title \"GitHub App device login\"" 2>/dev/null || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send "GitHub App device login" "Code ${user_code} — ${verify_url}" || true
  fi
  if command -v open >/dev/null 2>&1; then
    open "$verify_url" 2>/dev/null || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$verify_url" 2>/dev/null || true
  fi

  local waited=0 body poll
  while [[ $waited -lt $expires_in ]]; do
    sleep "$interval"
    waited=$((waited + interval))
    body="client_id=${client_id}&device_code=${device_code}&grant_type=urn:ietf:params:oauth:grant-type:device_code"
    if [[ -n $client_secret ]]; then
      body+="&client_secret=${client_secret}"
    fi
    poll="$(oauth_json "$body" 2>/dev/null || true)"
    if printf '%s' "$poll" | grep -q '"access_token"'; then
      apply_token_response "$poll"
      log "device flow complete"
      return 0
    fi
    if printf '%s' "$poll" | grep -q 'authorization_pending\|slow_down'; then
      continue
    fi
    if printf '%s' "$poll" | grep -q 'expired_token\|access_denied\|incorrect_device_code'; then
      die "device flow failed: $poll"
    fi
  done
  die "device flow timed out"
}

# Localhost OAuth using the App's registered callback from bootstrap
# (http://127.0.0.1:8741/oauth-callback). Used when Device Flow is disabled.
oauth_localhost_flow() {
  local client_id client_secret port host redirect auth_url code state json
  need python3
  client_id="$(pass_get "$CLIENT_ID_PATH")"
  client_secret="$(pass_get "$CLIENT_SECRET_PATH")"
  [[ -n $client_id && -n $client_secret ]] || die "missing App client credentials in pass"
  host="127.0.0.1"
  port="${GH_OAUTH_PORT:-8741}"
  redirect="http://${host}:${port}/oauth-callback"
  state="$(python3 -c 'import secrets; print(secrets.token_urlsafe(24))')"

  log "Starting localhost OAuth on $redirect"
  json="$(
    GH_OAUTH_CLIENT_ID="$client_id" \
      GH_OAUTH_CLIENT_SECRET="$client_secret" \
      GH_OAUTH_HOST="$host" \
      GH_OAUTH_PORT="$port" \
      GH_OAUTH_STATE="$state" \
      python3 - <<'PY'
import json, os, secrets, sys, threading, time, urllib.parse, urllib.request, webbrowser
from http.server import BaseHTTPRequestHandler, HTTPServer

HOST = os.environ["GH_OAUTH_HOST"]
PORT = int(os.environ["GH_OAUTH_PORT"])
CLIENT_ID = os.environ["GH_OAUTH_CLIENT_ID"]
CLIENT_SECRET = os.environ["GH_OAUTH_CLIENT_SECRET"]
STATE = os.environ.get("GH_OAUTH_STATE") or secrets.token_urlsafe(24)
REDIRECT = f"http://{HOST}:{PORT}/oauth-callback"
result = {"done": False, "error": None, "oauth": None}

def exchange(code: str) -> dict:
    body = urllib.parse.urlencode({
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "code": code,
        "redirect_uri": REDIRECT,
    }).encode()
    req = urllib.request.Request(
        "https://github.com/login/oauth/access_token",
        data=body,
        headers={
            "Accept": "application/json",
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "dendritic-github-app-mint",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read().decode())

class H(BaseHTTPRequestHandler):
    def log_message(self, *args):
        return
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path != "/oauth-callback":
            self.send_response(404); self.end_headers(); return
        qs = urllib.parse.parse_qs(parsed.query)
        if qs.get("error"):
            result["error"] = qs["error"][0]; result["done"] = True
            self.send_response(400); self.end_headers(); return
        if (qs.get("state") or [None])[0] != STATE:
            result["error"] = "state mismatch"; result["done"] = True
            self.send_response(400); self.end_headers(); return
        code = (qs.get("code") or [None])[0]
        if not code:
            result["error"] = "missing code"; result["done"] = True
            self.send_response(400); self.end_headers(); return
        try:
            result["oauth"] = exchange(code)
            result["done"] = True
            body = b"<html><body><h1>GitHub auth OK</h1><p>Close this tab.</p></body></html>"
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers(); self.wfile.write(body)
        except Exception as e:
            result["error"] = str(e); result["done"] = True
            self.send_response(500); self.end_headers()

httpd = HTTPServer((HOST, PORT), H)
auth = "https://github.com/login/oauth/authorize?" + urllib.parse.urlencode({
    "client_id": CLIENT_ID,
    "redirect_uri": REDIRECT,
    "state": STATE,
})
print(f"github-app-mint: opening browser for OAuth…", file=sys.stderr)
print(f"github-app-mint: {auth}", file=sys.stderr)
threading.Thread(target=httpd.serve_forever, daemon=True).start()
webbrowser.open(auth)
deadline = time.time() + 600
while time.time() < deadline and not result["done"]:
    time.sleep(0.2)
httpd.shutdown()
if result["error"] or not result["oauth"]:
    print(json.dumps({"error": result["error"] or "timeout"}), file=sys.stderr)
    raise SystemExit(1)
json.dump(result["oauth"], sys.stdout)
print()
PY
  )" || die "localhost OAuth failed"

  apply_token_response "$json"
  log "localhost OAuth complete"
}

status() {
  local has_id has_refresh cache_left
  has_id=false
  has_refresh=false
  [[ -n $(pass_get "$CLIENT_ID_PATH") ]] && has_id=true
  [[ -n $(pass_get "$REFRESH_PATH") ]] && has_refresh=true
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
  echo "GitHub App (pass-backed)"
  echo "  client_id in pass: $has_id"
  echo "  refresh_token in pass: $has_refresh"
  echo "  access cache: $cache_left"
  echo "  paths: $CLIENT_ID_PATH / $REFRESH_PATH"
}

if $DO_STATUS; then
  status
  exit 0
fi

with_lock

if ! $FORCE_REFRESH && ! $FORCE_DEVICE; then
  if tok="$(cache_valid)"; then
    if cache_verified_fresh; then
      printf '%s\n' "$tok"
      exit 0
    fi
    if probe_access_token "$tok"; then
      mark_verified
      printf '%s\n' "$tok"
      exit 0
    fi
    invalidate_cache
  fi
fi

if $FORCE_DEVICE; then
  device_flow
  exit 0
fi

if refresh_access; then
  exit 0
fi

log "refresh failed; trying device flow"
if [[ -t 0 ]] || [[ -t 2 ]]; then
  device_flow
else
  die "refresh failed and no TTY for device flow — run: pass-github-app-bootstrap or github-app-mint-token --device"
fi
