#!/usr/bin/env bash
# Deterministic GitHub App bootstrap via Manifest → pass → OAuth refresh token.
#
#   pass-github-app-bootstrap           # full manifest + OAuth (browser once)
#   pass-github-app-bootstrap --device  # re-auth only (existing client in pass)
#   pass-github-app-bootstrap --force   # recreate even if client_id exists
#
# Permissions come from home/github-app-manifest.json (versioned in the flake).
set -euo pipefail

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
MANIFEST_PATH="${MANIFEST_PATH:-$DOTFILES_ROOT/home/github-app-manifest.json}"
SERVER_PY="${SERVER_PY:-$DOTFILES_ROOT/scripts/github-app-manifest-server.py}"
CLIENT_ID_PATH="secretspec/shared/default/GH_APP_CLIENT_ID"
CLIENT_SECRET_PATH="secretspec/shared/default/GH_APP_CLIENT_SECRET"
REFRESH_PATH="secretspec/shared/default/GH_REFRESH_TOKEN"
APP_ID_PATH="secretspec/shared/default/GH_APP_ID"
APP_PEM_PATH="secretspec/shared/default/GH_APP_PRIVATE_KEY"
LISTEN_PORT="${LISTEN_PORT:-8741}"
FORCE=false
DEVICE_ONLY=false

export PASSWORD_STORE_DIR

die() {
  echo "error: $*" >&2
  exit 1
}
log() { echo "$*"; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing $1"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
  --force) FORCE=true ;;
  --device) DEVICE_ONLY=true ;;
  -h | --help)
    sed -n '2,10p' "$0" | sed 's/^# //; s/^#//'
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

pass_get() { pass show "$1" 2>/dev/null | head -n1 | tr -d '[:space:]' || true; }
pass_put() {
  printf '%s\n' "$2" | pass insert -e -f "$1" >/dev/null
  log "pass: wrote $1"
}
pass_put_multiline() {
  # PEM / multiline secrets
  local path="$1" file="$2"
  pass insert -m -f "$path" <"$file" >/dev/null
  log "pass: wrote $path"
}

pass_commit() {
  git -C "$PASSWORD_STORE_DIR" add -A
  if git -C "$PASSWORD_STORE_DIR" status --porcelain | grep -q .; then
    git -C "$PASSWORD_STORE_DIR" -c user.useConfigOnly=true commit -m "$1" >/dev/null 2>&1 ||
      git -C "$PASSWORD_STORE_DIR" -c user.name="pass-store-sync" \
        -c user.email="pass-store-sync@localhost" commit -m "$1" >/dev/null
    git -C "$PASSWORD_STORE_DIR" push >/dev/null 2>&1 || true
  fi
}

write_cache_access() {
  local access="$1" expires_in="${2:-28800}"
  local cache_dir="${HOME}/.cache/dendritic"
  mkdir -p "$cache_dir"
  umask 077
  python3 - "$cache_dir/gh-app-token.json" "$access" "$expires_in" <<'PY'
import json, sys, time
path, access, exp_in = sys.argv[1], sys.argv[2], int(sys.argv[3])
now = int(time.time())
json.dump(
    {
        "access_token": access,
        "expires_at": now + exp_in,
        "token_type": "bearer",
        "verified_at": now,
    },
    open(path, "w"),
)
PY
}

if $DEVICE_ONLY || { ! $FORCE && [[ -n $(pass_get "$CLIENT_ID_PATH") ]]; }; then
  if [[ -z $(pass_get "$CLIENT_ID_PATH") ]]; then
    die "no client_id in pass — run without --device first"
  fi
  log "Re-running user auth with existing App credentials…"
  if command -v github-app-mint-token >/dev/null 2>&1; then
    github-app-mint-token --device
  else
    die "github-app-mint-token not on PATH"
  fi
  exit 0
fi

[[ -f $MANIFEST_PATH ]] || die "missing manifest: $MANIFEST_PATH"
[[ -f $SERVER_PY ]] || die "missing server: $SERVER_PY"

log "Starting manifest handshake on http://127.0.0.1:${LISTEN_PORT}/register"
log "Browser will open — click Create on GitHub (permissions already set from manifest)."
log ""

export MANIFEST_PATH LISTEN_PORT
export LISTEN_HOST=127.0.0.1
out_json="$(mktemp)"
pem_file="$(mktemp)"
trap 'rm -f "$out_json" "$pem_file"' EXIT

if ! python3 "$SERVER_PY" >"$out_json"; then
  die "manifest/OAuth handshake failed (see above)"
fi

client_id="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["credentials"]["client_id"])' "$out_json")"
client_secret="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["credentials"]["client_secret"])' "$out_json")"
app_id="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["credentials"].get("id") or "")' "$out_json")"
refresh="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["oauth"].get("refresh_token") or "")' "$out_json")"
access="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["oauth"].get("access_token") or "")' "$out_json")"
expires_in="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["oauth"].get("expires_in") or 28800)' "$out_json")"
slug="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["credentials"].get("slug") or "")' "$out_json")"

[[ -n $client_id && -n $client_secret ]] || die "conversion missing client credentials"
[[ -n $refresh ]] || die "OAuth missing refresh_token — ensure 'Expire user authorization tokens' is enabled on the App"

pass_put "$CLIENT_ID_PATH" "$client_id"
pass_put "$CLIENT_SECRET_PATH" "$client_secret"
pass_put "$REFRESH_PATH" "$refresh"
[[ -n $app_id ]] && pass_put "$APP_ID_PATH" "$app_id"

python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["credentials"].get("pem") or "", end="")' "$out_json" >"$pem_file"
if [[ -s $pem_file ]]; then
  pass_put_multiline "$APP_PEM_PATH" "$pem_file"
fi

pass_commit "bootstrap: GitHub App dendritic-cli-auth (manifest)"

if [[ -n $access ]]; then
  write_cache_access "$access" "$expires_in"
fi

login="$(GH_TOKEN="$access" curl -fsS -H "Authorization: Bearer $access" -H "Accept: application/vnd.github+json" https://api.github.com/user | python3 -c 'import json,sys; print(json.load(sys.stdin).get("login",""))' || true)"
log ""
log "Bootstrap complete."
log "  App: ${slug:-dendritic-cli-auth} (id=${app_id:-unknown})"
log "  User: ${login:-unknown}"
log "  pass: $CLIENT_ID_PATH, $CLIENT_SECRET_PATH, $REFRESH_PATH"
log "Enable Device Flow (optional, for headless re-auth):"
log "  https://github.com/settings/apps/${slug}/advanced"
log "Check: github-app-mint-token --status && gh api user -q .login"
