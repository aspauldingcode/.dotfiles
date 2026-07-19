#!/usr/bin/env bash
# Declare which peer is left at home (Bubbles) and its remote Endpoint.
#
#   pass-wg-set-home --peer sliceanddice --endpoint EXAMPLE.COM:51820
#   pass-wg-set-home --peer mba --endpoint 1.2.3.4:51820
#   pass-wg-set-home --clear              # clear home + endpoints (LAN/mDNS only)
#   pass-wg-set-home --status
#
# Traveler dials WG_ENDPOINT_<home>. Home peer can omit traveler Endpoint
# (PersistentKeepalive from traveler punches NAT).
#
# Endpoints stay in private pass — never commit public IPs to the flake.
set -euo pipefail

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
PEERS_JSON="${WG_PEERS_JSON:-$DOTFILES_ROOT/home/wireguard-peers.json}"
export PASSWORD_STORE_DIR

PEER=""
ENDPOINT=""
CLEAR=false
DO_STATUS=false

die() {
  echo "pass-wg-set-home: error: $*" >&2
  exit 1
}
log() { echo "pass-wg-set-home: $*"; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing $1"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
  --peer)
    PEER="${2:?}"
    shift
    ;;
  --endpoint)
    ENDPOINT="${2:?}"
    shift
    ;;
  --clear) CLEAR=true ;;
  --status) DO_STATUS=true ;;
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
need python3

valid_peer() {
  python3 - "$PEERS_JSON" "$1" <<'PY'
import json, sys
ids = {p["id"] for p in json.load(open(sys.argv[1]))}
raise SystemExit(0 if sys.argv[2] in ids else 1)
PY
}

pass_put() {
  printf '%s\n' "$2" | pass insert -e -f "secretspec/shared/default/$1" >/dev/null
}

pass_commit() {
  git -C "$PASSWORD_STORE_DIR" add -A
  if git -C "$PASSWORD_STORE_DIR" status --porcelain | grep -q .; then
    git -C "$PASSWORD_STORE_DIR" -c user.name="pass-store-sync" \
      -c user.email="pass-store-sync@localhost" commit -m "$1" >/dev/null 2>&1 || true
    git -C "$PASSWORD_STORE_DIR" push >/dev/null 2>&1 ||
      log "warning: pass push failed"
  fi
}

if $DO_STATUS; then
  home="$(pass show secretspec/shared/default/WG_HOME 2>/dev/null | head -n1 || true)"
  echo "WG_HOME=${home:-"(unset)"}"
  for id in $(python3 -c 'import json;print(" ".join(p["id"] for p in json.load(open("'"$PEERS_JSON"'"))) )'); do
    up="$(printf '%s' "$id" | tr '[:lower:]' '[:upper:]')"
    ep="$(pass show "secretspec/shared/default/WG_ENDPOINT_$up" 2>/dev/null | head -n1 || true)"
    echo "WG_ENDPOINT_$up=$([[ -n $ep ]] && echo '(set)' || echo '(empty)')"
  done
  exit 0
fi

if $CLEAR; then
  pass_put WG_HOME "-"
  for id in $(python3 -c 'import json;print(" ".join(p["id"] for p in json.load(open("'"$PEERS_JSON"'"))) )'); do
    up="$(printf '%s' "$id" | tr '[:lower:]' '[:upper:]')"
    pass_put "WG_ENDPOINT_$up" "-"
  done
  pass_commit "wireguard: clear WG_HOME + endpoints"
  log "cleared — peers use Bubbles/LAN mDNS when available"
  exit 0
fi

[[ -n $PEER ]] || die "need --peer <mba|sliceanddice>"
[[ -n $ENDPOINT ]] || die "need --endpoint HOST:PORT (or --clear)"
valid_peer "$PEER" || die "unknown peer '$PEER' (see home/wireguard-peers.json)"
[[ $ENDPOINT == *:* ]] || die "endpoint must be HOST:PORT"

up="$(printf '%s' "$PEER" | tr '[:lower:]' '[:upper:]')"
pass_put WG_HOME "$PEER"
pass_put "WG_ENDPOINT_$up" "$ENDPOINT"
# Clear the traveler endpoint so home waits for inbound (NAT punch from traveler).
for id in $(python3 -c 'import json;print(" ".join(p["id"] for p in json.load(open("'"$PEERS_JSON"'"))) )'); do
  if [[ $id != "$PEER" ]]; then
    oup="$(printf '%s' "$id" | tr '[:lower:]' '[:upper:]')"
    pass_put "WG_ENDPOINT_$oup" "-"
  fi
done
pass_commit "wireguard: WG_HOME=$PEER"
log "home=$PEER endpoint=(set in pass) — traveler: pass-materialize && dendritic-wg-ensure"
log "router: forward UDP ${ENDPOINT##*:} → home peer LAN IP (not stored in git)"
