#!/usr/bin/env bash
# Collect dendritic fleet/theme/llm/wg/flake status for pass-store-tray.
# Writes ~/.cache/dendritic-tray.status (JSON). No secrets.
set -euo pipefail

STATUS="${DENDRITIC_TRAY_STATUS:-${HOME}/.cache/dendritic-tray.status}"
DOTFILES="${DOTFILES_ROOT:-${DENDRITIC_DOTFILES:-}}"
if [[ -z $DOTFILES ]]; then
  if [[ -d /etc/nix-darwin/.dotfiles/.git ]]; then
    DOTFILES=/etc/nix-darwin/.dotfiles
  elif [[ -d /etc/nixos/.dotfiles/.git ]]; then
    DOTFILES=/etc/nixos/.dotfiles
  else
    DOTFILES="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  fi
fi
WG_IFACE="${WG_IFACE:-dendritic}"
FLEET_JSON="${DENDRITIC_FLEET_STATUS_JSON:-${DOTFILES}/docs/fleet-status.json}"
PEERS_JSON="${WG_PEERS_JSON:-${DOTFILES}/home/wireguard-peers.json}"
HOST="$(hostname -s 2>/dev/null || hostname | cut -d. -f1)"
export STATUS DOTFILES WG_IFACE FLEET_JSON PEERS_JSON HOST

mkdir -p "$(dirname "$STATUS")"

# theme
THEME_VARIANT=""
THEME_PHASE=""
THEME_WALLPAPER=""
if command -v dendritic-appearance >/dev/null 2>&1; then
  if dendritic-appearance status >/tmp/dendritic-appearance-status.json 2>/dev/null; then
    eval "$(
      python3 - <<'PY'
import json
d=json.load(open("/tmp/dendritic-appearance-status.json"))
phase=d.get("phase")
if isinstance(phase, dict) and phase:
    name=next(iter(phase.keys()))
else:
    name=str(phase or "")
o=d.get("observation") or {}
def esc(s):
    return str(s or "").replace("\\","\\\\").replace('"','\\"').replace("$","\\$").replace("`","\\`")
print(f'THEME_PHASE="{esc(name)}"')
print(f'THEME_VARIANT="{esc(o.get("colors_variant") or o.get("wallpaper_variant"))}"')
print(f'THEME_WALLPAPER="{esc(o.get("wallpaper_name"))}"')
PY
    )"
  fi
fi
if [[ -z $THEME_VARIANT && -f "${HOME}/.colors.toml" ]]; then
  THEME_VARIANT="$(awk -F= '/^(variant|polarity)/{gsub(/[ "]/,"",$2); print $2; exit}' "${HOME}/.colors.toml" || true)"
fi
export THEME_VARIANT THEME_PHASE THEME_WALLPAPER

# llm
LLM_OK=0
LLM_MODELS=0
if curl -fsS --max-time 2 http://127.0.0.1:11434/api/tags -o /tmp/dendritic-ollama-tags.json 2>/dev/null; then
  LLM_OK=1
  LLM_MODELS="$(python3 -c 'import json; print(len(json.load(open("/tmp/dendritic-ollama-tags.json")).get("models") or []))' 2>/dev/null || echo 0)"
fi
export LLM_OK LLM_MODELS

# wg
WG_UP=0
WG_PEER_OK=0
WG_PEER_IP=""
if command -v wg >/dev/null 2>&1 && wg show "$WG_IFACE" >/dev/null 2>&1; then
  WG_UP=1
fi
if [[ -f $PEERS_JSON ]]; then
  WG_PEER_IP="$(python3 -c 'import json,sys; peers=json.load(open(sys.argv[1])); me=sys.argv[2]
for p in peers:
  if p.get("id")!=me:
    print(p.get("address","").split("/")[0]); break' "$PEERS_JSON" "$HOST" 2>/dev/null || true)"
fi
if [[ -n $WG_PEER_IP ]]; then
  if ping -c1 -W2 "$WG_PEER_IP" >/dev/null 2>&1 || ping -c1 -t2 "$WG_PEER_IP" >/dev/null 2>&1; then
    WG_PEER_OK=1
  fi
fi
export WG_UP WG_PEER_OK WG_PEER_IP

python3 <<'PY'
import json, os, subprocess, time
from datetime import datetime, timezone
from pathlib import Path

status = Path(os.environ["STATUS"])
dotfiles = os.environ.get("DOTFILES") or ""
fleet_json = os.environ.get("FLEET_JSON") or ""
host = os.environ.get("HOST") or ""
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

fleet = []
if fleet_json and Path(fleet_json).is_file():
    d = json.loads(Path(fleet_json).read_text())
    now_dt = datetime.now(timezone.utc)
    for h in d.get("hosts") or []:
        seen = h.get("seen_at") or ""
        st = h.get("status") or "offline"
        try:
            ts = datetime.fromisoformat(seen.replace("Z", "+00:00"))
            age = (now_dt - ts).total_seconds()
            if age <= 1800:
                st = "online"
            elif age <= 86400:
                st = "stale"
            else:
                st = "offline"
        except Exception:
            pass
        fleet.append({
            "host": h.get("host", ""),
            "platform": h.get("platform", ""),
            "flake_rev": h.get("flake_rev", ""),
            "status": st,
            "seen_at": seen,
        })

flake = {
    "root": dotfiles,
    "rev": "",
    "dirty": False,
    "ahead": 0,
    "behind": 0,
    "nixpkgs_age_days": None,
}
if dotfiles and (Path(dotfiles) / ".git").exists():
    def git(*args):
        r = subprocess.run(["git", "-C", dotfiles, *args], capture_output=True, text=True)
        return r.stdout.strip() if r.returncode == 0 else ""
    flake["rev"] = git("rev-parse", "--short", "HEAD")
    flake["dirty"] = bool(git("status", "--porcelain"))
    ab = git("rev-list", "--left-right", "--count", "HEAD...origin/development")
    if ab:
        parts = ab.replace("\t", " ").split()
        if len(parts) >= 2:
            flake["ahead"] = int(parts[0])
            flake["behind"] = int(parts[1])
    lock = Path(dotfiles) / "flake.lock"
    if lock.is_file():
        try:
            nodes = json.loads(lock.read_text()).get("nodes") or {}
            lm = ((nodes.get("nixpkgs") or {}).get("locked") or {}).get("lastModified")
            if lm:
                flake["nixpkgs_age_days"] = max(0, int((time.time() - int(lm)) / 86400))
        except Exception:
            pass

job = {"state": "idle", "message": ""}
if status.is_file():
    try:
        prev = json.loads(status.read_text())
        job = prev.get("job") or job
    except Exception:
        pass
lock_dir = Path.home() / ".cache" / "dendritic-tray.lock"
if job.get("state") not in ("idle", "error") and not lock_dir.is_dir():
    job = {"state": "idle", "message": ""}

out = {
    "schema": 1,
    "updated_at": now,
    "host": host,
    "theme": {
        "variant": os.environ.get("THEME_VARIANT") or "",
        "phase": os.environ.get("THEME_PHASE") or "",
        "wallpaper": os.environ.get("THEME_WALLPAPER") or "",
    },
    "llm": {
        "ok": os.environ.get("LLM_OK") == "1",
        "models": int(os.environ.get("LLM_MODELS") or 0),
    },
    "wg": {
        "iface": os.environ.get("WG_IFACE") or "dendritic",
        "up": os.environ.get("WG_UP") == "1",
        "peer_ip": os.environ.get("WG_PEER_IP") or "",
        "peer_ok": os.environ.get("WG_PEER_OK") == "1",
    },
    "fleet": fleet,
    "flake": flake,
    "job": job,
}
tmp = status.with_suffix(".tmp")
tmp.write_text(json.dumps(out, indent=2) + "\n")
tmp.replace(status)
print(f"dendritic-tray-collect: wrote {status}")
PY
