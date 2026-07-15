#!/usr/bin/env bash
# After Windows specialize: clear BootNext and ensure systemd-boot is first in BootOrder.
set -euo pipefail

MOUNT="${DENDRITIC_WINDOWS_MOUNT:?}"
MARKER_WIN="$MOUNT/dendritic-windows-ready"
STATE_DIR=/var/lib/dendritic-windows

if [[ ! -e $MARKER_WIN ]]; then
  echo "dendritic-windows-finalize: Windows ready marker not present; skip"
  exit 0
fi

mkdir -p "$STATE_DIR"

# Drop any leftover one-shot Windows BootNext.
efibootmgr --delete-bootnext 2>/dev/null || true

# Prefer systemd-boot (Linux Boot Manager / systemd-boot) first.
mapfile -t order < <(efibootmgr | sed -n 's/^BootOrder: //p' | tr ',' '\n')
sys_boot="$(efibootmgr | sed -n 's/^Boot\([0-9A-Fa-f]*\).*systemd-boot.*/\1/p' | head -1)"
if [[ -z $sys_boot ]]; then
  sys_boot="$(efibootmgr | sed -n 's/^Boot\([0-9A-Fa-f]*\).*Linux Boot Manager.*/\1/p' | head -1)"
fi
if [[ -z $sys_boot ]]; then
  echo "dendritic-windows-finalize: systemd-boot Boot#### not found" >&2
  touch "$STATE_DIR/boot-order-restored"
  exit 0
fi

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
touch "$STATE_DIR/boot-order-restored"
