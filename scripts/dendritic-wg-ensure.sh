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
  # Prefer explicit peer id (HM wrapper sets this; root activation may lack hostname on PATH).
  if [[ -n ${WG_PEER_ID:-} ]]; then
    printf '%s' "$WG_PEER_ID"
    return 0
  fi
  local h
  h="$(
    { hostname -s 2>/dev/null || hostname 2>/dev/null || uname -n 2>/dev/null; } | cut -d. -f1
  )"
  h="$(printf '%s' "$h" | tr '[:upper:]' '[:lower:]')"
  case "$h" in
  mba | sliceanddice) printf '%s' "$h" ;;
  *) die "unknown host '$h' — set WG_PEER_ID=mba|sliceanddice" ;;
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

# Host peers (mba/sliceanddice) + optional clients (iphone, …).
# Controllers peer with every other host and every enrolled client.
PEER_TABLE_FILE="${STATE_DIR}/peers.tsv"
eval "$(
  python3 - "$PEERS_JSON" "$PEER_ID" "$PEER_TABLE_FILE" <<'PY'
import json, sys, shlex
peers = json.load(open(sys.argv[1]))
me_id = sys.argv[2]
table_path = sys.argv[3]
by = {p["id"]: p for p in peers}
if me_id not in by:
    raise SystemExit(f"peer id {me_id!r} not in peers JSON")
me = by[me_id]
role = me.get("role") or "host"
if role == "client":
    raise SystemExit(f"{me_id!r} is a client — use dendritic-connect-device wireguard")
hosts = [p for p in peers if (p.get("role") or "host") != "client"]
clients = [p for p in peers if (p.get("role") or "host") == "client"]
if me_id not in {p["id"] for p in hosts}:
    raise SystemExit(f"{me_id!r} must be a host peer")
others = [p for p in hosts if p["id"] != me_id]
if not others:
    raise SystemExit("need at least one other host peer")
primary = others[0]

def emit(k, v):
    print(f"{k}={shlex.quote(str(v))}")

emit("ME_ID", me["id"])
emit("ME_ADDR", me["address"])
emit("ME_PORT", me["listenPort"])
emit("PEER_ID", primary["id"])
emit("PEER_COUNT", str(len(others) + len(clients)))
# TSV: id role addr port mdns
with open(table_path, "w", encoding="utf-8") as fh:
    for p in others + clients:
        r = p.get("role") or "host"
        mdns = p.get("mdns") or (f"{p['id']}.local" if r != "client" else "")
        port = p.get("listenPort") or ""
        fh.write(f"{p['id']}\t{r}\t{p['address']}\t{port}\t{mdns}\n")
emit("PEER_TABLE_FILE", table_path)
PY
)"

# Uppercase via tr (macOS /bin/bash is 3.2 — no ${var^^}).
PRIV_KEY="$(normalize_opt "$(pass_get "WG_PRIVATE_KEY_$(printf '%s' "$ME_ID" | tr '[:lower:]' '[:upper:]')")")"
[[ -n $PRIV_KEY ]] || die "missing WG_PRIVATE_KEY for $ME_ID — run: nix run .#pass-wg-bootstrap"

PSK="$(file_get "${XDG_CONFIG_HOME:-$HOME/.config}/dendritic/wireguard/psk")"
[[ -n $PSK ]] || PSK="$(normalize_opt "$(pass_get WG_PSK)")"

{
  echo "[Interface]"
  echo "Address = ${ME_ADDR}"
  echo "ListenPort = ${ME_PORT}"
  echo "PrivateKey = ${PRIV_KEY}"
  while IFS=$'\t' read -r pid prole paddr pport pmdns; do
    [[ -n $pid ]] || continue
    up="$(printf '%s' "$pid" | tr '[:lower:]' '[:upper:]')"
    pub="$(file_get "${XDG_CONFIG_HOME:-$HOME/.config}/dendritic/wireguard/keys/${pid}.public")"
    [[ -n $pub ]] || pub="$(normalize_opt "$(pass_get "WG_PUBLIC_KEY_${up}")")"
    if [[ -z $pub ]]; then
      if [[ $prole == "client" ]]; then
        log "skip client $pid — no public key yet (Connect device… → WireGuard)"
        continue
      fi
      die "missing WG_PUBLIC_KEY for $pid — run pass-wg-bootstrap + pass-materialize"
    fi
    peer_ip="${paddr%%/*}"
    echo ""
    echo "[Peer]"
    echo "PublicKey = ${pub}"
    if [[ -n $PSK ]]; then
      echo "PresharedKey = ${PSK}"
    fi
    echo "AllowedIPs = ${peer_ip}/32"
    if [[ $prole != "client" ]]; then
      endpoint="$(file_get "${XDG_CONFIG_HOME:-$HOME/.config}/dendritic/wireguard/endpoints/${pid}")"
      [[ -n $endpoint ]] || endpoint="$(normalize_opt "$(pass_get "WG_ENDPOINT_${up}")")"
      if [[ -z $endpoint && -n $pmdns ]]; then
        mdns_ip="$(resolve_mdns "$pmdns" || true)"
        if [[ -n ${mdns_ip:-} && -n $pport ]]; then
          endpoint="${mdns_ip}:${pport}"
          log "peer $pid endpoint via mDNS/LAN (${pmdns})"
        fi
      elif [[ -n $endpoint ]]; then
        log "peer $pid endpoint from pass WG_ENDPOINT_${pid}"
      else
        log "peer $pid — omit Endpoint (keepalive only)"
      fi
      if [[ -n ${endpoint:-} ]]; then
        echo "Endpoint = ${endpoint}"
      fi
      echo "PersistentKeepalive = ${KEEPALIVE}"
    fi
  done <"$PEER_TABLE_FILE"
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

# Prefer the root dendritic helper (set-and-forget) over sudo/osascript.
dendritic_bin() {
  if [[ -n ${DENDRITIC_BIN:-} && -x ${DENDRITIC_BIN} ]]; then
    printf '%s' "$DENDRITIC_BIN"
    return 0
  fi
  command -v dendritic 2>/dev/null || true
}

helper_install_conf() {
  local bin
  bin="$(dendritic_bin)"
  [[ -n $bin ]] || return 1
  "$bin" wg install-conf --iface "$IFACE" "$USER_CONF"
}

helper_reload_iface() {
  local bin
  bin="$(dendritic_bin)"
  [[ -n $bin ]] || return 1
  "$bin" wg down --iface "$IFACE" 2>/dev/null || true
  "$bin" wg up --iface "$IFACE"
}

# Install system conf (wg-quick unit / launchd).
install_conf() {
  if [[ -w $CONF_DIR ]] || [[ $(id -u) -eq 0 ]]; then
    mkdir -p "$CONF_DIR"
    install -m 0600 "$USER_CONF" "$CONF_PATH"
    return 0
  fi
  if helper_install_conf; then
    return 0
  fi
  if sudo_cmd mkdir -p "$CONF_DIR" && sudo_cmd install -m 0600 "$USER_CONF" "$CONF_PATH"; then
    return 0
  fi
  log "could not install $CONF_PATH (helper/sudo) — user conf at $USER_CONF"
  return 1
}

wg_quick_bin() {
  command -v wg-quick || die "wg-quick not on PATH"
}

reload_iface() {
  local wq
  wq="$(wg_quick_bin)"
  if helper_reload_iface; then
    return 0
  fi
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
  return 1
}

install_conf
if [[ ${WG_ENSURE_NO_UP:-0} == 1 ]]; then
  log "wrote $CONF_PATH (WG_ENSURE_NO_UP=1 — skip up)"
  exit 0
fi

reload_iface
log "interface $IFACE up (primary=$PEER_ID peers=${PEER_COUNT:-?})"
echo "$PEER_ID" >"${STATE_DIR}/peer"
date -u +%Y-%m-%dT%H:%M:%SZ >"${STATE_DIR}/last-ensure"
