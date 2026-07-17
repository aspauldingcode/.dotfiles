#!/usr/bin/env bash
# After Setup's downlevel phase, Firmware must boot Windows Boot Manager (not
# systemd-boot) so specialize/OOBE/FirstLogon can finish. If NixOS comes back
# first with an in-progress install, BootNext WBM and reboot once.
set -euo pipefail

MOUNT="${DENDRITIC_WINDOWS_MOUNT:?}"
AUTO_REBOOT="${DENDRITIC_WINDOWS_AUTO_REBOOT:-1}"
STATE_DIR="${DENDRITIC_WINDOWS_STATE:-/var/lib/dendritic-windows}"
INSTALLED="$STATE_DIR/installed"
MARKER_WIN="$MOUNT/dendritic-windows-ready"
BT_DIR="$MOUNT/\$Windows.~BT"

log() { echo "dendritic-windows-continue-setup: $*"; }

if [[ -f $INSTALLED ]]; then
  log "installed marker present; skip"
  exit 0
fi
if [[ -e $MARKER_WIN ]]; then
  log "ready marker present; finalize owns the rest"
  exit 0
fi

# In-progress: Setup wrote $Windows.~BT and/or a partial Windows tree, and WBM exists.
in_progress=0
if [[ -d $BT_DIR ]]; then
  in_progress=1
elif [[ -d $MOUNT/Windows && ! -e $MOUNT/Windows/System32/ntoskrnl.exe ]]; then
  # Compact/WIM reparse ntoskrnl may not look like a regular file from Linux.
  in_progress=1
elif [[ -d $MOUNT/Windows && -d $MOUNT/Users ]]; then
  # Partial apply without ready marker — still needs specialize.
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
