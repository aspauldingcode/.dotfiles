#!/usr/bin/env bash
# One-time (or --force) WireGuard key bootstrap into pass SecretSpec.
#
#   nix run .#pass-wg-bootstrap
#   nix run .#pass-wg-bootstrap -- --force          # regenerate all keys + PSK
#   nix run .#pass-wg-bootstrap -- --status
#
# Writes (Alex-only pass paths):
#   WG_PRIVATE_KEY_{MBA,SLICEANDDICE}
#   WG_PUBLIC_KEY_{MBA,SLICEANDDICE}
#   WG_PSK
# Leaves WG_ENDPOINT_* / WG_HOME empty until: pass-wg-set-home
#
# Then on each host: pass-materialize && dendritic-wg-ensure
set -euo pipefail

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
PEERS_JSON="${WG_PEERS_JSON:-$DOTFILES_ROOT/home/wireguard-peers.json}"
FORCE=false
DO_STATUS=false

export PASSWORD_STORE_DIR

die() {
  echo "pass-wg-bootstrap: error: $*" >&2
  exit 1
}
log() { echo "pass-wg-bootstrap: $*"; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing $1"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
  --force | -f) FORCE=true ;;
  --status) DO_STATUS=true ;;
  -h | --help)
    sed -n '2,16p' "$0" | sed 's/^# //; s/^#//'
    exit 0
    ;;
  *) die "unknown arg: $1" ;;
  esac
  shift
done

need pass
need git
need wg
need python3
[[ -r $PEERS_JSON ]] || die "missing $PEERS_JSON"

pass_exists() {
  pass show "secretspec/shared/default/$1" >/dev/null 2>&1
}

pass_put() {
  local key="$1" value="$2"
  printf '%s\n' "$value" | pass insert -e -f "secretspec/shared/default/$key" >/dev/null
  log "wrote secretspec/shared/default/$key"
}

pass_commit() {
  git -C "$PASSWORD_STORE_DIR" add -A
  if git -C "$PASSWORD_STORE_DIR" status --porcelain | grep -q .; then
    git -C "$PASSWORD_STORE_DIR" -c user.name="pass-store-sync" \
      -c user.email="pass-store-sync@localhost" commit -m "$1" >/dev/null 2>&1 || true
    git -C "$PASSWORD_STORE_DIR" push >/dev/null 2>&1 ||
      log "warning: pass push failed (ntfy sync may retry)"
  fi
}

peer_ids() {
  python3 - "$PEERS_JSON" <<'PY'
import json, sys
for p in json.load(open(sys.argv[1])):
    print(p["id"])
PY
}

if $DO_STATUS; then
  echo "wireguard (pass-backed)"
  for id in $(peer_ids); do
    up="$(printf '%s' "$id" | tr '[:lower:]' '[:upper:]')"
    echo "  $id private: $(pass_exists "WG_PRIVATE_KEY_$up" && echo true || echo false)"
    echo "  $id public:  $(pass_exists "WG_PUBLIC_KEY_$up" && echo true || echo false)"
    ep="$(pass show "secretspec/shared/default/WG_ENDPOINT_$up" 2>/dev/null | head -n1 | tr -d '[:space:]' || true)"
    case "$ep" in "" | "-" | none | NONE) ep_set=false ;; *) ep_set=true ;; esac
    echo "  $id endpoint set: $ep_set"
  done
  echo "  PSK: $(pass_exists WG_PSK && echo true || echo false)"
  home="$(pass show secretspec/shared/default/WG_HOME 2>/dev/null | head -n1 | tr -d '[:space:]' || true)"
  case "$home" in "" | "-" | none | NONE) home="(unset — LAN/mDNS or pass-wg-set-home)" ;; esac
  echo "  WG_HOME: $home"
  exit 0
fi

changed=false
for id in $(peer_ids); do
  up="$(printf '%s' "$id" | tr '[:lower:]' '[:upper:]')"
  priv_key="WG_PRIVATE_KEY_$up"
  pub_key="WG_PUBLIC_KEY_$up"
  if pass_exists "$priv_key" && ! $FORCE; then
    log "keep existing $priv_key (pass --force to rotate)"
    continue
  fi
  priv="$(wg genkey)"
  pub="$(printf '%s' "$priv" | wg pubkey)"
  pass_put "$priv_key" "$priv"
  pass_put "$pub_key" "$pub"
  changed=true
done

if ! pass_exists WG_PSK || $FORCE; then
  # 32-byte base64 PSK
  psk="$(wg genpsk)"
  pass_put WG_PSK "$psk"
  changed=true
fi

# Ensure endpoint/home keys exist (placeholder "-" = unset; never commit real IPs).
for id in $(peer_ids); do
  up="$(printf '%s' "$id" | tr '[:lower:]' '[:upper:]')"
  if ! pass_exists "WG_ENDPOINT_$up"; then
    pass_put "WG_ENDPOINT_$up" "-"
    changed=true
  fi
done
if ! pass_exists WG_HOME; then
  pass_put WG_HOME "-"
  changed=true
fi

if $changed; then
  pass_commit "bootstrap: WireGuard keys (dendritic)"
  log "done — on each host: pass pull && pass-materialize && dendritic-wg-ensure"
  log "when leaving a device on Bubbles: pass-wg-set-home --peer <id> --endpoint HOST:51820"
else
  log "nothing to do (keys present). Use --force to rotate."
fi
