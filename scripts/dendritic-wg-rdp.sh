#!/usr/bin/env bash
# Open RDP to the WireGuard peer (macrdp on mba, lamco on sliceanddice).
#
#   dendritic-wg-rdp              # peer from peers JSON
#   dendritic-wg-rdp sliceanddice
#   dendritic-wg-rdp mba
set -euo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
PEERS_JSON="${WG_PEERS_JSON:-$DOTFILES_ROOT/home/wireguard-peers.json}"

die() {
  echo "dendritic-wg-rdp: error: $*" >&2
  exit 1
}

host_id() {
  local h
  h="$(hostname -s 2>/dev/null || hostname | cut -d. -f1)"
  printf '%s' "$(printf '%s' "$h" | tr '[:upper:]' '[:lower:]')"
}

TARGET="${1:-}"
ME="$(host_id)"
if [[ -z $TARGET ]]; then
  TARGET="$(
    python3 - "$PEERS_JSON" "$ME" <<'PY'
import json, sys
me = sys.argv[2]
peers = json.load(open(sys.argv[1]))
others = [p["id"] for p in peers if p["id"] != me]
print(others[0] if others else "")
PY
  )"
fi
[[ -n $TARGET ]] || die "no peer target"

eval "$(
  python3 - "$PEERS_JSON" "$TARGET" <<'PY'
import json, sys, shlex
peer = next(p for p in json.load(open(sys.argv[1])) if p["id"] == sys.argv[2])
ip = peer["address"].split("/")[0]
print(f"IP={shlex.quote(ip)}")
print(f"PORT={shlex.quote(str(peer.get('rdpPort', 3389)))}")
PY
)"

if command -v xfreerdp >/dev/null 2>&1; then
  exec xfreerdp "/v:${IP}:${PORT}" /cert:ignore /network:auto
elif command -v wlfreerdp >/dev/null 2>&1; then
  exec wlfreerdp "/v:${IP}:${PORT}" /cert:ignore /network:auto
elif command -v open >/dev/null 2>&1 && [[ "$(uname -s)" == Darwin ]]; then
  # Microsoft Remote Desktop URL scheme when installed
  exec open "rdp://full%20address=s:${IP}:${PORT}"
else
  die "install freerdp (xfreerdp) or Microsoft Remote Desktop; target ${IP}:${PORT}"
fi
