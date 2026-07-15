#!/usr/bin/env bash
# Bootstrap FlakeHub device token into pass (SecretSpec) + local determinate-nixd login.
#
#   pass-flakehub-bootstrap              # elevate (UI) → mint → pass → login device JWT
#   pass-flakehub-bootstrap --from-clipboard
#   pass-flakehub-bootstrap --token-file FILE   # admin/user token file for elevation
#   pass-flakehub-bootstrap --force
#
# Day-to-day rotation: pass-rotate-cli-auth --flakehub (auto-elevates when needed).
set -euo pipefail

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
ORG="${FLAKEHUB_ORG:-aspauldingcode}"
FH_PASS_PATH="secretspec/shared/default/FLAKEHUB_TOKEN"
FH_DESC_PREFIX="dendritic-cli-auth"
FORCE=false
FROM_CLIPBOARD=false
TOKEN_FILE=""
YES=false

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
  --from-clipboard) FROM_CLIPBOARD=true ;;
  --token-file)
    TOKEN_FILE="${2:?}"
    shift
    ;;
  --org)
    ORG="${2:?}"
    shift
    ;;
  --yes | -y) YES=true ;;
  -h | --help)
    sed -n '2,12p' "$0" | sed 's/^# //; s/^#//'
    exit 0
    ;;
  *) die "unknown arg: $1" ;;
  esac
  shift
done

need pass
need git
need determinate-nixd

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
    git -C "$PASSWORD_STORE_DIR" push >/dev/null 2>&1 ||
      log "warning: pass git push failed (peers catch up via sync)"
  fi
}

existing="$(pass_get "$FH_PASS_PATH")"
if [[ -n $existing && $existing != placeholder && $FORCE == false ]]; then
  log "FLAKEHUB_TOKEN already in pass — use --force to remint, or: pass-rotate-cli-auth --flakehub"
  # Still ensure daemon logged in
  tf="$(mktemp)"
  umask 077
  printf '%s\n' "$existing" >"$tf"
  determinate-nixd login token --token-file "$tf" >/dev/null 2>&1 ||
    determinate-nixd auth login token --token-file "$tf" >/dev/null 2>&1 || true
  rm -f "$tf"
  determinate-nixd auth bind "$ORG" >/dev/null 2>&1 || true
  exit 0
fi

if [[ -n $TOKEN_FILE ]]; then
  [[ -r $TOKEN_FILE ]] || die "unreadable --token-file $TOKEN_FILE"
  log "elevating with --token-file…"
  determinate-nixd auth login token --token-file "$TOKEN_FILE"
elif $FROM_CLIPBOARD; then
  clip=""
  if command -v pbpaste >/dev/null 2>&1; then
    clip="$(pbpaste | tr -d '[:space:]')"
  elif command -v wl-paste >/dev/null 2>&1; then
    clip="$(wl-paste | tr -d '[:space:]')"
  else
    die "no clipboard tool"
  fi
  [[ -n $clip ]] || die "clipboard empty"
  tf="$(mktemp)"
  umask 077
  printf '%s\n' "$clip" >"$tf"
  determinate-nixd auth login token --token-file "$tf"
  rm -f "$tf"
else
  log "FlakeHub bootstrap: minting needs *admin user* auth (device JWTs cannot create)."
  log "  1. https://flakehub.com/user/settings?editview=tokens → New token"
  log "  2. Paste into the prompt (or: --token-file / --from-clipboard)"
  if command -v open >/dev/null 2>&1; then
    open "https://flakehub.com/user/settings?editview=tokens" >/dev/null 2>&1 || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "https://flakehub.com/user/settings?editview=tokens" >/dev/null 2>&1 || true
  fi
  if [[ ! -t 0 ]] && ! $YES; then
    die "non-interactive: pass a UI user token via --token-file FILE or --from-clipboard"
  fi
  determinate-nixd auth login token
fi

determinate-nixd auth bind "$ORG" >/dev/null 2>&1 || true

host="$(hostname -s 2>/dev/null || hostname || echo host)"
desc="${FH_DESC_PREFIX} ${host} $(date -u +%Y-%m-%d)"
log "minting device token ($desc)…"
token="$(
  if command -v flakehub-mint-token >/dev/null 2>&1; then
    FLAKEHUB_ORG="$ORG" flakehub-mint-token --org "$ORG" --description "$desc"
  else
    bash "${DOTFILES_ROOT}/scripts/flakehub-mint-token.sh" --org "$ORG" --description "$desc"
  fi
)"
token="$(printf '%s' "$token" | tr -d '[:space:]')"
[[ -n $token ]] || die "empty device token from mint"

pass_put "$FH_PASS_PATH" "$token"
pass_commit "secretspec: FLAKEHUB_TOKEN ($desc)"

tf="$(mktemp)"
umask 077
printf '%s\n' "$token" >"$tf"
if determinate-nixd login token --token-file "$tf" >/dev/null 2>&1 ||
  determinate-nixd auth login token --token-file "$tf" >/dev/null 2>&1; then
  log "logged in with new device token"
else
  rm -f "$tf"
  die "login with new device token failed"
fi
rm -f "$tf"
determinate-nixd auth bind "$ORG" >/dev/null 2>&1 || true

log "done. Rotate later: pass-rotate-cli-auth --flakehub --yes"
log "Peers pick up pass via ntfy sync; activation runs flakehub-pass-login."
