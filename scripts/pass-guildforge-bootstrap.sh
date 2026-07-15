#!/usr/bin/env bash
# Bootstrap Discord bot credentials into pass (SecretSpec) for GuildForge MCP.
#
#   pass-guildforge-bootstrap                 # interactive / open Developer Portal
#   pass-guildforge-bootstrap --from-env      # use DISCORD_TOKEN + GUILD_ID from env
#   pass-guildforge-bootstrap --token T --guild ID
#   pass-guildforge-bootstrap --force         # overwrite existing pass entries
#
# After insert: commits+pushes password-store (ntfy wakes peers) and rematerializes
# ~/.config/guildforge/env on this host.
set -euo pipefail

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
TOKEN_PATH="secretspec/shared/default/DISCORD_TOKEN"
GUILD_PATH="secretspec/shared/default/GUILD_ID"
ENV_FILE="${GUILDFORGE_ENV_FILE:-$HOME/.config/guildforge/env}"
FORCE=false
FROM_ENV=false
TOKEN_OPT=""
GUILD_OPT=""
OPEN_PORTAL=true

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
  --from-env) FROM_ENV=true ;;
  --token)
    TOKEN_OPT="${2:?}"
    shift
    ;;
  --guild)
    GUILD_OPT="${2:?}"
    shift
    ;;
  --no-open) OPEN_PORTAL=false ;;
  -h | --help)
    sed -n '2,14p' "$0" | sed 's/^# //; s/^#//'
    exit 0
    ;;
  *) die "unknown arg: $1" ;;
  esac
  shift
done

need pass
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
    git -C "$PASSWORD_STORE_DIR" push >/dev/null 2>&1 ||
      log "warning: pass git push failed (peers will catch up on next sync)"
  fi
}

existing_token="$(pass_get "$TOKEN_PATH")"
existing_guild="$(pass_get "$GUILD_PATH")"

if [[ $FROM_ENV == true ]]; then
  TOKEN_OPT="${DISCORD_TOKEN:-$TOKEN_OPT}"
  GUILD_OPT="${GUILD_ID:-$GUILD_OPT}"
fi

if [[ -z $TOKEN_OPT && -n $existing_token && $FORCE == false ]]; then
  TOKEN_OPT="$existing_token"
  log "using existing pass DISCORD_TOKEN"
fi
if [[ -z $GUILD_OPT && -n $existing_guild && $FORCE == false ]]; then
  GUILD_OPT="$existing_guild"
  log "using existing pass GUILD_ID"
fi

if [[ -z $TOKEN_OPT || -z $GUILD_OPT ]]; then
  if [[ $OPEN_PORTAL == true ]]; then
    log "Opening Discord Developer Portal — create a Bot, copy token + guild ID."
    log "  1. https://discord.com/developers/applications → New Application → Bot → Reset Token"
    log "  2. Enable Privileged Gateway Intent: Server Members Intent"
    log "  3. OAuth2 → URL Generator: scopes bot + applications.commands; perms Manage Channels + Manage Roles"
    log "  4. Invite bot; enable Developer Mode in Discord; right-click server → Copy Server ID"
    if command -v open >/dev/null 2>&1; then
      open "https://discord.com/developers/applications" >/dev/null 2>&1 || true
    elif command -v xdg-open >/dev/null 2>&1; then
      xdg-open "https://discord.com/developers/applications" >/dev/null 2>&1 || true
    fi
  fi
  if [[ -z $TOKEN_OPT ]]; then
    printf 'Discord bot token: ' >&2
    read -r TOKEN_OPT
  fi
  if [[ -z $GUILD_OPT ]]; then
    printf 'Discord guild (server) ID: ' >&2
    read -r GUILD_OPT
  fi
fi

TOKEN_OPT="$(printf '%s' "$TOKEN_OPT" | tr -d '[:space:]')"
GUILD_OPT="$(printf '%s' "$GUILD_OPT" | tr -d '[:space:]')"
[[ -n $TOKEN_OPT ]] || die "empty DISCORD_TOKEN"
[[ -n $GUILD_OPT ]] || die "empty GUILD_ID"
[[ $GUILD_OPT =~ ^[0-9]+$ ]] || die "GUILD_ID must be numeric (enable Developer Mode → Copy Server ID)"

if [[ -n $existing_token && $FORCE == false && $TOKEN_OPT == "$existing_token" &&
  -n $existing_guild && $GUILD_OPT == "$existing_guild" ]]; then
  log "pass already has matching DISCORD_TOKEN + GUILD_ID"
else
  pass_put "$TOKEN_PATH" "$TOKEN_OPT"
  pass_put "$GUILD_PATH" "$GUILD_OPT"
  pass_commit "secretspec: guildforge discord credentials"
fi

# Materialize ~/.config/guildforge/env (and peers via sync).
if command -v pass-materialize >/dev/null 2>&1; then
  pass-materialize || log "warning: pass-materialize failed"
else
  umask 077
  mkdir -p "$(dirname "$ENV_FILE")"
  printf 'DISCORD_TOKEN=%s\nGUILD_ID=%s\n' "$TOKEN_OPT" "$GUILD_OPT" >"$ENV_FILE"
  chmod 600 "$ENV_FILE"
  log "wrote $ENV_FILE"
fi

log "done. Reload MCP / restart IDE to pick up guildforge."
log "Peers: ntfy wake after push → pass-store-sync pull → pass-materialize."
