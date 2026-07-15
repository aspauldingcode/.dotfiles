#!/usr/bin/env bash
# One-shot: shrink NixOS root, create Windows NTFS, apply IoT Enterprise LTSC WIM.
# Idempotent: exits 0 if /var/lib/dendritic-windows/installed exists (unless FORCE).
set -euo pipefail

DISK="${DENDRITIC_WINDOWS_DISK:?}"
MOUNT="${DENDRITIC_WINDOWS_MOUNT:?}"
SIZE_GIB="${DENDRITIC_WINDOWS_SIZE_GIB:?}"
EDITION_NAME="${DENDRITIC_WINDOWS_EDITION_NAME:?}"
CACHE_DIR="${DENDRITIC_WINDOWS_CACHE:?}"
STATE_DIR="${DENDRITIC_WINDOWS_STATE:?}"
UNATTEND_TEMPLATE="${DENDRITIC_WINDOWS_UNATTEND_TEMPLATE:?}"
PASSWORD_FILE="${DENDRITIC_WINDOWS_PASSWORD_FILE:?}"
ISO_SHA256="${DENDRITIC_WINDOWS_ISO_SHA256:?}"
ISO_URL="${DENDRITIC_WINDOWS_ISO_URL:-}"
ISO_NAME="${DENDRITIC_WINDOWS_ISO_NAME:?}"
FORCE="${DENDRITIC_WINDOWS_FORCE:-0}"
ESP_MNT="${DENDRITIC_WINDOWS_ESP:-/boot}"
AUTO_REBOOT="${DENDRITIC_WINDOWS_AUTO_REBOOT:-1}"

INSTALLED="$STATE_DIR/installed"
ISO_PATH="$CACHE_DIR/$ISO_NAME"
WINDOWS_MIB=$((SIZE_GIB * 1024))
SWAP_MIB=9216 # ~9 GiB
NEED_MIB=$((WINDOWS_MIB + SWAP_MIB))

log() { echo "dendritic-windows-bootstrap: $*"; }
die() {
  echo "dendritic-windows-bootstrap: ERROR: $*" >&2
  exit 1
}

# Pure CI / dry-run: validate env + unattend only (no disk / download).
if [[ ${DENDRITIC_WINDOWS_SELFTEST:-0} == "1" ]]; then
  [[ -f $UNATTEND_TEMPLATE ]] || die "unattend template missing: $UNATTEND_TEMPLATE"
  grep -q '__DENDRITIC_PASSWORD__' "$UNATTEND_TEMPLATE" || die "password placeholder missing"
  grep -q 'SkipMachineOOBE>true</SkipMachineOOBE>' "$UNATTEND_TEMPLATE" || die "missing SkipMachineOOBE"
  grep -q 'WillShowUI>Never</WillShowUI>' "$UNATTEND_TEMPLATE" || die "missing WillShowUI Never"
  grep -q 'shutdown /r' "$UNATTEND_TEMPLATE" || die "missing post-specialize reboot"
  log "self-test OK"
  exit 0
fi

already_windows() {
  local dev
  dev="$(readlink -f /dev/disk/by-partlabel/windows 2>/dev/null || true)"
  [[ -n $dev && -b $dev ]] || return 1
  mkdir -p /run/dendritic-windows-probe
  if mount -t ntfs3 -o ro "$dev" /run/dendritic-windows-probe 2>/dev/null ||
    mount -t ntfs3 -o ro,nls=utf8 "$dev" /run/dendritic-windows-probe 2>/dev/null; then
    if [[ -e /run/dendritic-windows-probe/Windows/System32/ntoskrnl.exe ]]; then
      umount /run/dendritic-windows-probe || true
      return 0
    fi
    umount /run/dendritic-windows-probe || true
  fi
  return 1
}

if [[ $FORCE != "1" ]]; then
  if [[ -f $INSTALLED ]]; then
    log "marker $INSTALLED present; skip"
    exit 0
  fi
  if already_windows; then
    log "existing Windows install detected; writing marker and skip apply"
    mkdir -p "$STATE_DIR"
    echo "preexisting $(date -Iseconds)" >"$INSTALLED"
    exit 0
  fi
fi

# ── Preflight ──────────────────────────────────────────────────────────
[[ -b $DISK ]] || die "disk $DISK missing"
if [[ -e /sys/firmware/efi/efivars ]]; then
  # Secure Boot: byte at offset 4 of SecureBoot-*-efi var; 1=enabled
  sb="$(od -An -tx1 -j4 -N1 /sys/firmware/efi/efivars/SecureBoot-* 2>/dev/null | tr -d ' \n' || echo 00)"
  if [[ $sb == "01" ]]; then
    die "Secure Boot is enabled; disable in firmware before bootstrap"
  fi
fi

# Prefer AC power
if [[ -r /sys/class/power_supply/AC0/online ]]; then
  [[ "$(cat /sys/class/power_supply/AC0/online)" == "1" ]] || log "WARNING: not on AC power"
elif [[ -r /sys/class/power_supply/ADP1/online ]]; then
  [[ "$(cat /sys/class/power_supply/ADP1/online)" == "1" ]] || log "WARNING: not on AC power"
fi

root_src="$(findmnt -n -o SOURCE /)"
root_avail_kib="$(df -k --output=avail / | tail -1 | tr -d ' ')"
root_avail_mib=$((root_avail_kib / 1024))
# Keep ≥20 GiB free after carving NEED_MIB from the filesystem
[[ $root_avail_mib -gt $((NEED_MIB + 20 * 1024)) ]] ||
  die "need ~$((NEED_MIB / 1024 + 20)) GiB free on /; have ~$((root_avail_mib / 1024)) GiB"

[[ -r $PASSWORD_FILE ]] || die "password file missing: $PASSWORD_FILE"
PASSWORD="$(tr -d '\n' <"$PASSWORD_FILE")"
[[ -n $PASSWORD ]] || die "password file empty"

mkdir -p "$CACHE_DIR" "$STATE_DIR"

# ── Fetch ISO (Microsoft Eval fwlink → CDN) ───────────────────────────
iso_ok() {
  [[ -f $ISO_PATH ]] || return 1
  # Allow skipping verify only if explicitly requested (empty sha = skip).
  if [[ -z $ISO_SHA256 || $ISO_SHA256 == "skip" ]]; then
    [[ -s $ISO_PATH ]]
    return
  fi
  echo "${ISO_SHA256}  ${ISO_PATH}" | sha256sum -c --status
}

if ! iso_ok; then
  [[ -n $ISO_URL ]] || die "ISO missing and DENDRITIC_WINDOWS_ISO_URL is empty"
  mkdir -p "$CACHE_DIR"
  log "downloading IoT LTSC eval ISO (~4.8 GiB) via $ISO_URL"
  log "  to: $ISO_PATH"
  rm -f "$ISO_PATH" "$ISO_PATH.aria2"
  # aria2 follows the Microsoft fwlink → signed CDN URL.
  aria2c \
    --max-connection-per-server=16 \
    --split=16 \
    --min-split-size=1M \
    --continue=true \
    --allow-overwrite=true \
    --auto-file-renaming=false \
    --max-tries=5 \
    --retry-wait=30 \
    --dir="$CACHE_DIR" \
    --out="$ISO_NAME" \
    "$ISO_URL"
  iso_ok || die "ISO sha256 mismatch after download (expected $ISO_SHA256)"
  log "ISO verified OK"
fi

# ── Repartition (once) ─────────────────────────────────────────────────
nparts="$(lsblk -n -o NAME "$DISK" | wc -l)"
nparts=$((nparts - 1))

if [[ $nparts -lt 4 ]]; then
  log "repartitioning: carve ${SIZE_GIB}G windows + ~9G swap from end of disk"
  swapoff -a || true

  # Delete trailing swap partition (part3)
  parted -s "$DISK" rm 3 || true
  partprobe "$DISK" || true
  udevadm settle || true

  # Shrink ext4 on part2
  root_part="${DISK}-part2"
  [[ $root_src == "$(readlink -f "$root_part")" ]] || die "root $root_src is not $root_part"

  # Current end of part2 in MiB from parted
  # Shrink filesystem first: target size = current blocks - NEED
  block_size="$(tune2fs -l "$root_part" | awk -F: '/Block size/ {gsub(/ /,"",$2); print $2}')"
  block_count="$(tune2fs -l "$root_part" | awk -F: '/Block count/ {gsub(/ /,"",$2); print $2}')"
  fs_mib=$((block_count * block_size / 1024 / 1024))
  new_fs_mib=$((fs_mib - NEED_MIB))
  [[ $new_fs_mib -gt 50000 ]] || die "refusing to shrink root below 50G (would be ${new_fs_mib}M)"

  log "resize2fs $root_part -> ${new_fs_mib}M"
  e2fsck -f -y "$root_part" || true
  resize2fs "$root_part" "${new_fs_mib}M"

  # Resize partition 2 in parted (MiB). Start stays; new end = start + new_fs_mib (+ small slack)
  # Get start in bytes
  start_b="$(cat "/sys/block/$(basename "$DISK")/$(basename "$root_part")/start")"
  sect_b=512
  start_mib=$((start_b * sect_b / 1024 / 1024))
  # Leave 1MiB alignment slack inside the partition for FS
  part2_end_mib=$((start_mib + new_fs_mib + 16))
  win_start=$part2_end_mib
  win_end=$((win_start + WINDOWS_MIB))
  swap_start=$win_end
  # swap goes to end of disk

  log "parted: resize 2 end=${part2_end_mib}MiB; mkpart windows; mkpart swap"
  parted -s "$DISK" unit MiB \
    resizepart 2 "$part2_end_mib" \
    mkpart windows ntfs "$win_start" "$win_end" \
    mkpart swap linux-swap "$swap_start" "100%"

  sgdisk -c 1:ESP -c 2:nixos -c 3:windows -c 4:swap "$DISK" >/dev/null
  partprobe "$DISK" || true
  udevadm settle || true

  win_dev="${DISK}-part3"
  swap_dev="${DISK}-part4"
  [[ -b $win_dev ]] || die "windows partition missing"
  [[ -b $swap_dev ]] || die "swap partition missing"

  mkfs.ntfs -f -L windows "$win_dev"
  # Keep the previous swap UUID so NixOS swapDevices stays valid across bootstrap.
  mkswap -U c570ec29-6025-456b-99d1-8f16b677835a -L swap "$swap_dev"
  swapon "$swap_dev" || true
else
  log "four partitions already present; skip shrink"
  win_dev="$(readlink -f /dev/disk/by-partlabel/windows)"
  [[ -b $win_dev ]] || die "partlabel windows missing"
fi

# ── Apply WIM ───────────────────────────────────────────────────────────
isomnt="$(mktemp -d /run/dendritic-windows-iso.XXXX)"
cleanup() {
  umount "$isomnt" 2>/dev/null || true
  rmdir "$isomnt" 2>/dev/null || true
  umount "$MOUNT" 2>/dev/null || true
}
trap cleanup EXIT

mount -o ro,loop "$ISO_PATH" "$isomnt"
wim="${isomnt}/sources/install.wim"
[[ -f $wim ]] || wim="${isomnt}/sources/install.esd"
[[ -f $wim ]] || die "install.wim/esd not in ISO"

# Resolve image index by name
idx="$(wimlib-imagex info "$wim" | awk -v name="$EDITION_NAME" '
  /^Index:/ { idx=$2 }
  /^Name:/ {
    $1=""; sub(/^ /,"");
    if (index($0, name) || $0 == name) { print idx; exit }
  }
')"
if [[ -z $idx ]]; then
  log "available images:"
  wimlib-imagex info "$wim" | sed -n '/^Index:/,/^Architecture:/p' >&2 || true
  die "could not find WIM image matching '$EDITION_NAME'"
fi
log "applying WIM index $idx ($EDITION_NAME) -> $win_dev"

# Ensure unmounted
umount "$win_dev" 2>/dev/null || true
umount "$MOUNT" 2>/dev/null || true
findmnt "$win_dev" >/dev/null 2>&1 && die "$win_dev still mounted"

wimlib-imagex apply "$wim" "$idx" "$win_dev"

# ── Inject unattend ─────────────────────────────────────────────────────
mkdir -p "$MOUNT"
mount -t ntfs3 -o rw,uid=0,gid=0 "$win_dev" "$MOUNT"
mkdir -p "$MOUNT/Windows/Panther"
# Escape XML special chars in password minimally
xml_pass="$(printf '%s' "$PASSWORD" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')"
sed "s|__DENDRITIC_PASSWORD__|${xml_pass}|g" "$UNATTEND_TEMPLATE" >"$MOUNT/Windows/Panther/unattend.xml"
# Also place at root for some specialize paths
cp "$MOUNT/Windows/Panther/unattend.xml" "$MOUNT/autounattend.xml" 2>/dev/null || true

# ── ESP: Microsoft Boot Manager ─────────────────────────────────────────
mkdir -p "$ESP_MNT/EFI/Microsoft/Boot"
# Prefer files from applied image
if [[ -d "$MOUNT/Windows/Boot/EFI" ]]; then
  cp -n "$MOUNT/Windows/Boot/EFI/"*.efi "$ESP_MNT/EFI/Microsoft/Boot/" 2>/dev/null || true
  cp -f "$MOUNT/Windows/Boot/EFI/bootmgfw.efi" "$ESP_MNT/EFI/Microsoft/Boot/bootmgfw.efi"
fi
# BCD store: copy from image if present; Windows specialize repairs if needed
if [[ -f "$MOUNT/Boot/BCD" ]]; then
  mkdir -p "$ESP_MNT/EFI/Microsoft/Boot"
  cp -f "$MOUNT/Boot/BCD" "$ESP_MNT/EFI/Microsoft/Boot/BCD" 2>/dev/null || true
fi
if [[ -f "$MOUNT/Windows/Boot/EFI/BCD" ]]; then
  cp -f "$MOUNT/Windows/Boot/EFI/BCD" "$ESP_MNT/EFI/Microsoft/Boot/BCD" 2>/dev/null || true
fi

# Register EFI entry if missing
if ! efibootmgr | grep -qi 'Windows Boot Manager'; then
  # Partition 1 is ESP
  efibootmgr --create --disk "$DISK" --part 1 \
    --label 'Windows Boot Manager' \
    --loader '\EFI\Microsoft\Boot\bootmgfw.efi' || true
fi

# One-shot next boot → Windows specialize. Do NOT flip BootOrder (keeps NixOS default).
win_boot="$(efibootmgr | sed -n 's/^Boot\([0-9A-Fa-f]*\).*Windows Boot Manager.*/\1/p' | head -1)"
if [[ -n $win_boot ]]; then
  efibootmgr --bootnext "$win_boot" || die "efibootmgr --bootnext $win_boot failed"
  log "BootNext=$win_boot (one-shot silent specialize); BootOrder unchanged"
else
  log "WARNING: Windows Boot Manager EFI entry missing; set BootNext manually after reboot"
fi

umount "$MOUNT" || true
umount "$isomnt" || true
trap - EXIT

mkdir -p "$STATE_DIR"
{
  echo "edition=$EDITION_NAME"
  echo "wim_index=$idx"
  echo "iso_sha256=$ISO_SHA256"
  echo "installed_at=$(date -Iseconds)"
  echo "sku=IoTEnterpriseLTSC"
  echo "silent=1"
} >"$INSTALLED"

log "done — silent wimlib apply + unattend injected (no Windows Setup GUI)"
log 'next boot (BootNext): unattended specialize → marker → auto-reboot to NixOS'
if [[ $AUTO_REBOOT == "1" ]]; then
  log "rebooting into Windows specialize now"
  systemctl reboot
else
  log "AUTO_REBOOT=0 — reboot when ready to finish specialize"
fi
