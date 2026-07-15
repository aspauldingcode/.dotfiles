#!/usr/bin/env bash
# Label existing GPT partitions + swap so disko-oriented by-label mounts work
# before Windows bootstrap repartitions the disk.
set -euo pipefail

DISK="${DENDRITIC_WINDOWS_DISK:?}"
ESP_PART="${DISK}-part1"
ROOT_PART="${DISK}-part2"
SWAP_PART="${DISK}-part3"

if [[ ! -b $DISK ]]; then
  echo "dendritic-windows-label-gpt: disk $DISK not found" >&2
  exit 1
fi

# Current layout (pre-bootstrap): 1=ESP 2=root 3=swap
# Post-bootstrap: 1=ESP 2=nixos 3=windows 4=wininstall 5=swap
nparts="$(lsblk -n -o NAME "$DISK" | wc -l)"
nparts=$((nparts - 1))

sgdisk -c 1:ESP "$DISK" >/dev/null
sgdisk -c 2:nixos "$DISK" >/dev/null

if [[ $nparts -ge 5 ]]; then
  sgdisk -c 3:windows "$DISK" >/dev/null
  sgdisk -c 4:wininstall "$DISK" >/dev/null
  sgdisk -c 5:swap "$DISK" >/dev/null
  SWAP_DEV="${DISK}-part5"
elif [[ $nparts -eq 4 ]]; then
  # Legacy dual-boot layout without wininstall
  sgdisk -c 3:windows "$DISK" >/dev/null
  sgdisk -c 4:swap "$DISK" >/dev/null
  SWAP_DEV="${DISK}-part4"
elif [[ $nparts -eq 3 ]]; then
  sgdisk -c 3:swap "$DISK" >/dev/null
  SWAP_DEV="$SWAP_PART"
else
  echo "dendritic-windows-label-gpt: unexpected partition count $nparts" >&2
  exit 1
fi

partprobe "$DISK" 2>/dev/null || true
udevadm settle || true

if [[ -b $SWAP_DEV ]]; then
  swap_real="$(readlink -f "$SWAP_DEV")"
  active=0
  while read -r name; do
    [[ -n $name ]] || continue
    [[ "$(readlink -f "$name")" == "$swap_real" ]] && active=1 && break
  done < <(swapon --show=NAME --noheadings 2>/dev/null || true)
  if [[ $active -eq 1 ]]; then
    # Active swap: label only (never mkswap).
    swaplabel -L swap "$SWAP_DEV" 2>/dev/null || true
  else
    swaplabel -L swap "$SWAP_DEV" 2>/dev/null || mkswap -L swap "$SWAP_DEV" || true
  fi
fi

echo "dendritic-windows-label-gpt: labeled ESP/nixos/swap (parts=$nparts)"
