#!/usr/bin/env bash
# After Windows specialize: clear BootNext, ensure systemd-boot-first, mark installed.
# wininstall Setup media partition is left in place (no re-bootstrap).
set -euo pipefail

MOUNT="${DENDRITIC_WINDOWS_MOUNT:?}"
MARKER_WIN="$MOUNT/dendritic-windows-ready"
STATE_DIR=/var/lib/dendritic-windows

if [[ ! -e $MARKER_WIN ]]; then
  echo "dendritic-windows-finalize: Windows ready marker not present; skip"
  exit 0
fi

mkdir -p "$STATE_DIR"

efibootmgr --delete-bootnext 2>/dev/null || true

mapfile -t order < <(efibootmgr | sed -n 's/^BootOrder: //p' | tr ',' '\n')
sys_boot="$(efibootmgr | sed -n 's/^Boot\([0-9A-Fa-f]*\).*systemd-boot.*/\1/p' | head -1)"
if [[ -z $sys_boot ]]; then
  sys_boot="$(efibootmgr | sed -n 's/^Boot\([0-9A-Fa-f]*\).*Linux Boot Manager.*/\1/p' | head -1)"
fi
if [[ -n $sys_boot ]]; then
  new_order=("$sys_boot")
  for e in "${order[@]}"; do
    [[ $e == "$sys_boot" ]] && continue
    new_order+=("$e")
  done
  joined="$(
    IFS=,
    echo "${new_order[*]}"
  )"
  efibootmgr -o "$joined"
  echo "dendritic-windows-finalize: BootOrder -> $joined"
else
  echo "dendritic-windows-finalize: systemd-boot Boot#### not found" >&2
fi

echo "finalize $(date -Iseconds)" >"$STATE_DIR/installed"
touch "$STATE_DIR/boot-order-restored"
echo "dendritic-windows-finalize: installed marker written; wininstall media kept"
