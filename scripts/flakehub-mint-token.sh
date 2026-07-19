#!/usr/bin/env bash
# Mint FlakeHub device tokens (stdout) or elevate admin auth.
#
#   flakehub-mint-token                 # create device token → print JWT
#   flakehub-mint-token --status        # status / list (no secrets)
#   flakehub-mint-token --login-pass    # login determinate-nixd from pass
#   flakehub-mint-token --elevate       # interactive admin login (UI user token)
#   flakehub-mint-token --org ORG --description DESC
#
# Device JWTs can list tokens but cannot create. Minting requires FlakeHub
# *admin user* auth (`determinate-nixd auth login token` with a UI user token),
# then we store a coarse device JWT in pass for day-to-day use.
set -euo pipefail

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
ORG="${FLAKEHUB_ORG:-aspauldingcode}"
FH_PASS_PATH="secretspec/shared/default/FLAKEHUB_TOKEN"
FH_DESC_PREFIX="${FLAKEHUB_DESC_PREFIX:-dendritic-cli-auth}"
DO_STATUS=false
DO_LOGIN_PASS=false
DO_ELEVATE=false
DESC=""
TOKEN_FILE=""

export PASSWORD_STORE_DIR

die() {
  echo "error: $*" >&2
  exit 1
}
log() { echo "$*" >&2; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing $1"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
  --status) DO_STATUS=true ;;
  --login-pass) DO_LOGIN_PASS=true ;;
  --elevate) DO_ELEVATE=true ;;
  --org)
    ORG="${2:?}"
    shift
    ;;
  --description | --desc)
    DESC="${2:?}"
    shift
    ;;
  --token-file)
    TOKEN_FILE="${2:?}"
    shift
    ;;
  -h | --help)
    sed -n '2,14p' "$0" | sed 's/^# //; s/^#//'
    exit 0
    ;;
  *) die "unknown arg: $1" ;;
  esac
  shift
done

need determinate-nixd

login_from_pass() {
  need pass
  local token tf
  token="$(pass show "$FH_PASS_PATH" 2>/dev/null | head -n1 | tr -d '[:space:]' || true)"
  [[ -n $token && $token != placeholder ]] || die "FLAKEHUB_TOKEN missing in pass ($FH_PASS_PATH)"
  tf="$(mktemp)"
  umask 077
  printf '%s\n' "$token" >"$tf"
  if determinate-nixd login token --token-file "$tf" >/dev/null 2>&1 ||
    determinate-nixd auth login token --token-file "$tf" >/dev/null 2>&1; then
    log "flakehub-mint: logged in from pass"
  else
    rm -f "$tf"
    die "flakehub-mint: login from pass failed"
  fi
  rm -f "$tf"
  determinate-nixd auth bind "$ORG" >/dev/null 2>&1 || true
}

elevate_admin() {
  if [[ -n $TOKEN_FILE ]]; then
    [[ -r $TOKEN_FILE ]] || die "unreadable --token-file $TOKEN_FILE"
    log "flakehub-mint: elevating with --token-file"
    determinate-nixd auth login token --token-file "$TOKEN_FILE"
    determinate-nixd auth bind "$ORG" >/dev/null 2>&1 || true
    return 0
  fi
  log "flakehub-mint: admin elevation required to mint device tokens"
  log "  Open: https://flakehub.com/user/settings?editview=tokens"
  log "  Create a short-lived *user* token, then paste it."
  if command -v open >/dev/null 2>&1; then
    open "https://flakehub.com/user/settings?editview=tokens" >/dev/null 2>&1 || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "https://flakehub.com/user/settings?editview=tokens" >/dev/null 2>&1 || true
  fi
  if [[ -t 0 ]]; then
    determinate-nixd auth login token
  else
    die "non-interactive: run with --token-file FILE, or: determinate-nixd auth login token"
  fi
  determinate-nixd auth bind "$ORG" >/dev/null 2>&1 || true
}

mint_device_token() {
  local host desc token err
  host="$(hostname -s 2>/dev/null || hostname || echo host)"
  desc="${DESC:-${FH_DESC_PREFIX} ${host} $(date -u +%Y-%m-%d)}"
  err="$(mktemp)"
  log "flakehub-mint: creating device token ($desc)…"
  if ! token="$(determinate-nixd auth token device create --org "$ORG" --description "$desc" 2>"$err" | tr -d '\r\n')"; then
    log "flakehub-mint: create failed:"
    sed 's/^/  /' "$err" >&2 || true
    rm -f "$err"
    return 1
  fi
  rm -f "$err"
  [[ -n $token ]] || {
    log "flakehub-mint: empty token"
    return 1
  }
  printf '%s\n' "$token"
}

if $DO_STATUS; then
  determinate-nixd status 2>/dev/null || true
  if command -v fh >/dev/null 2>&1; then
    fh status 2>/dev/null || true
  fi
  log "org: $ORG"
  log "pass: $FH_PASS_PATH"
  determinate-nixd auth token device list --org "$ORG" -n 10 2>/dev/null || true
  exit 0
fi

if $DO_LOGIN_PASS; then
  login_from_pass
  exit 0
fi

if $DO_ELEVATE; then
  elevate_admin
  exit 0
fi

# Default: mint; on 401 elevate (interactive / --token-file) and retry once.
errf="$(mktemp)"
host="$(hostname -s 2>/dev/null || hostname || echo host)"
desc="${DESC:-${FH_DESC_PREFIX} ${host} $(date -u +%Y-%m-%d)}"
if token="$(determinate-nixd auth token device create --org "$ORG" --description "$desc" 2>"$errf" | tr -d '\r\n')" && [[ -n $token ]]; then
  rm -f "$errf"
  printf '%s\n' "$token"
  exit 0
fi

if grep -qiE '401|Unauthorized|log in with `fh login`|Please log in' "$errf"; then
  log "flakehub-mint: device JWT cannot mint — elevating to admin user auth"
  rm -f "$errf"
  elevate_admin
  DESC="$desc" mint_device_token
  exit 0
fi

log "flakehub-mint: create failed:"
sed 's/^/  /' "$errf" >&2 || true
rm -f "$errf"
exit 1
