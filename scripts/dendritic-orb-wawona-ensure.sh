#!/usr/bin/env bash
# Create/start the OrbStack NixOS machine and apply flake#orb-wawona.
# SSH is OrbStack's localhost proxy (127.0.0.1:32222 via Host orb) — no
# manual port forwards. Mac flake is visible in the guest at /mnt/mac/…
set -euo pipefail

MACHINE="${ORB_WAWONA_MACHINE:-wawona}"
LINUX_USER="${ORB_WAWONA_USER:-alex}"
IMAGE="${ORB_WAWONA_IMAGE:-nixos}"
MEMORY_MIB="${ORB_WAWONA_MEMORY_MIB:-8192}"
CPUS="${ORB_WAWONA_CPUS:-4}"
FLAKE_ATTR="${ORB_WAWONA_FLAKE_ATTR:-orb-wawona}"
WWN_MCP_GUEST="${ORB_WAWONA_WWN_MCP:-/mnt/mac/Users/8amps/Wawona/wwn-mcp}"

die() {
  echo "dendritic-orb-wawona: error: $*" >&2
  exit 1
}
log() { echo "dendritic-orb-wawona: $*"; }

need() {
  command -v "$1" >/dev/null 2>&1 || die "missing $1 — rebuild mba with dendritic.apps.orbstack.enable"
}

need orb
need orbctl

if ! orbctl list >/dev/null 2>&1; then
  app="$(command -v orbctl)"
  prefix="$(cd "$(dirname "$app")/.." && pwd)"
  if [[ -d $prefix/Applications/OrbStack.app ]]; then
    log "opening nixpkgs OrbStack.app"
    open "$prefix/Applications/OrbStack.app" || true
  fi
  for _ in $(seq 1 30); do
    orbctl list >/dev/null 2>&1 && break
    sleep 2
  done
  orbctl list >/dev/null 2>&1 || die "OrbStack daemon did not come up"
fi

orb config set app.start_at_login true 2>/dev/null || true

list_names() { orbctl list 2>/dev/null | awk '{print $1}'; }

if list_names | grep -qx "$MACHINE"; then
  log "machine ${MACHINE} already exists"
elif list_names | grep -qx nixos && [[ $MACHINE == wawona ]]; then
  log "renaming leftover machine nixos → ${MACHINE}"
  orb rename nixos "$MACHINE"
else
  log "creating ${IMAGE} machine ${MACHINE} (user ${LINUX_USER})"
  orb create --user "$LINUX_USER" "$IMAGE" "$MACHINE"
fi

orb start "$MACHINE" 2>/dev/null || true
orb config set "machine.${MACHINE}.memory_mib" "$MEMORY_MIB" 2>/dev/null || true
orb config set "machine.${MACHINE}.cpu" "$CPUS" 2>/dev/null || true
orb config set "machine.${MACHINE}.username" "$LINUX_USER" 2>/dev/null || true

# New machines use LINUX_USER; existing ones may still only have OrbStack's
# default (_8amps when the Mac account starts with a digit). Prefer alex.
guest_login="$LINUX_USER"
if ! orb -m "$MACHINE" -u "$LINUX_USER" true >/dev/null 2>&1; then
  if orb -m "$MACHINE" -u _8amps true >/dev/null 2>&1; then
    log "guest login ${LINUX_USER} not ready — applying as _8amps"
    guest_login=_8amps
  fi
fi

log "applying flake #${FLAKE_ATTR} inside ${MACHINE} as ${guest_login}"
orb -m "$MACHINE" -u "$guest_login" sudo env \
  FLAKE_ATTR="$FLAKE_ATTR" \
  WWN_MCP_GUEST="$WWN_MCP_GUEST" \
  bash -s <<'GUEST'
set -euo pipefail
attr="$FLAKE_ATTR"
mcp="$WWN_MCP_GUEST"
flake=""
for cand in \
  /mnt/mac/private/etc/nix-darwin/.dotfiles \
  /mnt/mac/etc/nix-darwin/.dotfiles \
  /etc/nixos/.dotfiles; do
  if [[ -f $cand/flake.nix ]]; then
    flake="$cand"
    break
  fi
done
if [[ -z $flake ]]; then
  echo "dendritic-orb-wawona: flake not mounted under /mnt/mac — copy it to /etc/nixos/.dotfiles" >&2
  exit 1
fi

# Keep OrbStack's injected HTTPS CA across flake switch (lives in stock configuration.nix).
if [[ -f /etc/nixos/configuration.nix ]] && [[ ! -f /etc/nixos/orbstack-ca.nix ]]; then
  {
    echo '{ ... }: {'
    awk '
      /security\.pki\.certificates = \[/ {grab=1}
      grab {print}
      grab && /\];/ {exit}
    ' /etc/nixos/configuration.nix
    echo '}'
  } >/etc/nixos/orbstack-ca.nix
fi

echo "dendritic-orb-wawona: guest flake=$flake#$attr"
extra=()
if [[ -f $mcp/flake.nix ]]; then
  extra+=(--override-input wwn-mcp "$mcp")
fi
# pathExists /etc/nixos/*.nix is impure inside a flake eval.
# OrbStack LXC has no logind inhibitors; switchInhibitors parses empty JSON.
export NIXOS_NO_CHECK=1
exec nixos-rebuild switch --impure --flake "$flake#$attr" "${extra[@]}"
GUEST

log "done — ssh wawona   (or: ssh ${LINUX_USER}@${MACHINE}@orb)"
log "waypipe: waypipe ssh wawona -- niri"
log "         waypipe ssh wawona -- ghostty"
