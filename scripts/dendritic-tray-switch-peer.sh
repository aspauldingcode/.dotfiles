#!/usr/bin/env bash
# Switch peer host over WireGuard SSH (confirmed tray action).
# Requires WG up + peer reachable. Never force-push.
set -euo pipefail

STATUS="${DENDRITIC_TRAY_STATUS:-${HOME}/.cache/dendritic-tray.status}"
LOCK="${HOME}/.cache/dendritic-tray.lock"
LOG="${HOME}/.cache/dendritic-tray-sync.log"
DOTFILES="${DOTFILES_ROOT:-${DENDRITIC_DOTFILES:-}}"
if [[ -z "$DOTFILES" ]]; then
  if [[ -d /etc/nix-darwin/.dotfiles/.git ]]; then DOTFILES=/etc/nix-darwin/.dotfiles
  elif [[ -d /etc/nixos/.dotfiles/.git ]]; then DOTFILES=/etc/nixos/.dotfiles
  else DOTFILES="$(git rev-parse --show-toplevel 2>/dev/null || true)"; fi
fi
PEERS_JSON="${WG_PEERS_JSON:-${DOTFILES}/home/wireguard-peers.json}"
HOST="$(hostname -s 2>/dev/null || hostname | cut -d. -f1)"
WG_IFACE="${WG_IFACE:-dendritic}"
COLLECT="${DENDRITIC_TRAY_COLLECT:-dendritic-tray-collect}"

mkdir -p "$(dirname "$LOG")"
exec >>"$LOG" 2>&1
echo "==== dendritic-tray-switch-peer $(date -u +%Y-%m-%dT%H:%M:%SZ) from=$HOST ===="

write_job() {
  local state="$1" msg="$2"
  python3 - "$STATUS" "$state" "$msg" <<'PY'
import json,sys
from pathlib import Path
from datetime import datetime,timezone
p=Path(sys.argv[1]); state=sys.argv[2]; msg=sys.argv[3]
d={}
if p.is_file():
  try: d=json.loads(p.read_text())
  except Exception: d={}
d["updated_at"]=datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
d["job"]={"state":state,"message":msg}
p.write_text(json.dumps(d,indent=2)+"\n")
PY
}

if ! mkdir "$LOCK" 2>/dev/null; then
  write_job "error" "tray job already running"
  exit 0
fi
echo "$$" >"$LOCK/pid"
trap 'rm -rf "$LOCK"' EXIT

if ! command -v wg >/dev/null 2>&1 || ! wg show "$WG_IFACE" >/dev/null 2>&1; then
  write_job "error" "wg $WG_IFACE down"
  exit 1
fi

peer_id="$(python3 -c 'import json,sys
peers=json.load(open(sys.argv[1])); me=sys.argv[2]
for p in peers:
  if p.get("id")!=me: print(p["id"]); break' "$PEERS_JSON" "$HOST")"
peer_ip="$(python3 -c 'import json,sys
peers=json.load(open(sys.argv[1])); me=sys.argv[2]
for p in peers:
  if p.get("id")!=me: print(p.get("address","").split("/")[0]); break' "$PEERS_JSON" "$HOST")"
ssh_user="$([[ "$peer_id" == "mba" ]] && echo 8amps || echo alex)"
remote_root="$([[ "$peer_id" == "mba" ]] && echo /etc/nix-darwin/.dotfiles || echo /etc/nixos/.dotfiles)"

write_job "switching" "ping $peer_id ($peer_ip)"
if ! ping -c1 -W3 "$peer_ip" >/dev/null 2>&1 && ! ping -c1 -t3 "$peer_ip" >/dev/null 2>&1; then
  write_job "error" "peer $peer_id unreachable"
  exit 1
fi

write_job "switching" "ssh $peer_id pull + nh switch"
ssh -o BatchMode=yes -o ConnectTimeout=10 "${ssh_user}@${peer_ip}" bash -s -- "$remote_root" "$peer_id" <<'REMOTE'
set -euo pipefail
ROOT="$1"
HOST_ID="$2"
cd "$ROOT"
git fetch origin --prune
git checkout development
git pull --rebase --autostash origin development
if [[ "$(uname -s)" == "Darwin" ]]; then
  nh darwin switch -H "$HOST_ID" || nh darwin switch
else
  nh os switch -H "$HOST_ID" || nh os switch
fi
REMOTE

write_job "idle" "peer $peer_id switched"
if command -v "$COLLECT" >/dev/null 2>&1; then "$COLLECT" || true; fi
echo "dendritic-tray-switch-peer: done"
