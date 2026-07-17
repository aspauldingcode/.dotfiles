#!/usr/bin/env bash
# Label existing GPT partitions so by-partlabel mounts work.
# NEVER invent a swap label on an unknown 3rd partition — that destroyed nixinstall.
set -euo pipefail

DISK="${DENDRITIC_WINDOWS_DISK:?}"

if [[ ! -b $DISK ]]; then
  echo "dendritic-windows-label-gpt: disk $DISK not found" >&2
  exit 1
fi

# Prefer bash counting — systemd PATH may lack awk even when gawk is a runtimeInput.
nparts="$(lsblk -nro TYPE "$DISK" | grep -c '^part$' || true)"

sgdisk -c 1:ESP "$DISK" >/dev/null
sgdisk -c 2:nixos "$DISK" >/dev/null

SWAP_DEV=""
case "$nparts" in
6)
  # Target: ESP nixos windows|nixinstall… — detect by existing PARTLABEL/FS
  # Prefer fixed target order if windows exists or sizes match; else label by content.
  sgdisk -c 3:nixinstall "$DISK" >/dev/null || true
  sgdisk -c 4:windows "$DISK" >/dev/null || true
  sgdisk -c 5:wininstall "$DISK" >/dev/null || true
  sgdisk -c 6:swap "$DISK" >/dev/null || true
  SWAP_DEV="${DISK}-part6"
  ;;
5)
  # ESP nixos windows wininstall swap  OR  ESP nixos windows wininstall nixinstall
  # If part5 is already swap-type or labeled swap, keep; if ext4 nixinstall, don't mkswap.
  sgdisk -c 3:windows "$DISK" >/dev/null
  sgdisk -c 4:wininstall "$DISK" >/dev/null
  if blkid "${DISK}-part5" 2>/dev/null | grep -q 'TYPE="ext4"'; then
    sgdisk -c 5:nixinstall "$DISK" >/dev/null
  else
    sgdisk -c 5:swap "$DISK" >/dev/null
    SWAP_DEV="${DISK}-part5"
  fi
  ;;
4)
  # Legacy dual-boot without wininstall, or ESP nixos nixinstall + something
  if blkid "${DISK}-part3" 2>/dev/null | grep -q 'TYPE="ext4"\|LABEL="nixinstall"\|TYPE="btrfs"'; then
    sgdisk -c 3:nixinstall "$DISK" >/dev/null
    if blkid "${DISK}-part4" 2>/dev/null | grep -q 'TYPE="swap"'; then
      sgdisk -c 4:swap "$DISK" >/dev/null
      SWAP_DEV="${DISK}-part4"
    fi
  else
    sgdisk -c 3:windows "$DISK" >/dev/null
    sgdisk -c 4:swap "$DISK" >/dev/null
    SWAP_DEV="${DISK}-part4"
  fi
  ;;
3)
  # ESP + nixos + (nixinstall | swap). Distinguish by filesystem — never mkswap ext4.
  if blkid "${DISK}-part3" 2>/dev/null | grep -Eq 'TYPE="swap"|TYPE="linux_raid_member"'; then
    sgdisk -c 3:swap "$DISK" >/dev/null
    SWAP_DEV="${DISK}-part3"
  else
    # Default: third partition is nixinstall (installer + vault)
    sgdisk -c 3:nixinstall "$DISK" >/dev/null
  fi
  ;;
2)
  :
  ;;
*)
  echo "dendritic-windows-label-gpt: unexpected partition count $nparts" >&2
  exit 1
  ;;
esac

partprobe "$DISK" 2>/dev/null || true
udevadm settle || true

if [[ -n $SWAP_DEV && -b $SWAP_DEV ]]; then
  # Only mkswap if already swap or completely blank — never wipe ext4/btrfs/ntfs.
  if blkid "$SWAP_DEV" 2>/dev/null | grep -q 'TYPE="swap"'; then
    swaplabel -L swap "$SWAP_DEV" 2>/dev/null || true
  elif ! blkid "$SWAP_DEV" 2>/dev/null | grep -q 'TYPE='; then
    mkswap -L swap "$SWAP_DEV" || true
  else
    echo "dendritic-windows-label-gpt: refusing mkswap on $SWAP_DEV (has filesystem)" >&2
  fi
fi

echo "dendritic-windows-label-gpt: labeled GPT (parts=$nparts)"
