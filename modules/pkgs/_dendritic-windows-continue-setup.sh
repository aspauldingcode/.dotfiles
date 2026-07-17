#!/usr/bin/env bash
# After Setup's downlevel phase, firmware must boot Windows Boot Manager (not
# systemd-boot) so specialize/OOBE/FirstLogon can finish.
#
# Do NOT WantedBy=multi-user during os-switch — that reboots mid-activation and
# leaves /nix/var/nix/profiles/system on an old generation. Prefer a boot timer.
set -euo pipefail

MOUNT="${DENDRITIC_WINDOWS_MOUNT:?}"
AUTO_REBOOT="${DENDRITIC_WINDOWS_AUTO_REBOOT:-1}"
STATE_DIR="${DENDRITIC_WINDOWS_STATE:-/var/lib/dendritic-windows}"
INSTALLED="$STATE_DIR/installed"
MARKER_WIN="$MOUNT/dendritic-windows-ready"
BT_DIR="$MOUNT/\$Windows.~BT"
SETUPERR="$MOUNT/Windows/Panther/setuperr.log"

log() { echo "dendritic-windows-continue-setup: $*"; }

if [[ -f $INSTALLED ]]; then
  log "installed marker present; skip"
  exit 0
fi
if [[ -e $MARKER_WIN ]]; then
  log "ready marker present; finalize owns the rest"
  exit 0
fi

# Poisoned specialize (e.g. ComputerName >15 chars → 0x80220005). WBM will only
# fail again — bootstrap must wipe + re-run Setup with a fixed Autounattend.
if [[ -f $SETUPERR ]] && grep -qE '80220005|unattend file is not valid' "$SETUPERR"; then
  log "poisoned specialize in $SETUPERR — skip WBM (bootstrap should reset windows)"
  exit 0
fi

in_progress=0
if [[ -d $BT_DIR ]]; then
  in_progress=1
elif [[ -d $MOUNT/Windows && -d $MOUNT/Users ]]; then
  in_progress=1
fi

[[ $in_progress == 1 ]] || {
  log "no in-progress Windows Setup detected; skip"
  exit 0
}

wbm="$(efibootmgr | sed -n 's/^Boot\([0-9A-Fa-f]*\).*Windows Boot Manager.*/\1/p' | head -1)"
if [[ -z $wbm ]]; then
  log "Windows Boot Manager EFI entry missing; cannot continue specialize"
  exit 1
fi

efibootmgr --bootnext "$wbm" || {
  log "efibootmgr --bootnext $wbm failed"
  exit 1
}
log "BootNext=$wbm → Windows Boot Manager (finish specialize/OOBE/FirstLogon)"

mkdir -p "$STATE_DIR"
echo "continue_at=$(date -Iseconds)" >"$STATE_DIR/continue-setup"

if [[ $AUTO_REBOOT == "1" ]]; then
  log "rebooting into Windows Boot Manager now"
  systemctl reboot
else
  log "AUTO_REBOOT=0 — reboot when ready to continue Setup"
fi
