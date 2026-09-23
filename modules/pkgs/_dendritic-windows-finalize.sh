#!/usr/bin/env bash
# After Windows specialize: clear BootNext, put the NixOS bootloader first,
# mark installed. wininstall Setup media partition is left in place.
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

# Prefer GRUB (NixOS-boot / GRUBX64). Fall back to leftover systemd-boot /
# Linux Boot Manager so older generations still work. Match Boot#### only —
# BootCurrent would otherwise look like a BootC* entry.
bootnum() {
  local line="$1" id
  id="${line#Boot}"
  printf '%s\n' "${id%%[^0-9A-Fa-f]*}"
}

pick_nixos_boot() {
  local line grub="" sys=""
  while IFS= read -r line; do
    [[ $line == Boot[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]* ]] || continue
    case "$line" in
    *Windows*) continue ;;
    *NIXOS-BOOT* | *NixOS-boot* | *nixos-boot* | *GRUBX64* | *grubx64.efi* | *NixOS* | *GRUB*)
      grub="$(bootnum "$line")"
      ;;
    *systemd-boot* | *"Linux Boot Manager"*)
      [[ -n $sys ]] || sys="$(bootnum "$line")"
      ;;
    esac
  done < <(efibootmgr)
  if [[ -n $grub ]]; then
    printf '%s\n' "$grub"
    return 0
  fi
  if [[ -n $sys ]]; then
    printf '%s\n' "$sys"
    return 0
  fi
  return 1
}

mapfile -t order < <(efibootmgr | sed -n 's/^BootOrder: //p' | tr ',' '\n')
sys_boot="$(pick_nixos_boot || true)"
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
  echo "dendritic-windows-finalize: NixOS/GRUB/systemd-boot Boot#### not found" >&2
fi

echo "finalize $(date -Iseconds)" >"$STATE_DIR/installed"
touch "$STATE_DIR/boot-order-restored"
echo "dendritic-windows-finalize: installed marker written; wininstall media kept"
