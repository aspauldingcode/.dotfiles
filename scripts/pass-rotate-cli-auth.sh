#!/usr/bin/env bash
# Rotate CLI auth tokens into pass (no path memorization).
#
#   nix run .#pass-rotate-cli-auth              # rotate what's due / all
#   nix run .#pass-rotate-cli-auth -- --status
#   nix run .#pass-rotate-cli-auth -- --flakehub
#   nix run .#pass-rotate-cli-auth -- --github
#   nix run .#pass-rotate-cli-auth -- --gcloud
#   nix run .#pass-rotate-cli-auth -- --vercel
#   nix run .#pass-rotate-cli-auth -- --wg
#   nix run .#pass-rotate-cli-auth -- --auto    # only if within --days of expiry
#
# FlakeHub: mint device JWT via flakehub-mint-token (admin elevate when needed).
#   One-time: nix run .#pass-flakehub-bootstrap
#   Rotate:   pass-rotate-cli-auth --flakehub  (TTY elevates; agents notify)
# GitHub: fully automated via GitHub App refresh_token in pass
#   (one-time: nix run .#pass-github-app-bootstrap). Legacy classic PAT paste
#   still works with --from-clipboard / stdin if App is not configured.
# Google Cloud: fully automated via OAuth refresh_token in pass
#   (one-time: nix run .#pass-gcloud-bootstrap). Access tokens mint on demand;
#   --gcloud forces refresh (or localhost re-auth if refresh revoked).
# Vercel: fully automated via OAuth refresh_token in pass
#   (one-time: nix run .#pass-vercel-bootstrap). Access tokens mint on demand;
#   --vercel forces refresh (or device re-auth if refresh revoked).
# WireGuard: rotate pairing keys/PSK in pass (both peers must rematerialize).
#   One-time: nix run .#pass-wg-bootstrap
#   Rotate:   pass-rotate-cli-auth --wg   (or pass-wg-rotate)
set -euo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
GH_PASS_PATH="secretspec/shared/default/GH_TOKEN"
GH_REFRESH_PATH="secretspec/shared/default/GH_REFRESH_TOKEN"
FH_PASS_PATH="secretspec/shared/default/FLAKEHUB_TOKEN"
GCLOUD_REFRESH_PATH="secretspec/shared/default/GCLOUD_REFRESH_TOKEN"
GCLOUD_SA_PATH="secretspec/shared/default/GCLOUD_SA_KEY"
VERCEL_REFRESH_PATH="secretspec/shared/default/VERCEL_REFRESH_TOKEN"
VERCEL_TOKEN_PATH="secretspec/shared/default/VERCEL_TOKEN"
FH_DESC_PREFIX="dendritic-cli-auth"
ORG="${FLAKEHUB_ORG:-aspauldingcode}"
DAYS=14
DO_STATUS=false
DO_AUTO=false
DO_FH=false
DO_GH=false
DO_GCLOUD=false
DO_VERCEL=false
DO_WG=false
DO_BOTH=true
FROM_CLIPBOARD=false
FROM_GH_AUTH=false
YES=false
REVOKE_OLD=true
FAILED=0

export PASSWORD_STORE_DIR

die() {
  echo "error: $*" >&2
  exit 1
}
need() { command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"; }
log() { printf '%s\n' "$*"; }

usage() {
  sed -n '2,24p' "$0" | sed 's/^# //; s/^#//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --status)
    DO_STATUS=true
    DO_BOTH=false
    ;;
  --auto) DO_AUTO=true ;;
  --flakehub | --fh)
    DO_FH=true
    DO_BOTH=false
    ;;
  --github | --gh)
    DO_GH=true
    DO_BOTH=false
    ;;
  --gcloud | --gcp)
    DO_GCLOUD=true
    DO_BOTH=false
    ;;
  --vercel | --vc)
    DO_VERCEL=true
    DO_BOTH=false
    ;;
  --wg | --wireguard)
    DO_WG=true
    DO_BOTH=false
    ;;
  --days)
    DAYS="${2:?}"
    shift
    ;;
  --org)
    ORG="${2:?}"
    shift
    ;;
  --from-clipboard) FROM_CLIPBOARD=true ;;
  --from-gh-auth) FROM_GH_AUTH=true ;;
  --keep-old) REVOKE_OLD=false ;;
  --yes | -y) YES=true ;;
  -h | --help)
    usage
    exit 0
    ;;
  *) die "unknown arg: $1 (see --help)" ;;
  esac
  shift
done

if $DO_BOTH; then
  DO_FH=true
  DO_GH=true
  DO_GCLOUD=true
  DO_VERCEL=true
fi

need pass
need gpg
need git
need python3

days_until() {
  python3 -c '
import sys, datetime as dt
raw = sys.stdin.read().strip()
if not raw:
    print(9999); raise SystemExit
raw = raw.replace(" UTC", "+00:00")
for fmt in ("%Y-%m-%d %H:%M:%S %z", "%Y-%m-%dT%H:%M:%S%z", "%Y-%m-%d %H:%M:%S%z", "%Y-%m-%d"):
    try:
        when = dt.datetime.strptime(raw, fmt)
        break
    except ValueError:
        when = None
else:
    try:
        when = dt.datetime.fromisoformat(raw)
    except Exception:
        print(9999); raise SystemExit
if when.tzinfo is None:
    when = when.replace(tzinfo=dt.timezone.utc)
now = dt.datetime.now(dt.timezone.utc)
print(int((when.astimezone(dt.timezone.utc) - now).total_seconds() // 86400))
'
}

pass_insert_secret() {
  local path="$1"
  local value="$2"
  printf '%s\n' "$value" | pass insert -e -f "$path" >/dev/null
  log "pass: wrote $path"
}

store_commit_push() {
  git -C "$PASSWORD_STORE_DIR" add -A
  if git -C "$PASSWORD_STORE_DIR" status --porcelain | grep -q .; then
    local msg="$1"
    if ! git -C "$PASSWORD_STORE_DIR" -c user.useConfigOnly=true commit -m "$msg" >/dev/null 2>&1; then
      git -C "$PASSWORD_STORE_DIR" -c user.name="pass-store-sync" \
        -c user.email="pass-store-sync@localhost" commit -m "$msg" >/dev/null
    fi
    git -C "$PASSWORD_STORE_DIR" push >/dev/null 2>&1 || log "warning: pass store push failed (watcher may retry)"
  fi
}

fh_expiry_from_status() {
  fh status 2>/dev/null | awk -F': ' '/Token expires at/ { print $2; exit }' || true
}

gh_app_configured() {
  pass show "$GH_REFRESH_PATH" >/dev/null 2>&1
}

gh_mint_token() {
  if command -v github-app-mint-token >/dev/null 2>&1; then
    github-app-mint-token "$@"
  else
    bash "${DOTFILES_ROOT}/scripts/github-app-mint-token.sh" "$@"
  fi
}

gcloud_configured() {
  pass show "$GCLOUD_REFRESH_PATH" >/dev/null 2>&1
}

gcloud_sa_configured() {
  pass show "$GCLOUD_SA_PATH" >/dev/null 2>&1
}

gcloud_mint_token() {
  if command -v gcloud-mint-token >/dev/null 2>&1; then
    gcloud-mint-token "$@"
  else
    bash "${DOTFILES_ROOT}/scripts/gcloud-mint-token.sh" "$@"
  fi
}

gcloud_access_left_secs() {
  local cache="${GCLOUD_CACHE_DIR:-$HOME/.cache/dendritic}/gcloud-token.json"
  python3 - "$cache" <<'PY' 2>/dev/null || echo 0
import json,sys,time
try:
  d=json.load(open(sys.argv[1]))
  print(max(0, int(d.get("expires_at",0))-int(time.time())))
except Exception:
  print(0)
PY
}

vercel_configured() {
  pass show "$VERCEL_REFRESH_PATH" >/dev/null 2>&1
}

vercel_static_configured() {
  pass show "$VERCEL_TOKEN_PATH" >/dev/null 2>&1
}

vercel_mint_token() {
  if command -v vercel-mint-token >/dev/null 2>&1; then
    vercel-mint-token "$@"
  else
    bash "${DOTFILES_ROOT}/scripts/vercel-mint-token.sh" "$@"
  fi
}

vercel_auth_json_path() {
  if [[ -n ${VERCEL_AUTH_JSON:-} ]]; then
    printf '%s' "$VERCEL_AUTH_JSON"
  elif [[ "$(uname -s)" == Darwin ]]; then
    printf '%s' "$HOME/Library/Application Support/com.vercel.cli/auth.json"
  else
    printf '%s' "${XDG_DATA_HOME:-$HOME/.local/share}/com.vercel.cli/auth.json"
  fi
}

vercel_access_left_secs() {
  local cache="${VERCEL_CACHE_DIR:-$HOME/.cache/dendritic}/vercel-token.json"
  python3 - "$cache" <<'PY' 2>/dev/null || echo 0
import json,sys,time
try:
  d=json.load(open(sys.argv[1]))
  print(max(0, int(d.get("expires_at",0))-int(time.time())))
except Exception:
  print(0)
PY
}

gh_expiry_from_api() {
  local token="" hdr
  if gh_app_configured; then
    token="$(gh_mint_token 2>/dev/null || true)"
  fi
  if [[ -z $token ]]; then
    token="$(pass show "$GH_PASS_PATH" 2>/dev/null | head -n1 | tr -d '[:space:]' || true)"
  fi
  if [[ -n $token ]]; then
    hdr="$(GH_TOKEN="$token" gh api -i /user 2>/dev/null || true)"
  else
    hdr="$(gh api -i /user 2>/dev/null || true)"
  fi
  # No expiration header for some token types — must not trip pipefail.
  printf '%s\n' "$hdr" | grep -i '^github-authentication-token-expiration:' |
    head -n1 | sed -E 's/^[^:]*:[[:space:]]*//; s/\r$//' || true
}

fh_mint_token() {
  if command -v flakehub-mint-token >/dev/null 2>&1; then
    flakehub-mint-token "$@"
  else
    bash "${DOTFILES_ROOT}/scripts/flakehub-mint-token.sh" "$@"
  fi
}

status() {
  local fh_exp gh_exp fh_days gh_days gcloud_left vercel_left
  fh_exp="$(fh_expiry_from_status)"
  gh_exp="$(gh_expiry_from_api)"
  fh_days="$(printf '%s' "$fh_exp" | days_until)"
  gh_days="$(printf '%s' "$gh_exp" | days_until)"
  log "FlakeHub org: $ORG"
  log "  FLAKEHUB_TOKEN expiry: ${fh_exp:-unknown} (${fh_days}d)"
  log "  pass path: $FH_PASS_PATH"
  log "GitHub"
  if gh_app_configured; then
    log "  mode: GitHub App (pass refresh_token) — API mint enabled"
    gh_mint_token --status 2>/dev/null | sed 's/^/  /' || true
  else
    log "  mode: classic PAT (legacy) — run: pass-github-app-bootstrap"
  fi
  log "  access expiry: ${gh_exp:-unknown} (${gh_days}d)"
  log "  pass paths: $GH_REFRESH_PATH / $GH_PASS_PATH"
  log "Google Cloud"
  if gcloud_configured; then
    log "  mode: OAuth (pass refresh_token) — API mint enabled"
    gcloud_mint_token --status 2>/dev/null | sed 's/^/  /' || true
    gcloud_left="$(gcloud_access_left_secs)"
    log "  access cache left: ${gcloud_left}s"
  elif gcloud_sa_configured; then
    log "  mode: service-account JSON (legacy) — run: pass-gcloud-bootstrap for OAuth minting"
    log "  pass path: $GCLOUD_SA_PATH"
  else
    log "  mode: unset — run: pass-gcloud-bootstrap"
  fi
  log "  pass path: $GCLOUD_REFRESH_PATH"
  log "Vercel"
  if vercel_configured; then
    log "  mode: OAuth (pass refresh_token) — API mint enabled"
    vercel_mint_token --status 2>/dev/null | sed 's/^/  /' || true
    vercel_left="$(vercel_access_left_secs)"
    log "  access cache left: ${vercel_left}s"
  elif vercel_static_configured; then
    log "  mode: static PAT (legacy) — run: pass-vercel-bootstrap for OAuth minting"
    log "  pass path: $VERCEL_TOKEN_PATH"
  else
    log "  mode: unset — run: pass-vercel-bootstrap"
  fi
  log "  pass path: $VERCEL_REFRESH_PATH"
  log "WireGuard"
  if pass show secretspec/shared/default/WG_PSK >/dev/null 2>&1; then
    if command -v pass-wg-bootstrap >/dev/null 2>&1; then
      pass-wg-bootstrap --status 2>/dev/null | sed 's/^/  /' || true
    else
      bash "${DOTFILES_ROOT}/scripts/pass-wg-bootstrap.sh" --status 2>/dev/null | sed 's/^/  /' || true
    fi
  else
    log "  mode: unset — run: nix run .#pass-wg-bootstrap"
  fi
  log "Auto threshold: ${DAYS}d"
}

rotate_flakehub() {
  need determinate-nixd
  local host desc token list_before tf
  host="$(hostname -s 2>/dev/null || hostname || echo host)"
  desc="${FH_DESC_PREFIX} ${host} $(date -u +%Y-%m-%d)"
  log "FlakeHub: minting device token ($desc)…"

  # Keep stderr on TTY so admin elevate prompts are visible.
  if ! token="$(
    FLAKEHUB_ORG="$ORG" fh_mint_token --org "$ORG" --description "$desc" | tr -d '[:space:]'
  )" || [[ -z $token ]]; then
    log "FlakeHub: mint failed"
    if [[ ! -t 0 ]]; then
      log "FlakeHub: non-interactive — need admin elevate once:"
      log "  nix run .#pass-flakehub-bootstrap"
      log "  or: pass-rotate-cli-auth --flakehub  (TTY)"
      if command -v dendritic >/dev/null 2>&1; then
        dendritic notify "FlakeHub token" "Run pass-flakehub-bootstrap to remint device token" 2>/dev/null || true
      elif command -v notify-send >/dev/null 2>&1; then
        notify-send "FlakeHub token" "pass-flakehub-bootstrap" || true
      fi
    else
      log "  Bootstrap: nix run .#pass-flakehub-bootstrap"
      log "  Or UI device token: https://flakehub.com/${ORG}/settings?editview=device-tokens"
    fi
    return 1
  fi

  pass_insert_secret "$FH_PASS_PATH" "$token"

  tf="$(mktemp)"
  umask 077
  printf '%s\n' "$token" >"$tf"
  if determinate-nixd login token --token-file "$tf" >/dev/null 2>&1 ||
    determinate-nixd auth login token --token-file "$tf" >/dev/null 2>&1; then
    log "FlakeHub: logged in with new device token"
  else
    rm -f "$tf"
    log "FlakeHub: login with new token failed"
    return 1
  fi
  rm -f "$tf"
  determinate-nixd auth bind "$ORG" >/dev/null 2>&1 || true

  if $REVOKE_OLD; then
    list_before="$(determinate-nixd auth token device list --org "$ORG" -n 50 2>/dev/null || true)"
    while read -r tid; do
      [[ -n $tid ]] || continue
      if printf '%s\n' "$list_before" | grep -F "$tid" | grep -F "$FH_DESC_PREFIX" >/dev/null &&
        ! printf '%s\n' "$list_before" | grep -F "$tid" | grep -F "$desc" >/dev/null; then
        log "FlakeHub: revoking old token $tid"
        determinate-nixd auth token device revoke --org "$ORG" --token-id "$tid" >/dev/null 2>&1 || true
      fi
    done < <(printf '%s\n' "$list_before" | grep -Eo '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' || true)
  fi

  store_commit_push "rotate: FLAKEHUB_TOKEN ($desc)"
  log "FlakeHub: rotation complete"
}

read_github_token() {
  local token=""
  if $FROM_GH_AUTH; then
    need gh
    token="$(gh auth token 2>/dev/null | tr -d '[:space:]' || true)"
    [[ -n $token ]] || die "gh auth token empty — run: gh auth login"
  elif $FROM_CLIPBOARD; then
    if command -v pbpaste >/dev/null 2>&1; then
      token="$(pbpaste | tr -d '[:space:]')"
    elif command -v wl-paste >/dev/null 2>&1; then
      token="$(wl-paste | tr -d '[:space:]')"
    else
      die "no clipboard tool (pbpaste/wl-paste)"
    fi
  elif [[ ! -t 0 ]]; then
    token="$(tr -d '[:space:]' <&0)"
  else
    log "Legacy classic PAT paste (prefer: pass-github-app-bootstrap for API minting)."
    log "  https://github.com/settings/tokens/new"
    if command -v open >/dev/null 2>&1; then
      open "https://github.com/settings/tokens/new" 2>/dev/null || true
    elif command -v xdg-open >/dev/null 2>&1; then
      xdg-open "https://github.com/settings/tokens/new" 2>/dev/null || true
    fi
    printf 'Paste new GH_TOKEN (input hidden): ' >&2
    stty -echo 2>/dev/null || true
    read -r token
    stty echo 2>/dev/null || true
    printf '\n' >&2
    token="$(printf '%s' "$token" | tr -d '[:space:]')"
  fi
  [[ -n $token ]] || die "empty GitHub token"
  printf '%s' "$token"
}

rotate_github() {
  local token login
  if gh_app_configured && ! $FROM_CLIPBOARD && ! $FROM_GH_AUTH; then
    log "GitHub: refreshing App user token via API (pass-backed)…"
    token="$(gh_mint_token --refresh 2>/dev/null || true)"
    if [[ -z $token ]]; then
      log "GitHub: refresh failed — starting device flow"
      token="$(gh_mint_token --device)"
    fi
    login="$(GH_TOKEN="$token" gh api /user -q .login 2>/dev/null || true)"
    [[ -n $login ]] || die "GitHub: minted token rejected"
    log "GitHub: App token OK for $login (refresh_token updated in pass)"
    return 0
  fi

  token="$(read_github_token)"
  pass_insert_secret "$GH_PASS_PATH" "$token"
  if GH_TOKEN="$token" gh api /user -q .login >/dev/null 2>&1; then
    log "GitHub: token accepted for $(GH_TOKEN="$token" gh api /user -q .login)"
  else
    die "GitHub: token rejected by api.github.com"
  fi
  store_commit_push "rotate: GH_TOKEN"
  log "GitHub: classic PAT stored in pass"
}

rotate_gcloud() {
  local token adc_dir
  if gcloud_configured; then
    log "gcloud: refreshing OAuth access via API (pass-backed)…"
    token="$(gcloud_mint_token --refresh 2>/dev/null || true)"
    if [[ -z $token ]]; then
      log "gcloud: refresh failed — starting localhost OAuth"
      token="$(gcloud_mint_token --device)"
    fi
    [[ -n $token ]] || die "gcloud: mint returned empty token"
    adc_dir="${CLOUDSDK_CONFIG:-$HOME/.config/gcloud}"
    mkdir -p "$adc_dir"
    umask 077
    gcloud_mint_token --adc >"$adc_dir/application_default_credentials.json"
    chmod 0600 "$adc_dir/application_default_credentials.json"
    log "gcloud: access OK; ADC rewritten"
    return 0
  fi
  if gcloud_sa_configured; then
    log "gcloud: SA key present — OAuth mint not configured."
    log "  Prefer: nix run .#pass-gcloud-bootstrap"
    if command -v dendritic >/dev/null 2>&1; then
      dendritic notify "gcloud SA mode" "Run pass-gcloud-bootstrap for OAuth minting" 2>/dev/null || true
    elif command -v notify-send >/dev/null 2>&1; then
      notify-send "gcloud SA mode" "pass-gcloud-bootstrap" || true
    fi
    return 0
  fi
  die "gcloud: not configured — run: nix run .#pass-gcloud-bootstrap"
}

rotate_vercel() {
  local token
  if vercel_configured; then
    log "vercel: refreshing OAuth access via API (pass-backed)…"
    # Prefer single locked mint+atomic auth.json write.
    token="$(vercel_mint_token --refresh --write-auth 2>/dev/null || true)"
    if [[ -z $token ]]; then
      # Device flow blocks HM/NixOS activation forever when no TTY (Cursor, systemd).
      if [[ -t 0 ]]; then
        log "vercel: refresh failed — starting OAuth device flow"
        token="$(vercel_mint_token --device --write-auth)"
      else
        log "vercel: refresh failed — skip device flow (non-interactive); run: pass-vercel-bootstrap"
        return 0
      fi
    fi
    [[ -n $token ]] || die "vercel: mint returned empty token"
    log "vercel: access OK; auth.json rewritten"
    return 0
  fi
  if vercel_static_configured; then
    log "vercel: static PAT present — OAuth mint not configured."
    log "  Prefer: nix run .#pass-vercel-bootstrap"
    if command -v dendritic >/dev/null 2>&1; then
      dendritic notify "vercel PAT mode" "Run pass-vercel-bootstrap for OAuth minting" 2>/dev/null || true
    elif command -v notify-send >/dev/null 2>&1; then
      notify-send "vercel PAT mode" "pass-vercel-bootstrap" || true
    fi
    return 0
  fi
  die "vercel: not configured — run: nix run .#pass-vercel-bootstrap"
}

rotate_wg() {
  log "wireguard: rotating pairing keys + PSK in pass…"
  if command -v pass-wg-rotate >/dev/null 2>&1; then
    pass-wg-rotate
  else
    bash "${DOTFILES_ROOT}/scripts/pass-wg-rotate.sh"
  fi
  log "wireguard: done — both peers: pass-materialize && dendritic-wg-ensure"
}

due_for_rotate() {
  local exp days
  exp="$1"
  days="$(printf '%s' "$exp" | days_until)"
  [[ $days -le $DAYS ]]
}

if $DO_STATUS; then
  status
  exit 0
fi

if $DO_AUTO; then
  status
  if $DO_FH; then
    if due_for_rotate "$(fh_expiry_from_status)"; then
      log "FlakeHub: within ${DAYS}d of expiry — rotating"
      rotate_flakehub || {
        log "FlakeHub: auto-rotate FAILED (admin elevate may be required)"
        FAILED=1
      }
    else
      log "FlakeHub: not due (threshold ${DAYS}d)"
    fi
  fi
  if $DO_GH; then
    if gh_app_configured; then
      if due_for_rotate "$(gh_expiry_from_api)"; then
        log "GitHub App: within ${DAYS}d of access expiry — refreshing via API"
        rotate_github
      else
        log "GitHub App: access token not due (threshold ${DAYS}d)"
      fi
    elif due_for_rotate "$(gh_expiry_from_api)"; then
      if $FROM_GH_AUTH || $FROM_CLIPBOARD || [[ ! -t 0 ]]; then
        log "GitHub: within ${DAYS}d of expiry — rotating classic PAT"
        rotate_github
      else
        log "GitHub: classic PAT due — prefer App minting:"
        log "  pass-github-app-bootstrap"
        if command -v dendritic >/dev/null 2>&1; then
          dendritic notify "GitHub token expiring" "Run pass-github-app-bootstrap for API token minting" 2>/dev/null || true
        elif command -v notify-send >/dev/null 2>&1; then
          notify-send "GitHub token expiring" "pass-github-app-bootstrap" || true
        fi
      fi
    else
      log "GitHub: not due (threshold ${DAYS}d)"
    fi
  fi
  if $DO_GCLOUD; then
    if gcloud_configured; then
      # Access tokens live ~1h; weekly agent just proves refresh still works + refreshes cache/ADC.
      log "gcloud: verifying OAuth refresh + rewriting ADC"
      rotate_gcloud
    elif gcloud_sa_configured; then
      log "gcloud: SA mode — no auto OAuth rotate (run pass-gcloud-bootstrap)"
    else
      log "gcloud: not configured — skip"
    fi
  fi
  if $DO_VERCEL; then
    if vercel_configured; then
      log "vercel: verifying OAuth refresh + rewriting auth.json"
      rotate_vercel
    elif vercel_static_configured; then
      log "vercel: static PAT mode — no auto OAuth rotate (run pass-vercel-bootstrap)"
    else
      log "vercel: not configured — skip"
    fi
  fi
  exit 0
fi

if $DO_FH; then
  if ! $YES && [[ -t 0 ]]; then
    read -r -p "Rotate FlakeHub device token for org '$ORG'? [y/N] " ans
    [[ $ans == [yY]* ]] || die "aborted"
  fi
  rotate_flakehub || {
    log "FlakeHub: rotation FAILED"
    FAILED=1
  }
fi

if $DO_GH; then
  rotate_github || {
    log "GitHub: rotation FAILED"
    FAILED=1
  }
fi

if $DO_GCLOUD; then
  if ! gcloud_configured && ! gcloud_sa_configured; then
    if $DO_BOTH; then
      log "gcloud: not configured — skip (run: nix run .#pass-gcloud-bootstrap)"
    else
      die "gcloud: not configured — run: nix run .#pass-gcloud-bootstrap"
    fi
  else
    rotate_gcloud || {
      log "gcloud: rotation FAILED"
      FAILED=1
    }
  fi
fi

if $DO_VERCEL; then
  if ! vercel_configured && ! vercel_static_configured; then
    if $DO_BOTH; then
      log "vercel: not configured — skip (run: nix run .#pass-vercel-bootstrap)"
    else
      die "vercel: not configured — run: nix run .#pass-vercel-bootstrap"
    fi
  else
    rotate_vercel || {
      log "vercel: rotation FAILED"
      FAILED=1
    }
  fi
fi

# WireGuard is never part of DO_BOTH / --auto (breaks peers until both rematerialize).
if $DO_WG; then
  if ! pass show secretspec/shared/default/WG_PSK >/dev/null 2>&1; then
    die "wireguard: not configured — run: nix run .#pass-wg-bootstrap"
  fi
  if ! $YES && [[ -t 0 ]]; then
    read -r -p "Rotate WireGuard keys+PSK (both peers must rematerialize)? [y/N] " ans
    [[ $ans == [yY]* ]] || die "aborted"
  fi
  rotate_wg || {
    log "wireguard: rotation FAILED"
    FAILED=1
  }
fi

exit "${FAILED:-0}"
