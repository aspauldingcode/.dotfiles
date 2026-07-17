#!/usr/bin/env bash
# Label existing GPT partitions so by-partlabel mounts work.
# NEVER invent a swap label on an unknown 3rd partition — that destroyed nixinstall.
# Prefer content/size detection over fixed indices (Windows Setup may add MSR and
# renumber so LBA order is ESP→nixos→windows→wininstall→swap→nixinstall[+MSR]).
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

# Resolve /dev/sdXN or /dev/nvme0n1pN for GPT index i on $DISK.
part_dev() {
  local i="$1" base cand
  base="$(readlink -f "$DISK")"
  for cand in "${base}-part${i}" "${base}p${i}" "${base}${i}"; do
    if [[ -b $cand ]]; then
      printf '%s' "$cand"
      return 0
    fi
  done
  return 1
}

label_by_content() {
  # Label parts 3..n by fstype + size. Leaves Microsoft reserved alone (or names it).
  local i dev sz_b type label
  SWAP_DEV=""
  for i in $(seq 3 "$nparts"); do
    dev="$(part_dev "$i")" || continue
    type="$(blkid -o value -s TYPE "$dev" 2>/dev/null || true)"
    label="$(blkid -o value -s PARTLABEL "$dev" 2>/dev/null || true)"
    sz_b="$(lsblk -nbdo SIZE "$dev" 2>/dev/null || echo 0)"

    # ~16 MiB MSR created by Windows Setup
    if [[ $sz_b -gt 0 && $sz_b -lt 33554432 ]] ||
      [[ $label == *[Mm]icrosoft*reserved* ]]; then
      sgdisk -c "$i:msr" "$DISK" >/dev/null || true
      continue
    fi

    case "$type" in
    swap)
      sgdisk -c "$i:swap" "$DISK" >/dev/null
      SWAP_DEV="$dev"
      ;;
    ext4)
      sgdisk -c "$i:nixinstall" "$DISK" >/dev/null
      ;;
    ntfs | ntfs3)
      # windows ≈ 64 GiB; wininstall ≈ 8 GiB (allow slack)
      if [[ $sz_b -ge 40000000000 ]]; then
        sgdisk -c "$i:windows" "$DISK" >/dev/null
      else
        sgdisk -c "$i:wininstall" "$DISK" >/dev/null
      fi
      ;;
    btrfs)
      # Should only be nixos (#2); ignore extras
      :
      ;;
    vfat | fat32 | fat16 | msdos)
      :
      ;;
    *)
      # Blank / unknown: size heuristics matching disko carve
      if [[ $sz_b -ge 40000000000 ]]; then
        sgdisk -c "$i:windows" "$DISK" >/dev/null
      elif [[ $sz_b -ge 6000000000 && $sz_b -le 12000000000 ]]; then
        # 8G wininstall or nixinstall — prefer existing PARTLABEL / leave if labeled
        if [[ $label == nixinstall ]]; then
          sgdisk -c "$i:nixinstall" "$DISK" >/dev/null
        elif [[ $label == wininstall || $label == windows ]]; then
          sgdisk -c "$i:wininstall" "$DISK" >/dev/null
        elif [[ -z $type ]]; then
          # Ambiguous empty 8G: skip rather than mislabel
          echo "dendritic-windows-label-gpt: skip unlabeled blank part $i ($dev)" >&2
        else
          sgdisk -c "$i:wininstall" "$DISK" >/dev/null
        fi
      elif [[ $sz_b -ge 2000000000 && $sz_b -le 12000000000 && -z $type ]]; then
        sgdisk -c "$i:swap" "$DISK" >/dev/null
        SWAP_DEV="$dev"
      fi
      ;;
    esac
  done
}

SWAP_DEV=""
case "$nparts" in
7 | 6 | 5)
  # Content-based: survives Windows MSR insert + GPT renumber.
  label_by_content
  ;;
4)
  # Legacy dual-boot without wininstall, or ESP nixos nixinstall + something
  if blkid "$(part_dev 3)" 2>/dev/null | grep -q 'TYPE="ext4"\|LABEL="nixinstall"\|TYPE="btrfs"'; then
    sgdisk -c 3:nixinstall "$DISK" >/dev/null
    if blkid "$(part_dev 4)" 2>/dev/null | grep -q 'TYPE="swap"'; then
      sgdisk -c 4:swap "$DISK" >/dev/null
      SWAP_DEV="$(part_dev 4)"
    fi
  else
    sgdisk -c 3:windows "$DISK" >/dev/null
    sgdisk -c 4:swap "$DISK" >/dev/null
    SWAP_DEV="$(part_dev 4)"
  fi
  ;;
3)
  # ESP + nixos + (nixinstall | swap). Distinguish by filesystem — never mkswap ext4.
  if blkid "$(part_dev 3)" 2>/dev/null | grep -Eq 'TYPE="swap"|TYPE="linux_raid_member"'; then
    sgdisk -c 3:swap "$DISK" >/dev/null
    SWAP_DEV="$(part_dev 3)"
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

if [[ -n ${SWAP_DEV:-} && -b $SWAP_DEV ]]; then
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
