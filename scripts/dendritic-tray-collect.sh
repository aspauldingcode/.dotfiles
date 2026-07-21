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

# wg — detect without root. `wg show` needs privileges; Darwin names the
# interface utunN, not "dendritic". Prefer: own WG addr assigned, sysfs/ip link,
# then privileged wg show as last resort.
WG_UP=0
WG_PEER_OK=0
WG_PEER_IP=""
WG_SELF_IP=""
WG_PEER_ID=""
if [[ -f $PEERS_JSON ]]; then
  eval "$(
    python3 -c 'import json,sys
peers=json.load(open(sys.argv[1])); me=sys.argv[2]
self_ip=""; peer_ip=""; peer_id=""
for p in peers:
  pid=p.get("id") or ""
  ip=(p.get("address") or "").split("/")[0]
  if pid==me: self_ip=ip
  elif not peer_ip:
    peer_ip=ip; peer_id=pid
def esc(s):
  return str(s or "").replace("\\","\\\\").replace("\"","\\\"").replace("$","\\$").replace("`","\\`")
print(f"WG_SELF_IP=\"{esc(self_ip)}\"")
print(f"WG_PEER_IP=\"{esc(peer_ip)}\"")
print(f"WG_PEER_ID=\"{esc(peer_id)}\"")
' "$PEERS_JSON" "$HOST" 2>/dev/null || true
  )"
fi
wg_iface_up() {
  local iface="$1"
  [[ -n $iface ]] || return 1
  if [[ -d /sys/class/net/$iface ]]; then
    # Linux: present + IFF_UP (ip/sysfs work unprivileged)
    if command -v ip >/dev/null 2>&1; then
      ip -o link show "$iface" 2>/dev/null | grep -q '<[^>]*\bUP\b' && return 0
    fi
    [[ -e /sys/class/net/$iface/flags ]] && return 0
  fi
  return 1
}
wg_addr_present() {
  local ip="$1"
  [[ -n $ip ]] || return 1
  if command -v ip >/dev/null 2>&1; then
    ip -br addr 2>/dev/null | grep -Fq "$ip" && return 0
  fi
  if command -v ifconfig >/dev/null 2>&1; then
    ifconfig 2>/dev/null | grep -Eq "inet (addr:)?${ip}([[:space:]]|$)" && return 0
  fi
  return 1
}
if wg_iface_up "$WG_IFACE" || wg_addr_present "$WG_SELF_IP"; then
  WG_UP=1
elif command -v wg >/dev/null 2>&1 && wg show "$WG_IFACE" >/dev/null 2>&1; then
  WG_UP=1
fi
if [[ -n $WG_PEER_IP ]]; then
  if ping -c1 -W2 "$WG_PEER_IP" >/dev/null 2>&1 || ping -c1 -t2 "$WG_PEER_IP" >/dev/null 2>&1; then
    WG_PEER_OK=1
  fi
fi
export WG_UP WG_PEER_OK WG_PEER_IP WG_PEER_ID WG_SELF_IP

# android / oneplus6t — live adb + converge status file
ANDROID_STATUS="${ANDROID_CONVERGE_STATUS:-${HOME}/.cache/android-converge.status}"
ANDROID_LIVE=0
ANDROID_SERIAL=""
ANDROID_TRANSPORT=""
if command -v adb >/dev/null 2>&1; then
  eval "$(
    python3 - <<'PY'
import subprocess
r = subprocess.run(["adb", "devices"], capture_output=True, text=True)
serial = ""
transport = ""
for line in (r.stdout or "").splitlines()[1:]:
    parts = line.split()
    if len(parts) >= 2 and parts[1] == "device":
        serial = parts[0]
        transport = "wireless" if ":" in serial else "usb"
        break
def esc(s):
    return str(s or "").replace("\\", "\\\\").replace('"', '\\"').replace("$", "\\$").replace("`", "\\`")
print(f'ANDROID_LIVE={"1" if serial else "0"}')
print(f'ANDROID_SERIAL="{esc(serial)}"')
print(f'ANDROID_TRANSPORT="{esc(transport)}"')
PY
  )"
fi
export ANDROID_STATUS ANDROID_LIVE ANDROID_SERIAL ANDROID_TRANSPORT

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

# Live overlays: mark self online at local HEAD; mark WG-reachable peer online.
peer_id = os.environ.get("WG_PEER_ID") or ""
peer_ok = os.environ.get("WG_PEER_OK") == "1"
self_rev = ""
if dotfiles and (Path(dotfiles) / ".git").exists():
    r = subprocess.run(
        ["git", "-C", dotfiles, "rev-parse", "--short=8", "HEAD"],
        capture_output=True, text=True,
    )
    if r.returncode == 0:
        self_rev = r.stdout.strip()
by_host = {h["host"]: h for h in fleet if h.get("host")}
if host:
    me = by_host.get(host) or {"host": host, "platform": "", "flake_rev": "", "status": "online", "seen_at": now}
    me["status"] = "online"
    me["seen_at"] = now
    if self_rev:
        me["flake_rev"] = self_rev
    by_host[host] = me
if peer_id and peer_ok:
    peer = by_host.get(peer_id) or {
        "host": peer_id,
        "platform": "",
        "flake_rev": "",
        "status": "online",
        "seen_at": now,
    }
    # Only trust a published flake_rev when the heartbeat itself is fresh.
    # JSON may still say status=online with an old seen_at; age that explicitly.
    seen = peer.get("seen_at") or ""
    heartbeat_fresh = False
    try:
        ts = datetime.fromisoformat(seen.replace("Z", "+00:00"))
        heartbeat_fresh = (now_dt - ts).total_seconds() <= 1800
    except Exception:
        pass
    peer["status"] = "online"
    peer["seen_at"] = now
    if not heartbeat_fresh:
        peer["flake_rev"] = ""
    by_host[peer_id] = peer
fleet = list(by_host.values())

# Android / OnePlus 6T converge + reachability
android_path = Path(os.environ.get("ANDROID_STATUS") or "")
android = {
    "device": "oneplus6t",
    "reachable": False,
    "transport": "",
    "serial": "",
    "state": "",
    "message": "",
    "lease_holder": "",
    "last_ok_at": "",
    "config_rev": "",
    "controller": "",
    "updated_at": "",
    "status_age_secs": None,
    "present": False,
}
if android_path.is_file():
    try:
        ad = json.loads(android_path.read_text())
        android.update({
            "device": ad.get("device") or android["device"],
            "reachable": bool(ad.get("reachable")),
            "transport": ad.get("transport") or "",
            "serial": ad.get("serial") or "",
            "state": ad.get("state") or "",
            "message": ad.get("message") or "",
            "lease_holder": ad.get("lease_holder") or "",
            "last_ok_at": ad.get("last_ok_at") or "",
            "config_rev": ad.get("config_rev") or "",
            "controller": ad.get("controller") or "",
            "updated_at": ad.get("updated_at") or "",
            "present": True,
        })
        try:
            age = max(0, int(time.time() - android_path.stat().st_mtime))
            android["status_age_secs"] = age
        except Exception:
            pass
    except Exception:
        pass
if os.environ.get("ANDROID_LIVE") == "1":
    android["reachable"] = True
    android["present"] = True
    if os.environ.get("ANDROID_SERIAL"):
        android["serial"] = os.environ["ANDROID_SERIAL"]
    if os.environ.get("ANDROID_TRANSPORT"):
        android["transport"] = os.environ["ANDROID_TRANSPORT"]
# Live phone → overlay fleet badge host online
phone = android.get("device") or "oneplus6t"
if phone in by_host:
    android["present"] = True
if android.get("reachable"):
    ph = by_host.get(phone) or {
        "host": phone,
        "platform": "android",
        "flake_rev": "",
        "status": "online",
        "seen_at": now,
    }
    ph["status"] = "online"
    ph["seen_at"] = now
    ph["platform"] = "android"
    if android.get("config_rev"):
        ph["flake_rev"] = android["config_rev"]
    by_host[phone] = ph
    android["present"] = True
    fleet = list(by_host.values())
elif phone not in by_host and android.get("present"):
    by_host[phone] = {
        "host": phone,
        "platform": "android",
        "flake_rev": android.get("config_rev") or "",
        "status": "offline",
        "seen_at": android.get("updated_at") or "",
    }
    fleet = list(by_host.values())

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
    "android": android,
    "flake": flake,
    "job": job,
}
tmp = status.with_suffix(".tmp")
tmp.write_text(json.dumps(out, indent=2) + "\n")
tmp.replace(status)
print(f"dendritic-tray-collect: wrote {status}")
PY
