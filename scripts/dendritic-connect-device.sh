#!/usr/bin/env bash
# Guided 3rd-party device setup for the dendritic tray (iPhone WireGuard / pass).
#
#   dendritic-connect-device guide                 # open HTML how-to
#   dendritic-connect-device wireguard [--device iphone] [--rotate]
#   dendritic-connect-device pass-guide            # pass-for-iOS steps + open QtPass note
#
# Tray spawns these with no TTY — progress goes to dendritic-tray.status job + notify.
set -euo pipefail

STATUS="${DENDRITIC_TRAY_STATUS:-${HOME}/.cache/dendritic-tray.status}"
LOG="${HOME}/.cache/dendritic-connect-device.log"
OUT_DIR="${HOME}/.cache/dendritic-connect-device"
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
PEERS_JSON="${WG_PEERS_JSON:-$DOTFILES/home/wireguard-peers.json}"
PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
export PASSWORD_STORE_DIR DOTFILES_ROOT="$DOTFILES"

DEVICE="iphone"
ROTATE=false
MODE=""

mkdir -p "$(dirname "$LOG")" "$OUT_DIR"
exec >>"$LOG" 2>&1

die() {
  echo "dendritic-connect-device: error: $*" >&2
  write_job "error" "$*"
  notify "Connect device" "$*"
  exit 1
}
log() { echo "dendritic-connect-device: $*"; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing $1"; }

write_job() {
  local state="$1" msg="$2"
  python3 - "$STATUS" "$state" "$msg" <<'PY'
import json, sys
from pathlib import Path
from datetime import datetime, timezone
p = Path(sys.argv[1]); state = sys.argv[2]; msg = sys.argv[3]
d = {}
if p.is_file():
    try: d = json.loads(p.read_text())
    except Exception: d = {}
d.setdefault("schema", 1)
d["updated_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
d["job"] = {"state": state, "message": msg}
p.write_text(json.dumps(d, indent=2) + "\n")
PY
}

notify() {
  local title="$1" body="$2"
  if command -v dendritic >/dev/null 2>&1; then
    dendritic notify "$title" "$body" 2>/dev/null || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$body" 2>/dev/null || true
  fi
}

open_path() {
  local path="$1"
  if [[ "$(uname -s)" == Darwin ]]; then
    open "$path" 2>/dev/null || true
  else
    xdg-open "$path" >/dev/null 2>&1 || true
  fi
}

pass_put() {
  local key="$1" value="$2"
  printf '%s\n' "$value" | pass insert -e -f "secretspec/shared/default/$key" >/dev/null
}

pass_get() {
  pass show "secretspec/shared/default/$1" 2>/dev/null | head -n1 | tr -d '[:space:]' || true
}

pass_commit_push() {
  local msg="$1"
  git -C "$PASSWORD_STORE_DIR" add -A
  if git -C "$PASSWORD_STORE_DIR" status --porcelain | grep -q .; then
    git -C "$PASSWORD_STORE_DIR" -c user.name="pass-store-sync" \
      -c user.email="pass-store-sync@localhost" commit -m "$msg" >/dev/null 2>&1 || true
    git -C "$PASSWORD_STORE_DIR" push >/dev/null 2>&1 || log "warning: pass push failed"
  fi
}

resolve_mdns() {
  local name="$1" ip=""
  if command -v dscacheutil >/dev/null 2>&1; then
    ip="$(dscacheutil -q host -a name "$name" 2>/dev/null | awk '/ip_address/{print $2; exit}')"
  fi
  if [[ -z $ip ]] && command -v getent >/dev/null 2>&1; then
    ip="$(getent hosts "$name" 2>/dev/null | awk '{print $1; exit}')"
  fi
  if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf '%s' "$ip"
  fi
}

# Pick the host the phone should dial: WG_HOME, else this machine if it is a host.
hub_peer() {
  local home me
  home="$(pass_get WG_HOME)"
  case "$home" in "" | "-" | none | NONE) home="" ;; esac
  me="$(hostname -s 2>/dev/null || hostname | cut -d. -f1 | tr '[:upper:]' '[:lower:]')"
  if [[ -n $home ]]; then
    printf '%s' "$home"
  else
    printf '%s' "$me"
  fi
}

write_guide_html() {
  local out="$OUT_DIR/setup-guide.html"
  cat >"$out" <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Dendritic — connect a device</title>
<style>
  :root { color-scheme: light dark; --fg: #1a1a1a; --muted: #555; --bg: #f7f5f0; --card: #fff; --accent: #0b6e4f; }
  @media (prefers-color-scheme: dark) {
    :root { --fg: #f0eee8; --muted: #a8a49a; --bg: #161512; --card: #22201c; --accent: #6fcf9a; }
  }
  body { margin: 0; font: 16px/1.5 ui-sans-serif, system-ui, sans-serif; color: var(--fg); background: var(--bg); }
  main { max-width: 40rem; margin: 0 auto; padding: 2rem 1.25rem 4rem; }
  h1 { font-size: 1.6rem; letter-spacing: -0.02em; margin: 0 0 0.35rem; }
  h2 { font-size: 1.15rem; margin: 2rem 0 0.5rem; }
  p, li { color: var(--muted); }
  .lead { color: var(--fg); font-size: 1.05rem; }
  section { background: var(--card); border-radius: 12px; padding: 1.1rem 1.25rem; margin: 1rem 0; }
  code, kbd { font: 0.9em/1.4 ui-monospace, Menlo, monospace; }
  ol { padding-left: 1.2rem; }
  a { color: var(--accent); }
  .note { font-size: 0.92rem; }
</style>
</head>
<body>
<main>
  <h1>Connect a device</h1>
  <p class="lead">Use the menubar <strong>Connect device</strong> menu for the interactive steps. This page is the full guide.</p>

  <section>
    <h2>1. WireGuard (iPhone)</h2>
    <ol>
      <li>On the Mac/NixOS host, choose <strong>Connect device → WireGuard for iPhone…</strong>.</li>
      <li>Install <a href="https://apps.apple.com/app/wireguard/id1441195209">WireGuard</a> from the App Store.</li>
      <li>Scan the QR that opens (or import the <code>.conf</code> beside it under <code>~/.cache/dendritic-connect-device/</code>).</li>
      <li>On <em>both</em> mba and sliceanddice run <code>dendritic-wg-ensure</code> (or wait for pass-materialize) so hosts accept the phone peer.</li>
      <li>Toggle the tunnel on. You should reach <code>10.87.0.1</code> / <code>10.87.0.2</code>.</li>
    </ol>
    <p class="note">Away from home: set a home endpoint with <code>pass-wg-set-home</code>, then export the QR again so the phone dials your public/DDNS host.</p>
  </section>

  <section>
    <h2>2. Passwords (not QtPass on iPhone)</h2>
    <p><strong>QtPass is desktop-only</strong> (macOS / Linux). On iPhone use <a href="https://github.com/mssun/passforios">passforios</a> (“Pass”) with the same GPG key + git password store.</p>
    <ol>
      <li>Choose <strong>Connect device → Pass store for iPhone…</strong> for a short checklist.</li>
      <li>Export your GPG secret key once from a trusted host (keep it offline).</li>
      <li>In Pass for iOS: add the git remote for your private password-store and import the GPG key.</li>
      <li>On the desktop, keep using <strong>Open QtPass</strong> in the menubar — edits sync via pass-store-sync.</li>
    </ol>
  </section>

  <section>
    <h2>3. OnePlus 6T (already enrolled)</h2>
    <p class="note">Android LineageOS is managed by nix-android / android-converge — not this wizard. See <code>docs/nix-android.md</code>.</p>
  </section>
</main>
</body>
</html>
HTML
  printf '%s\n' "$out"
}

cmd_guide() {
  write_job "connecting" "Opening setup guide…"
  local html
  html="$(write_guide_html)"
  open_path "$html"
  write_job "idle" "Setup guide opened"
  notify "Connect device" "Setup guide opened"
}

cmd_pass_guide() {
  write_job "connecting" "Pass store for iPhone…"
  local html="$OUT_DIR/pass-iphone.html"
  cat >"$html" <<'HTML'
<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Pass store on iPhone</title>
<style>
  body { font: 16px/1.5 ui-sans-serif, system-ui, sans-serif; max-width: 36rem; margin: 2rem auto; padding: 0 1rem; }
  h1 { font-size: 1.4rem; } li { margin: 0.4rem 0; } code { font-family: ui-monospace, Menlo, monospace; font-size: 0.9em; }
</style></head><body>
<h1>Pass store on iPhone</h1>
<p><strong>QtPass does not run on iOS.</strong> Use the desktop menubar → <em>Open QtPass</em> on mba/sliceanddice. On the phone:</p>
<ol>
  <li>Install <a href="https://apps.apple.com/app/passwords/id1586435171">Pass for iOS</a> (passforios) or a compatible Pass client.</li>
  <li>Export your GPG secret key from a trusted host (one-time). Import it into the iOS app.</li>
  <li>Clone / add the same private git remote as <code>~/.password-store</code> (SSH key or HTTPS token in the app).</li>
  <li>Pull on the phone after desktop edits; pass-store-sync keeps hosts aligned.</li>
</ol>
<p>Never put the GPG passphrase or store remote into this public flake.</p>
</body></html>
HTML
  open_path "$html"
  # Also open QtPass so the user sees the desktop side of the story.
  if [[ "$(uname -s)" == Darwin ]]; then
    open -a QtPass 2>/dev/null || true
  else
    command -v qtpass >/dev/null 2>&1 && qtpass >/dev/null 2>&1 &
  fi
  write_job "idle" "Pass iPhone guide opened"
  notify "Connect device" "Pass guide opened — QtPass is desktop-only"
}

cmd_wireguard() {
  need pass
  need wg
  need python3
  [[ -r $PEERS_JSON ]] || die "missing $PEERS_JSON"

  write_job "connecting" "WireGuard QR for ${DEVICE}…"
  notify "Connect device" "Preparing WireGuard QR for ${DEVICE}"

  local up priv pub hub hub_up hub_pub hub_port hub_addr hub_mdns endpoint psk conf qr
  up="$(printf '%s' "$DEVICE" | tr '[:lower:]' '[:upper:]')"

  # Validate device is a client peer.
  python3 - "$PEERS_JSON" "$DEVICE" <<'PY' || die "device not a client peer in wireguard-peers.json"
import json, sys
peers = json.load(open(sys.argv[1]))
dev = sys.argv[2]
for p in peers:
    if p["id"] == dev and (p.get("role") or "host") == "client":
        raise SystemExit(0)
raise SystemExit(1)
PY

  eval "$(
    python3 - "$PEERS_JSON" "$DEVICE" <<'PY'
import json, sys, shlex
peers = {p["id"]: p for p in json.load(open(sys.argv[1]))}
d = peers[sys.argv[2]]
print(f"CLIENT_ADDR={shlex.quote(d['address'])}")
PY
  )"

  priv="$(pass_get "WG_PRIVATE_KEY_${up}")"
  pub="$(pass_get "WG_PUBLIC_KEY_${up}")"
  if [[ -z $priv || -z $pub || $ROTATE == true ]]; then
    log "generating keypair for $DEVICE"
    priv="$(wg genkey)"
    pub="$(printf '%s' "$priv" | wg pubkey)"
    pass_put "WG_PRIVATE_KEY_${up}" "$priv"
    pass_put "WG_PUBLIC_KEY_${up}" "$pub"
    pass_commit_push "wireguard: enroll client ${DEVICE}"
  fi

  # Materialize public key for hosts (best-effort).
  mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/dendritic/wireguard/keys"
  printf '%s\n' "$pub" >"${XDG_CONFIG_HOME:-$HOME/.config}/dendritic/wireguard/keys/${DEVICE}.public"
  chmod 600 "${XDG_CONFIG_HOME:-$HOME/.config}/dendritic/wireguard/keys/${DEVICE}.public"

  hub="$(hub_peer)"
  hub_up="$(printf '%s' "$hub" | tr '[:lower:]' '[:upper:]')"
  hub_pub="$(pass_get "WG_PUBLIC_KEY_${hub_up}")"
  [[ -n $hub_pub ]] || die "missing hub public key for $hub — run pass-wg-bootstrap"

  eval "$(
    python3 - "$PEERS_JSON" "$hub" <<'PY'
import json, sys, shlex
peers = {p["id"]: p for p in json.load(open(sys.argv[1]))}
h = peers.get(sys.argv[2]) or {}
print(f"HUB_PORT={shlex.quote(str(h.get('listenPort') or 51820))}")
print(f"HUB_MDNS={shlex.quote(h.get('mdns') or (sys.argv[2] + '.local'))}")
print(f"HUB_ADDR={shlex.quote(h.get('address') or '')}")
PY
  )"

  endpoint="$(pass_get "WG_ENDPOINT_${hub_up}")"
  case "$endpoint" in "" | "-" | none | NONE) endpoint="" ;; esac
  if [[ -z $endpoint ]]; then
    local ip
    ip="$(resolve_mdns "$HUB_MDNS" || true)"
    if [[ -n ${ip:-} ]]; then
      endpoint="${ip}:${HUB_PORT}"
      log "endpoint via mDNS ${HUB_MDNS} → (redacted)"
    else
      die "no endpoint for hub $hub — set pass-wg-set-home or join Bubbles LAN"
    fi
  fi

  psk="$(pass_get WG_PSK)"
  conf="$OUT_DIR/${DEVICE}.conf"
  {
    echo "# dendritic WireGuard client — ${DEVICE}"
    echo "# Scan QR or import in WireGuard iOS/Android. Do not commit."
    echo "[Interface]"
    echo "PrivateKey = ${priv}"
    echo "Address = ${CLIENT_ADDR}"
    echo "DNS = 1.1.1.1"
    echo ""
    echo "[Peer]"
    echo "PublicKey = ${hub_pub}"
    if [[ -n $psk ]]; then
      echo "PresharedKey = ${psk}"
    fi
    echo "AllowedIPs = 10.87.0.0/24"
    echo "Endpoint = ${endpoint}"
    echo "PersistentKeepalive = 25"
  } >"$conf"
  chmod 600 "$conf"

  qr="$OUT_DIR/${DEVICE}-wg.png"
  if command -v qrencode >/dev/null 2>&1; then
    qrencode -o "$qr" -t PNG -s 8 <"$conf"
    open_path "$qr"
  else
    log "qrencode missing — opening .conf instead"
    open_path "$conf"
  fi

  # Refresh local host so it accepts the client peer immediately.
  if command -v dendritic-wg-ensure >/dev/null 2>&1; then
    WG_SUDO_INTERACTIVE=0 dendritic-wg-ensure || log "warning: dendritic-wg-ensure failed"
  fi

  write_job "idle" "WireGuard QR ready for ${DEVICE}"
  notify "Connect device" "Scan QR in WireGuard app (${DEVICE}). Re-run ensure on the other host."
  log "wrote $conf and $qr"
}

usage() {
  sed -n '2,12p' "$0" | sed 's/^# //; s/^#//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  guide | pass-guide | wireguard)
    MODE="$1"
    ;;
  --device)
    shift
    DEVICE="${1:-}"
    [[ -n $DEVICE ]] || die "--device needs a value"
    ;;
  --rotate) ROTATE=true ;;
  -h | --help)
    usage
    exit 0
    ;;
  *) die "unknown arg: $1" ;;
  esac
  shift
done

[[ -n $MODE ]] || MODE="guide"

case "$MODE" in
guide) cmd_guide ;;
pass-guide) cmd_pass_guide ;;
wireguard) cmd_wireguard ;;
*) die "unknown mode: $MODE" ;;
esac
