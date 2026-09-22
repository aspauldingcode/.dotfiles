#!/usr/bin/env bash
# After grub-install --removable: AMI on this host ignores BootOrder and
# keeps leftover "Linux Boot Manager" (systemd-boot). Delete that NVRAM
# entry and move the binary off EFI/systemd so firmware cannot re-register
# it. Do not raw-copy grubx64.efi over BOOTX64 — NixOS grub-install
# --removable writes that path with the correct prefix.
set -euo pipefail

bootnum() {
  local line="$1" id
  id="${line#Boot}"
  printf '%s\n' "${id%%[^0-9A-Fa-f]*}"
}

is_boot_entry() {
  [[ $1 == Boot[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]* ]]
}

while IFS= read -r line; do
  is_boot_entry "$line" || continue
  case "$line" in
  *Windows*) continue ;;
  *systemd-boot* | *"Linux Boot Manager"*)
    num="$(bootnum "$line")"
    efibootmgr -b "$num" -B || true
    echo "dendritic-grub-efi-first: deleted Boot${num} (leftover systemd-boot)"
    ;;
  esac
done < <(efibootmgr)

if [[ -f /boot/EFI/systemd/systemd-bootx64.efi ]]; then
  mkdir -p /boot/EFI/dendritic-fallback
  mv -f /boot/EFI/systemd/systemd-bootx64.efi /boot/EFI/dendritic-fallback/systemd-bootx64.efi
  echo "dendritic-grub-efi-first: moved systemd-boot → /boot/EFI/dendritic-fallback"
fi

pick_grub() {
  local line grub=""
  while IFS= read -r line; do
    is_boot_entry "$line" || continue
    case "$line" in
    *Windows*) continue ;;
    *NIXOS-BOOT* | *NixOS-boot* | *nixos-boot* | *GRUBX64* | *grubx64.efi*)
      grub="$(bootnum "$line")"
      ;;
    esac
  done < <(efibootmgr)
  [[ -n $grub ]] || return 1
  printf '%s\n' "$grub"
}

mapfile -t order < <(efibootmgr | sed -n 's/^BootOrder: //p' | tr ',' '\n')
grub_boot="$(pick_grub || true)"
if [[ -z $grub_boot ]]; then
  echo "dendritic-grub-efi-first: no NixOS-boot entry (removable BOOTX64 is enough)"
  exit 0
fi

new_order=("$grub_boot")
for e in "${order[@]}"; do
  [[ -n $e ]] || continue
  [[ $e == "$grub_boot" ]] && continue
  new_order+=("$e")
done
joined="$(
  IFS=,
  echo "${new_order[*]}"
)"

current="$(efibootmgr | sed -n 's/^BootOrder: //p')"
if [[ $current == "$joined" ]]; then
  echo "dendritic-grub-efi-first: BootOrder already $joined"
  exit 0
fi

efibootmgr -o "$joined"
echo "dendritic-grub-efi-first: BootOrder $current -> $joined"
