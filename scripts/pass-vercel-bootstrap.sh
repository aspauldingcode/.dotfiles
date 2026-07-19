#!/usr/bin/env bash
# Bootstrap Vercel CLI auth into pass (SecretSpec) + local auth.json.
#
#   pass-vercel-bootstrap                 # OAuth device flow (browser once)
#   pass-vercel-bootstrap --device        # same (alias)
#   pass-vercel-bootstrap --force         # re-auth even if refresh_token exists
#   pass-vercel-bootstrap --from-auth-json [PATH]  # import existing CLI auth.json
#   pass-vercel-bootstrap --from-token TOKEN       # store static VERCEL_TOKEN
#   pass-vercel-bootstrap --team TEAM_ID            # store default team id
#
# After bootstrap: wrappers mint access tokens; auth.json rewritten for CLI.
set -euo pipefail

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
REFRESH_PATH="secretspec/shared/default/VERCEL_REFRESH_TOKEN"
TOKEN_PATH="secretspec/shared/default/VERCEL_TOKEN"
TEAM_PATH="secretspec/shared/default/VERCEL_TEAM_ID"
FORCE=false
FROM_AUTH_JSON=""
FROM_TOKEN=""
TEAM_OPT=""

export PASSWORD_STORE_DIR

die() {
  echo "error: $*" >&2
  exit 1
}
log() { echo "$*"; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing $1"; }

default_auth_json_path() {
  if [[ "$(uname -s)" == Darwin ]]; then
    printf '%s' "$HOME/Library/Application Support/com.vercel.cli/auth.json"
  else
    printf '%s' "${XDG_DATA_HOME:-$HOME/.local/share}/com.vercel.cli/auth.json"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --force) FORCE=true ;;
  --device) ;; # alias for default OAuth path
  --from-auth-json)
    if [[ $# -ge 2 && $2 != -* ]]; then
      FROM_AUTH_JSON="$2"
      shift
    else
      FROM_AUTH_JSON="$(default_auth_json_path)"
    fi
    ;;
  --from-token)
    FROM_TOKEN="${2:?}"
    shift
    ;;
  --team)
    TEAM_OPT="${2:?}"
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

need pass
need python3
need git

pass_get() { pass show "$1" 2>/dev/null | head -n1 | tr -d '[:space:]' || true; }
pass_put() {
  printf '%s\n' "$2" | pass insert -e -f "$1" >/dev/null
  log "pass: wrote $1"
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

mint() {
  if command -v vercel-mint-token >/dev/null 2>&1; then
    vercel-mint-token "$@"
  else
    bash "${DOTFILES_ROOT}/scripts/vercel-mint-token.sh" "$@"
  fi
}

write_auth_json_file() {
  local path dir
  path="$(default_auth_json_path)"
  dir="$(dirname "$path")"
  mkdir -p "$dir"
  umask 077
  mint --auth-json >"$path"
  chmod 0600 "$path"
  log "wrote auth.json: $path"
}

store_team() {
  if [[ -n $TEAM_OPT ]]; then
    pass_put "$TEAM_PATH" "$TEAM_OPT"
  fi
}

import_auth_json() {
  local src="$1"
  [[ -r $src ]] || die "auth.json not readable: $src"
  eval "$(
    python3 - "$src" <<'PY'
import json,sys,shlex
d=json.load(open(sys.argv[1]))
refresh = d.get("refreshToken") or d.get("refresh_token") or ""
token = d.get("token") or d.get("access_token") or ""
if not refresh and not token:
    raise SystemExit("auth.json missing refreshToken/token")
if refresh:
    print(f"REFRESH={shlex.quote(refresh)}")
if token:
    print(f"TOKEN={shlex.quote(token)}")
PY
  )"
  if [[ -n ${REFRESH:-} ]]; then
    pass_put "$REFRESH_PATH" "$REFRESH"
  fi
  if [[ -n ${TOKEN:-} && -z ${REFRESH:-} ]]; then
    pass_put "$TOKEN_PATH" "$TOKEN"
  fi
  store_team
  pass_commit "bootstrap: VERCEL_* from auth.json"
  if [[ -n ${REFRESH:-} ]]; then
    mint --refresh >/dev/null
    write_auth_json_file
  fi
  log "Imported auth.json. Check: vercel-mint-token --status && vercel whoami"
}

import_static_token() {
  local token="$1"
  [[ -n $token ]] || die "empty token"
  pass_put "$TOKEN_PATH" "$token"
  store_team
  pass_commit "bootstrap: VERCEL_TOKEN"
  log "Stored static VERCEL_TOKEN. Prefer OAuth: re-run without --from-token."
  log "Check: vercel whoami"
}

if [[ -n $FROM_TOKEN ]]; then
  import_static_token "$FROM_TOKEN"
  exit 0
fi

if [[ -n $FROM_AUTH_JSON ]]; then
  import_auth_json "$FROM_AUTH_JSON"
  exit 0
fi

if ! $FORCE && [[ -n $(pass_get "$REFRESH_PATH") ]]; then
  log "VERCEL_REFRESH_TOKEN already in pass — refreshing access + rewriting auth.json."
  log "  (use --force to re-run browser OAuth)"
  mint --refresh >/dev/null
  store_team
  [[ -n $TEAM_OPT ]] && pass_commit "bootstrap: VERCEL_TEAM_ID"
  write_auth_json_file
  log "Check: vercel-mint-token --status && vercel whoami"
  exit 0
fi

need curl
mint --device >/dev/null
store_team
[[ -n $TEAM_OPT ]] && pass_commit "bootstrap: VERCEL_TEAM_ID"
write_auth_json_file
log "Check: vercel-mint-token --status && vercel whoami"
