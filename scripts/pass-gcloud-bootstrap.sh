#!/usr/bin/env bash
# Bootstrap Google Cloud CLI auth into pass (SecretSpec) + local ADC.
#
#   pass-gcloud-bootstrap              # localhost OAuth (browser once)
#   pass-gcloud-bootstrap --device     # same (alias)
#   pass-gcloud-bootstrap --force      # re-auth even if refresh_token exists
#   pass-gcloud-bootstrap --from-adc   # import ~/.config/gcloud/application_default_credentials.json
#   pass-gcloud-bootstrap --from-sa FILE  # import service-account JSON key
#   pass-gcloud-bootstrap --project ID    # store default project
#
# After bootstrap: wrappers mint access tokens; ADC written for client libs.
set -euo pipefail

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CLIENT_ID_PATH="secretspec/shared/default/GCLOUD_CLIENT_ID"
CLIENT_SECRET_PATH="secretspec/shared/default/GCLOUD_CLIENT_SECRET"
REFRESH_PATH="secretspec/shared/default/GCLOUD_REFRESH_TOKEN"
ACCOUNT_PATH="secretspec/shared/default/GCLOUD_ACCOUNT"
PROJECT_PATH="secretspec/shared/default/GCLOUD_PROJECT"
SA_KEY_PATH="secretspec/shared/default/GCLOUD_SA_KEY"
ADC_PATH="${CLOUDSDK_CONFIG:-$HOME/.config/gcloud}/application_default_credentials.json"
FORCE=false
FROM_ADC=false
FROM_SA=""
PROJECT_OPT=""

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
  --device) ;; # alias for default OAuth path
  --from-adc) FROM_ADC=true ;;
  --from-sa)
    FROM_SA="${2:?}"
    shift
    ;;
  --project)
    PROJECT_OPT="${2:?}"
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
pass_put_multiline() {
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

write_adc_file() {
  local dir
  dir="$(dirname "$ADC_PATH")"
  mkdir -p "$dir"
  umask 077
  if command -v gcloud-mint-token >/dev/null 2>&1; then
    gcloud-mint-token --adc >"$ADC_PATH"
  else
    bash "${DOTFILES_ROOT}/scripts/gcloud-mint-token.sh" --adc >"$ADC_PATH"
  fi
  chmod 0600 "$ADC_PATH"
  log "wrote ADC: $ADC_PATH"
}

store_project() {
  if [[ -n $PROJECT_OPT ]]; then
    pass_put "$PROJECT_PATH" "$PROJECT_OPT"
  fi
}

import_adc() {
  local src="${1:-$ADC_PATH}"
  [[ -r $src ]] || die "ADC not readable: $src"
  eval "$(
    python3 - "$src" <<'PY'
import json,sys,shlex
d=json.load(open(sys.argv[1]))
if d.get("type") != "authorized_user":
    raise SystemExit("ADC type is not authorized_user (got %r)" % (d.get("type"),))
for k,out in (("client_id","CID"),("client_secret","CSEC"),("refresh_token","REFRESH")):
    v=d.get(k) or ""
    if not v:
        raise SystemExit(f"ADC missing {k}")
    print(f"{out}={shlex.quote(v)}")
PY
  )"
  pass_put "$CLIENT_ID_PATH" "$CID"
  pass_put "$CLIENT_SECRET_PATH" "$CSEC"
  pass_put "$REFRESH_PATH" "$REFRESH"
  store_project
  # Resolve account via mint
  local access email
  if command -v gcloud-mint-token >/dev/null 2>&1; then
    access="$(gcloud-mint-token --refresh)"
  else
    access="$(bash "${DOTFILES_ROOT}/scripts/gcloud-mint-token.sh" --refresh)"
  fi
  email="$(
    curl -fsS -H "Authorization: Bearer $access" \
      https://www.googleapis.com/oauth2/v3/userinfo |
      python3 -c 'import json,sys; print(json.load(sys.stdin).get("email",""))'
  )"
  [[ -n $email ]] && pass_put "$ACCOUNT_PATH" "$email"
  pass_commit "bootstrap: GCLOUD_* from ADC"
  write_adc_file
  log "Imported ADC for ${email:-unknown}. Check: gcloud-mint-token --status && gcloud auth list"
}

import_sa() {
  local file="$1"
  [[ -r $file ]] || die "SA key not readable: $file"
  python3 - "$file" <<'PY' >/dev/null
import json,sys
d=json.load(open(sys.argv[1]))
assert d.get("type") == "service_account", d.get("type")
assert d.get("private_key") and d.get("client_email")
PY
  pass_put_multiline "$SA_KEY_PATH" "$file"
  local email
  email="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["client_email"])' "$file")"
  pass_put "$ACCOUNT_PATH" "$email"
  store_project
  pass_commit "bootstrap: GCLOUD_SA_KEY ($email)"
  # Materialize ADC path as SA key for libraries
  local dir
  dir="$(dirname "$ADC_PATH")"
  mkdir -p "$dir"
  umask 077
  cp "$file" "$ADC_PATH"
  chmod 0600 "$ADC_PATH"
  log "Imported SA $email → pass + $ADC_PATH"
  log "Prefer user OAuth (default bootstrap) for interactive gcloud; SA is fallback."
}

if [[ -n $FROM_SA ]]; then
  import_sa "$FROM_SA"
  exit 0
fi

if $FROM_ADC; then
  import_adc
  exit 0
fi

if ! $FORCE && [[ -n $(pass_get "$REFRESH_PATH") ]]; then
  log "GCLOUD_REFRESH_TOKEN already in pass — refreshing access + rewriting ADC."
  log "  (use --force to re-run browser OAuth)"
  if command -v gcloud-mint-token >/dev/null 2>&1; then
    gcloud-mint-token --refresh >/dev/null
  else
    bash "${DOTFILES_ROOT}/scripts/gcloud-mint-token.sh" --refresh >/dev/null
  fi
  store_project
  [[ -n $PROJECT_OPT ]] && pass_commit "bootstrap: GCLOUD_PROJECT"
  write_adc_file
  log "Check: gcloud-mint-token --status && gcloud auth list"
  exit 0
fi

need curl
if command -v gcloud-mint-token >/dev/null 2>&1; then
  gcloud-mint-token --device >/dev/null
else
  export DOTFILES_ROOT
  bash "${DOTFILES_ROOT}/scripts/gcloud-mint-token.sh" --device >/dev/null
fi
store_project
[[ -n $PROJECT_OPT ]] && pass_commit "bootstrap: GCLOUD_PROJECT"
write_adc_file
log "Check: gcloud-mint-token --status && gcloud auth list && gcloud config get-value account"
