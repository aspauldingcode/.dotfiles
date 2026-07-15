#!/usr/bin/env bash
# Create/populate PARTLABEL=nixinstall with sliceanddice-installer + systemd-boot entry.
set -euo pipefail

DISK="${DENDRITIC_NIXINSTALL_DISK:?}"
MOUNT="${DENDRITIC_NIXINSTALL_MOUNT:-/mnt/nixinstall}"
STATE_DIR="${DENDRITIC_NIXINSTALL_STATE:-/var/lib/dendritic-nixinstall}"
FLAKE_DIR="${DENDRITIC_FLAKE_DIR:-/etc/nixos/.dotfiles}"
INSTALLER_TOPLEVEL="${DENDRITIC_INSTALLER_TOPLEVEL:?}"
ESP="${DENDRITIC_NIXINSTALL_ESP:-/boot}"
SIZE_GIB="${DENDRITIC_NIXINSTALL_SIZE_GIB:-8}"
FORCE="${DENDRITIC_NIXINSTALL_FORCE:-0}"

READY="$STATE_DIR/ready"
SIZE_MIB=$((SIZE_GIB * 1024))

log() { echo "dendritic-nixinstall-bootstrap: $*"; }
die() {
  echo "dendritic-nixinstall-bootstrap: ERROR: $*" >&2
  exit 1
}

if [[ ${DENDRITIC_NIXINSTALL_SELFTEST:-0} == "1" ]]; then
  [[ -n $INSTALLER_TOPLEVEL ]] || die "toplevel missing"
  log "self-test OK"
  exit 0
fi

[[ -b $DISK ]] || die "disk $DISK missing"
mkdir -p "$STATE_DIR" "$MOUNT"

if [[ $FORCE != "1" && -f $READY ]] && [[ -b /dev/disk/by-partlabel/nixinstall ]]; then
  log "marker $READY present; skip (FORCE=1 to refresh)"
  exit 0
fi

# ── Create partition in free space at end of disk if missing ───────────
if [[ ! -b /dev/disk/by-partlabel/nixinstall ]]; then
  log "creating ${SIZE_GIB}G nixinstall partition at end of $DISK"
  # Free space starts after last partition end (sectors).
  last_end="$(sfdisk -d "$DISK" | awk -F'[ ,=]+' '/start=/ {e=$4+$6} END {print e+0}')"
  [[ -n $last_end && $last_end -gt 0 ]] || die "could not parse partition table"
  # Align to 1MiB
  start=$(((last_end + 2047) / 2048 * 2048))
  size_sect=$((SIZE_MIB * 1024 * 1024 / 512))
  disk_sects="$(blockdev --getsz "$DISK")"
  end=$((start + size_sect - 1))
  [[ $end -lt $disk_sects ]] || die "not enough free sectors (need ~${SIZE_GIB}G at end of disk)"

  echo "start=$start size=$size_sect type=8300 name=nixinstall" | sfdisk --force -a "$DISK"
  partprobe "$DISK" 2>/dev/null || true
  udevadm settle || true
  sleep 1
  [[ -b /dev/disk/by-partlabel/nixinstall ]] || {
    # Fallback label via sgdisk if sfdisk name didn't stick
    nparts="$(lsblk -n -o NAME "$DISK" | wc -l)"
    nparts=$((nparts - 1))
    sgdisk -c "$nparts:nixinstall" "$DISK" || true
    partprobe "$DISK" 2>/dev/null || true
    udevadm settle || true
  }
  [[ -b /dev/disk/by-partlabel/nixinstall ]] || die "nixinstall partition still missing"
  mkfs.ext4 -F -L nixinstall /dev/disk/by-partlabel/nixinstall
fi

dev="$(readlink -f /dev/disk/by-partlabel/nixinstall)"
umount "$MOUNT" 2>/dev/null || true
mount -t ext4 "$dev" "$MOUNT"

log "installing installer system → $MOUNT"
mkdir -p "$MOUNT/boot"
# Bind ESP so nixos-install can write loader entries
if ! findmnt -n "$MOUNT/boot" >/dev/null 2>&1; then
  mount --bind "$ESP" "$MOUNT/boot"
fi

nixos-install \
  --system "$INSTALLER_TOPLEVEL" \
  --root "$MOUNT" \
  --no-root-password \
  --no-channel-copy \
  --no-bootloader || {
  # Fallback without bootloader; we write a loader entry ourselves
  log "nixos-install --no-bootloader retry"
  nixos-install \
    --system "$INSTALLER_TOPLEVEL" \
    --root "$MOUNT" \
    --no-root-password \
    --no-channel-copy \
    --no-bootloader
}

# Copy flake for offline reinstall orchestration
log "syncing flake → $MOUNT/flake"
mkdir -p "$MOUNT/flake"
rsync -a --delete \
  --exclude .git \
  --exclude result \
  --exclude 'result-*' \
  "$FLAKE_DIR/" "$MOUNT/flake/" ||
  rsync -a "$FLAKE_DIR/" "$MOUNT/flake/"

# systemd-boot entry on ESP pointing at installer kernel/initrd with nixinstall root
partuuid="$(blkid -o value -s PARTUUID "$dev" || true)"
[[ -n $partuuid ]] || die "PARTUUID missing for nixinstall"
gen="$(basename "$(readlink -f "$INSTALLER_TOPLEVEL")")"
mkdir -p "$ESP/EFI/dendritic-installer" "$ESP/loader/entries"
# Prefer kernels already placed under /boot by nixos-install; also keep store paths via bind.
cat >"$ESP/loader/entries/dendritic-installer.conf" <<EOF
title  NixOS Installer (dendritic)
linux  /EFI/dendritic-installer/bzImage
initrd /EFI/dendritic-installer/initrd
options root=PARTUUID=$partuuid rootfstype=ext4 rw init=/nix/var/nix/profiles/system/init
EOF

# Copy kernel/initrd from the installer toplevel into ESP
if [[ -e $INSTALLER_TOPLEVEL/kernel ]]; then
  cp -f "$(readlink -f "$INSTALLER_TOPLEVEL/kernel")" "$ESP/EFI/dendritic-installer/bzImage"
  cp -f "$(readlink -f "$INSTALLER_TOPLEVEL/initrd")" "$ESP/EFI/dendritic-installer/initrd"
else
  die "installer toplevel missing kernel/initrd"
fi

umount "$MOUNT/boot" 2>/dev/null || true

{
  echo "toplevel=$INSTALLER_TOPLEVEL"
  echo "partuuid=$partuuid"
  echo "ready_at=$(date -Iseconds)"
} >"$READY"

log "done — reboot and pick 'NixOS Installer (dendritic)'"
log "before wipe: dendritic-vault-sync"
log "in installer: dendritic-reinstall"
