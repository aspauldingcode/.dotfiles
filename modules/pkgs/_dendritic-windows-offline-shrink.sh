#!/usr/bin/env bash
# Runs from initrd BEFORE sysroot.mount. Shrinks ext4 root offline and carves
# windows + wininstall + swap. Triggered by ESP marker pending-shrink.
set -euo pipefail

ESP_MNT=/dendritic-esp
MARKER="$ESP_MNT/dendritic-windows/pending-shrink"
DONE="$ESP_MNT/dendritic-windows/shrink-done"

log() { echo "dendritic-windows-offline-shrink: $*"; }
die() {
  echo "dendritic-windows-offline-shrink: ERROR: $*" >&2
  exit 1
}

# Locate ESP (vfat).
mkdir -p "$ESP_MNT"
esp_dev=""
for cand in /dev/disk/by-partlabel/ESP /dev/disk/by-label/ESP; do
  if [[ -b $cand ]]; then
    esp_dev="$(readlink -f "$cand")"
    break
  fi
done
if [[ -z $esp_dev ]]; then
  # Fallback: first partition of the configured disk if marker path known later
  log "ESP not found yet; skip"
  exit 0
fi

mount -t vfat -o rw "$esp_dev" "$ESP_MNT" || exit 0
if [[ ! -f $MARKER ]]; then
  umount "$ESP_MNT" || true
  exit 0
fi

# shellcheck disable=SC1090
source "$MARKER"

: "${DISK:?}"
: "${NEW_FS_MIB:?}"
: "${WINDOWS_MIB:?}"
: "${INSTALL_MIB:?}"
: "${SWAP_UUID:?}"

root_part="${DISK}-part2"
[[ -b $root_part ]] || die "root part missing: $root_part"

log "offline shrink $root_part -> ${NEW_FS_MIB}M"
e2fsck -f -y "$root_part" || true
resize2fs "$root_part" "${NEW_FS_MIB}M"

# Drop old swap (part3) if present
if [[ -b ${DISK}-part3 ]]; then
  swapoff "${DISK}-part3" 2>/dev/null || true
  parted -s "$DISK" rm 3 || true
fi

start_b="$(cat "/sys/block/$(basename "$DISK")/$(basename "$root_part")/start")"
start_mib=$((start_b * 512 / 1024 / 1024))
part2_end_mib=$((start_mib + NEW_FS_MIB + 16))
win_start=$part2_end_mib
win_end=$((win_start + WINDOWS_MIB))
inst_start=$win_end
inst_end=$((inst_start + INSTALL_MIB))
swap_start=$inst_end

log "parted: resize 2; mkpart windows/wininstall/swap"
parted -s "$DISK" unit MiB \
  resizepart 2 "$part2_end_mib" \
  mkpart windows ntfs "$win_start" "$win_end" \
  mkpart wininstall ntfs "$inst_start" "$inst_end" \
  mkpart swap linux-swap "$swap_start" "100%"

sgdisk -c 1:ESP -c 2:nixos -c 3:windows -c 4:wininstall -c 5:swap "$DISK" >/dev/null || true
partprobe "$DISK" 2>/dev/null || true

swap_dev="${DISK}-part5"
if [[ -b $swap_dev ]]; then
  mkswap -U "$SWAP_UUID" -L swap "$swap_dev" || true
fi

mkdir -p "$(dirname "$DONE")"
{
  echo "shrunk_at=$(date -Iseconds 2>/dev/null || echo unknown)"
  echo "new_fs_mib=$NEW_FS_MIB"
} >"$DONE"
rm -f "$MARKER"
sync
umount "$ESP_MNT" || true
log "shrink complete; continuing boot"
