#!/usr/bin/env bash
# Build /etc/wireguard/dendritic.conf from pass/SecretSpec + wireguard-peers.json
# and bring the interface up (wg-quick).
#
# Endpoint resolution order per peer:
#   1. pass WG_ENDPOINT_<PEER> (remote / DDNS / public — never committed to git)
#   2. mDNS <peer>.local when resolvable (home Bubbles / LAN)
#   3. omit Endpoint (wait for peer) — PersistentKeepalive keeps NAT mappings
#
# Private key is fetched only for this host (never materialized for both peers).
set -euo pipefail

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
PEERS_JSON="${WG_PEERS_JSON:-$DOTFILES_ROOT/home/wireguard-peers.json}"
SECRETSPEC_TOML="${SECRETSPEC_TOML:-$DOTFILES_ROOT/home/secretspec.toml}"
IFACE="${WG_IFACE:-dendritic}"
CONF_DIR="${WG_CONF_DIR:-/etc/wireguard}"
CONF_PATH="${CONF_DIR}/${IFACE}.conf"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dendritic-wireguard"
USER_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/dendritic/wireguard/${IFACE}.conf"
KEEPALIVE="${WG_PERSISTENT_KEEPALIVE:-25}"

export PASSWORD_STORE_DIR

die() {
  echo "dendritic-wg: error: $*" >&2
  exit 1
}
log() { echo "dendritic-wg: $*" >&2; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing $1"; }

need python3
need wg
[[ -r $PEERS_JSON ]] || die "missing peers JSON: $PEERS_JSON"

host_id() {
  local h
  h="$(hostname -s 2>/dev/null || hostname | cut -d. -f1)"
  h="$(printf '%s' "$h" | tr '[:upper:]' '[:lower:]')"
  case "$h" in
  mba | sliceanddice) printf '%s' "$h" ;;
  *)
    if [[ -n ${WG_PEER_ID:-} ]]; then
      printf '%s' "$WG_PEER_ID"
    else
      die "unknown host '$h' — set WG_PEER_ID=mba|sliceanddice"
    fi
    ;;
  esac
}

pass_get() {
  # Split locals: `local key="$1" path="...$key"` leaves $key unbound under set -u.
  local key path val
  key="$1"
  path="secretspec/shared/default/$key"
  val=""
  if command -v secretspec >/dev/null 2>&1 && [[ -r $SECRETSPEC_TOML ]]; then
    val="$(secretspec get -f "$SECRETSPEC_TOML" "$key" 2>/dev/null || true)"
  fi
  if [[ -z $val || $val == placeholder ]]; then
    val="$(pass show "$path" 2>/dev/null | head -n1 | tr -d '[:space:]' || true)"
  fi
  printf '%s' "$val"
}

normalize_opt() {
  # "-" / "none" / "unset" placeholders mean empty (pass cannot store truly empty easily).
  local v="$1"
  case "$v" in
  "" | "-" | none | NONE | unset | UNSET) printf '' ;;
  *) printf '%s' "$v" ;;
  esac
}

file_get() {
  local f="$1" v=""
  [[ -r $f ]] || {
    printf ''
    return 0
  }
  v="$(head -n1 "$f" | tr -d '[:space:]')"
  normalize_opt "$v"
}

resolve_mdns() {
  local name="$1" ip=""
  # Prefer getent / dscacheutil / dig — never log the result (fleet threat model).
  if command -v dscacheutil >/dev/null 2>&1; then
    ip="$(dscacheutil -q host -a name "$name" 2>/dev/null | awk '/ip_address/{print $2; exit}')"
  fi
  if [[ -z $ip ]] && command -v getent >/dev/null 2>&1; then
    ip="$(getent hosts "$name" 2>/dev/null | awk '{print $1; exit}')"
  fi
  if [[ -z $ip ]] && command -v dig >/dev/null 2>&1; then
    ip="$(dig +short "$name" 2>/dev/null | head -n1)"
  fi
  # Basic IPv4 sanity
  if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf '%s' "$ip"
  fi
}

PEER_ID="$(host_id)"
mkdir -p "$STATE_DIR" "$(dirname "$USER_CONF")"
chmod 700 "$(dirname "$USER_CONF")" 2>/dev/null || true

eval "$(
  python3 - "$PEERS_JSON" "$PEER_ID" <<'PY'
import json, sys, shlex
peers = json.load(open(sys.argv[1]))
me_id = sys.argv[2]
by = {p["id"]: p for p in peers}
if me_id not in by:
    raise SystemExit(f"peer id {me_id!r} not in peers JSON")
others = [p for p in peers if p["id"] != me_id]
if len(others) != 1:
    raise SystemExit("dendritic-wg currently expects exactly two peers")
me, peer = by[me_id], others[0]
def emit(k, v):
    print(f"{k}={shlex.quote(str(v))}")
emit("ME_ID", me["id"])
emit("ME_ADDR", me["address"])
emit("ME_PORT", me["listenPort"])
emit("PEER_ID", peer["id"])
emit("PEER_ADDR", peer["address"])
emit("PEER_PORT", peer["listenPort"])
emit("PEER_MDNS", peer.get("mdns") or f"{peer['id']}.local")
# AllowedIPs = peer host route only (not full tunnel)
peer_ip = peer["address"].split("/")[0]
emit("PEER_ALLOWED", f"{peer_ip}/32")
PY
)"

# Uppercase via tr (macOS /bin/bash is 3.2 — no ${var^^}).
PRIV_KEY="$(normalize_opt "$(pass_get "WG_PRIVATE_KEY_$(printf '%s' "$ME_ID" | tr '[:lower:]' '[:upper:]')")")"
[[ -n $PRIV_KEY ]] || die "missing WG_PRIVATE_KEY for $ME_ID — run: nix run .#pass-wg-bootstrap"

PEER_PUB="$(file_get "${XDG_CONFIG_HOME:-$HOME/.config}/dendritic/wireguard/keys/${PEER_ID}.public")"
[[ -n $PEER_PUB ]] || PEER_PUB="$(normalize_opt "$(pass_get "WG_PUBLIC_KEY_$(printf '%s' "$PEER_ID" | tr '[:lower:]' '[:upper:]')")")"
[[ -n $PEER_PUB ]] || die "missing WG_PUBLIC_KEY for $PEER_ID — run pass-wg-bootstrap + pass-materialize"

PSK="$(file_get "${XDG_CONFIG_HOME:-$HOME/.config}/dendritic/wireguard/psk")"
[[ -n $PSK ]] || PSK="$(normalize_opt "$(pass_get WG_PSK)")"

ENDPOINT_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/dendritic/wireguard/endpoints/${PEER_ID}"
ENDPOINT="$(file_get "$ENDPOINT_FILE")"
[[ -n $ENDPOINT ]] || ENDPOINT="$(normalize_opt "$(pass_get "WG_ENDPOINT_$(printf '%s' "$PEER_ID" | tr '[:lower:]' '[:upper:]')")")"

if [[ -z $ENDPOINT ]]; then
  mdns_ip="$(resolve_mdns "$PEER_MDNS" || true)"
  if [[ -n ${mdns_ip:-} ]]; then
    ENDPOINT="${mdns_ip}:${PEER_PORT}"
    log "peer endpoint via mDNS/LAN (${PEER_MDNS})"
  else
    log "no remote endpoint + peer mDNS unresolved — omit Endpoint (keepalive only)"
  fi
else
  log "peer endpoint from pass WG_ENDPOINT_${PEER_ID}"
fi

{
  echo "[Interface]"
  echo "Address = ${ME_ADDR}"
  echo "ListenPort = ${ME_PORT}"
  echo "PrivateKey = ${PRIV_KEY}"
  echo ""
  echo "[Peer]"
  echo "PublicKey = ${PEER_PUB}"
  if [[ -n $PSK ]]; then
    echo "PresharedKey = ${PSK}"
  fi
  echo "AllowedIPs = ${PEER_ALLOWED}"
  if [[ -n ${ENDPOINT:-} ]]; then
    echo "Endpoint = ${ENDPOINT}"
  fi
  echo "PersistentKeepalive = ${KEEPALIVE}"
} >"${USER_CONF}.tmp"
chmod 0600 "${USER_CONF}.tmp"
mv -f "${USER_CONF}.tmp" "$USER_CONF"

# Non-interactive sudo during HM activation (no TTY / Touch ID hang).
sudo_cmd() {
  if [[ $(id -u) -eq 0 ]]; then
    "$@"
    return
  fi
  if [[ -t 0 && -t 2 && ${WG_SUDO_INTERACTIVE:-1} == 1 ]]; then
    sudo "$@"
  else
    sudo -n "$@" 2>/dev/null
  fi
}

# Install system conf (wg-quick unit / launchd).
install_conf() {
  if [[ -w $CONF_DIR ]] || [[ $(id -u) -eq 0 ]]; then
    mkdir -p "$CONF_DIR"
    install -m 0600 "$USER_CONF" "$CONF_PATH"
    return 0
  fi
  if sudo_cmd mkdir -p "$CONF_DIR" && sudo_cmd install -m 0600 "$USER_CONF" "$CONF_PATH"; then
    return 0
  fi
  if [[ "$(uname -s)" == Darwin ]] && command -v osascript >/dev/null 2>&1; then
    # Single admin dialog: mkdir + install (agents lack sudo -n / Touch ID TTY).
    if osascript -e "do shell script \"mkdir -p $(printf '%q' "$CONF_DIR") && install -m 0600 $(printf '%q' "$USER_CONF") $(printf '%q' "$CONF_PATH")\" with administrator privileges" 2>/dev/null; then
      return 0
    fi
  fi
  log "could not install $CONF_PATH (sudo) — user conf at $USER_CONF"
  return 1
}

wg_quick_bin() {
  command -v wg-quick || die "wg-quick not on PATH"
}

reload_iface() {
  local wq
  wq="$(wg_quick_bin)"
  if command -v systemctl >/dev/null 2>&1; then
    if systemctl cat "wg-quick-${IFACE}.service" >/dev/null 2>&1; then
      sudo_cmd systemctl restart "wg-quick-${IFACE}.service" && return 0
    fi
  fi
  if sudo_cmd "$wq" down "$IFACE" 2>/dev/null || true; then
    :
  fi
  if sudo_cmd "$wq" up "$IFACE"; then
    return 0
  fi
  if [[ "$(uname -s)" == Darwin ]] && command -v osascript >/dev/null 2>&1; then
    osascript -e "do shell script \"$(printf '%q' "$wq") down $(printf '%q' "$IFACE") 2>/dev/null || true; $(printf '%q' "$wq") up $(printf '%q' "$IFACE")\" with administrator privileges" 2>/dev/null
    return $?
  fi
  return 1
}

install_conf
if [[ ${WG_ENSURE_NO_UP:-0} == 1 ]]; then
  log "wrote $CONF_PATH (WG_ENSURE_NO_UP=1 — skip up)"
  exit 0
fi

reload_iface
log "interface $IFACE up (peer=$PEER_ID)"
echo "$PEER_ID" >"${STATE_DIR}/peer"
date -u +%Y-%m-%dT%H:%M:%SZ >"${STATE_DIR}/last-ensure"
