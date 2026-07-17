#!/usr/bin/env bash
# One-shot: shrink NixOS root, create windows + wininstall + swap, extract Setup media
# onto wininstall, BootNext into silent Windows Setup. Idempotent after media-ready /
# installed markers (wininstall partition stays; no re-bootstrap).
set -euo pipefail

DISK="${DENDRITIC_WINDOWS_DISK:?}"
MOUNT="${DENDRITIC_WINDOWS_MOUNT:?}"
INSTALL_MOUNT="${DENDRITIC_WINDOWS_INSTALL_MOUNT:-/mnt/wininstall}"
SIZE_GIB="${DENDRITIC_WINDOWS_SIZE_GIB:?}"
INSTALL_GIB="${DENDRITIC_WINDOWS_INSTALL_GIB:-8}"
EDITION_NAME="${DENDRITIC_WINDOWS_EDITION_NAME:?}"
CACHE_DIR="${DENDRITIC_WINDOWS_CACHE:?}"
STATE_DIR="${DENDRITIC_WINDOWS_STATE:?}"
UNATTEND_TEMPLATE="${DENDRITIC_WINDOWS_UNATTEND_TEMPLATE:?}"
PASSWORD_FILE="${DENDRITIC_WINDOWS_PASSWORD_FILE:?}"
ISO_SHA256="${DENDRITIC_WINDOWS_ISO_SHA256:?}"
ISO_URL="${DENDRITIC_WINDOWS_ISO_URL:-}"
ISO_NAME="${DENDRITIC_WINDOWS_ISO_NAME:?}"
FORCE="${DENDRITIC_WINDOWS_FORCE:-0}"
AUTO_REBOOT="${DENDRITIC_WINDOWS_AUTO_REBOOT:-1}"

INSTALLED="$STATE_DIR/installed"
MEDIA_READY="$STATE_DIR/media-ready"
ISO_PATH="$CACHE_DIR/$ISO_NAME"
WINDOWS_MIB=$((SIZE_GIB * 1024))
INSTALL_MIB=$((INSTALL_GIB * 1024))
SWAP_MIB=9216 # ~9 GiB
NEED_MIB=$((WINDOWS_MIB + INSTALL_MIB + SWAP_MIB))

log() { echo "dendritic-windows-bootstrap: $*"; }
die() {
  echo "dendritic-windows-bootstrap: ERROR: $*" >&2
  exit 1
}

# Pure CI / dry-run: validate env + unattend only (no disk / download).
if [[ ${DENDRITIC_WINDOWS_SELFTEST:-0} == "1" ]]; then
  [[ -f $UNATTEND_TEMPLATE ]] || die "unattend template missing: $UNATTEND_TEMPLATE"
  grep -q '__DENDRITIC_PASSWORD__' "$UNATTEND_TEMPLATE" || die "password placeholder missing"
  grep -q '__DENDRITIC_IMAGE_INDEX__' "$UNATTEND_TEMPLATE" || die "image index placeholder missing"
  grep -q 'SkipMachineOOBE>true</SkipMachineOOBE>' "$UNATTEND_TEMPLATE" || die "missing SkipMachineOOBE"
  grep -q 'WillShowUI>Never</WillShowUI>' "$UNATTEND_TEMPLATE" || die "missing WillShowUI Never"
  grep -q 'PartitionID>4</PartitionID>' "$UNATTEND_TEMPLATE" || die "missing InstallTo partition 4 (windows)"
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

media_populated() {
  local dev
  dev="$(readlink -f /dev/disk/by-partlabel/wininstall 2>/dev/null || true)"
  [[ -n $dev && -b $dev ]] || return 1
  mkdir -p /run/dendritic-wininstall-probe
  if mount -t ntfs3 -o ro "$dev" /run/dendritic-wininstall-probe 2>/dev/null ||
    mount -t ntfs3 -o ro,nls=utf8 "$dev" /run/dendritic-wininstall-probe 2>/dev/null; then
    if [[ -e /run/dendritic-wininstall-probe/sources/setup.exe ]] &&
      [[ -e /run/dendritic-wininstall-probe/Autounattend.xml || -e /run/dendritic-wininstall-probe/autounattend.xml ]]; then
      umount /run/dendritic-wininstall-probe || true
      return 0
    fi
    umount /run/dendritic-wininstall-probe || true
  fi
  return 1
}

mark_installed() {
  mkdir -p "$STATE_DIR"
  echo "${1:-ready} $(date -Iseconds)" >"$INSTALLED"
}

set_bootnext_setup() {
  local setup_boot part
  part="${1:?}"
  if ! efibootmgr | grep -qi 'Windows Setup (dendritic)'; then
    efibootmgr --create --disk "$DISK" --part "$part" \
      --label 'Windows Setup (dendritic)' \
      --loader '\EFI\BOOT\bootx64.efi' || die "failed to create Setup EFI entry"
  fi
  setup_boot="$(efibootmgr | sed -n 's/^Boot\([0-9A-Fa-f]*\).*Windows Setup (dendritic).*/\1/p' | head -1)"
  [[ -n $setup_boot ]] || die "Setup EFI Boot#### not found"
  efibootmgr --bootnext "$setup_boot" || die "efibootmgr --bootnext $setup_boot failed"
  log "BootNext=$setup_boot → wininstall Setup (part $part); BootOrder unchanged"
}

if [[ $FORCE != "1" ]]; then
  if [[ -f $INSTALLED ]]; then
    log "marker $INSTALLED present; skip"
    exit 0
  fi
  if already_windows; then
    log "existing Windows install detected; writing installed marker"
    mark_installed preexisting
    exit 0
  fi
fi

# Media already prepared: only refresh BootNext (no re-download / re-extract / no reboot loop).
if [[ $FORCE != "1" ]] && { [[ -f $MEDIA_READY ]] || media_populated; }; then
  log "wininstall media ready; Windows not installed yet — refresh BootNext only"
  install_dev="$(readlink -f /dev/disk/by-partlabel/wininstall)"
  [[ -b $install_dev ]] || die "partlabel wininstall missing"
  # Derive partition number from by-path / sysfs
  install_part="$(cat "/sys/class/block/$(basename "$install_dev")/partition")"
  set_bootnext_setup "$install_part"
  mkdir -p "$STATE_DIR"
  [[ -f $MEDIA_READY ]] || echo "recovered $(date -Iseconds)" >"$MEDIA_READY"
  log "reboot when ready to run silent Setup (AUTO_REBOOT skipped on retry)"
  exit 0
fi

# ── Preflight ──────────────────────────────────────────────────────────
[[ -b $DISK ]] || die "disk $DISK missing"
if [[ -e /sys/firmware/efi/efivars ]]; then
  sb="$(od -An -tx1 -j4 -N1 /sys/firmware/efi/efivars/SecureBoot-* 2>/dev/null | tr -d ' \n' || echo 00)"
  if [[ $sb == "01" ]]; then
    die "Secure Boot is enabled; disable in firmware before bootstrap"
  fi
fi

if [[ -r /sys/class/power_supply/AC0/online ]]; then
  [[ "$(cat /sys/class/power_supply/AC0/online)" == "1" ]] || log "WARNING: not on AC power"
elif [[ -r /sys/class/power_supply/ADP1/online ]]; then
  [[ "$(cat /sys/class/power_supply/ADP1/online)" == "1" ]] || log "WARNING: not on AC power"
fi

root_src="$(findmnt -n -o SOURCE /)"

[[ -r $PASSWORD_FILE ]] || die "password file missing: $PASSWORD_FILE"
PASSWORD="$(tr -d '\n' <"$PASSWORD_FILE")"
[[ -n $PASSWORD ]] || die "password file empty"

mkdir -p "$CACHE_DIR" "$STATE_DIR"

# ── Fetch ISO (Microsoft Eval fwlink → CDN) ───────────────────────────
iso_ok() {
  [[ -f $ISO_PATH ]] || return 1
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

# Free space for ISO download only (partitioning is owned by nixinstall/disko).
root_avail_kib="$(df -k --output=avail / | tail -1 | tr -d ' ')"
root_avail_mib=$((root_avail_kib / 1024))
[[ $root_avail_mib -gt 8192 ]] || die "need ≳8 GiB free on / for ISO; have ~$((root_avail_mib / 1024)) GiB"

# ── Partitions must already exist (disko from sliceanddice-installer) ──
win_dev="$(readlink -f /dev/disk/by-partlabel/windows 2>/dev/null || true)"
install_dev="$(readlink -f /dev/disk/by-partlabel/wininstall 2>/dev/null || true)"
[[ -b $win_dev ]] || die "PARTLABEL=windows missing — boot NixOS Installer and run dendritic-reinstall first"
[[ -b $install_dev ]] || die "PARTLABEL=wininstall missing — boot NixOS Installer and run dendritic-reinstall first"

# Format NTFS targets if empty.
if ! blkid -o value -s TYPE "$win_dev" 2>/dev/null | grep -qi ntfs; then
  log "mkfs.ntfs windows"
  mkfs.ntfs -f -L windows "$win_dev"
fi
if ! blkid -o value -s TYPE "$install_dev" 2>/dev/null | grep -qi ntfs; then
  log "mkfs.ntfs wininstall"
  mkfs.ntfs -f -L wininstall "$install_dev"
fi

# ── Extract ISO → wininstall (Setup media; stays after install) ────────
isomnt="$(mktemp -d /run/dendritic-windows-iso.XXXX)"
cleanup() {
  umount "$isomnt" 2>/dev/null || true
  rmdir "$isomnt" 2>/dev/null || true
  umount "$INSTALL_MOUNT" 2>/dev/null || true
  umount "$MOUNT" 2>/dev/null || true
}
trap cleanup EXIT

umount "$install_dev" 2>/dev/null || true
umount "$INSTALL_MOUNT" 2>/dev/null || true
mkdir -p "$INSTALL_MOUNT"
mount -t ntfs3 -o rw,uid=0,gid=0 "$install_dev" "$INSTALL_MOUNT"

# Fresh extract when FORCE or empty media
if [[ $FORCE == "1" ]]; then
  find "$INSTALL_MOUNT" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
fi

mount -o ro,loop "$ISO_PATH" "$isomnt"
wim="${isomnt}/sources/install.wim"
[[ -f $wim ]] || wim="${isomnt}/sources/install.esd"
[[ -f $wim ]] || die "install.wim/esd not in ISO"

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
log "extracting Setup media (image index $idx) → $install_dev"

rsync -aH --info=stats2 "$isomnt"/ "$INSTALL_MOUNT"/

[[ -e $INSTALL_MOUNT/sources/setup.exe ]] || die "setup.exe missing after extract"
[[ -e $INSTALL_MOUNT/EFI/BOOT/bootx64.efi || -e $INSTALL_MOUNT/efi/boot/bootx64.efi ]] ||
  die 'EFI\BOOT\bootx64.efi missing after extract'

xml_pass="$(printf '%s' "$PASSWORD" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')"
sed -e "s|__DENDRITIC_PASSWORD__|${xml_pass}|g" \
  -e "s|__DENDRITIC_IMAGE_INDEX__|${idx}|g" \
  "$UNATTEND_TEMPLATE" >"$INSTALL_MOUNT/Autounattend.xml"
cp -f "$INSTALL_MOUNT/Autounattend.xml" "$INSTALL_MOUNT/autounattend.xml"

sync
umount "$isomnt" || true
umount "$INSTALL_MOUNT" || true
trap - EXIT

# Free root cache after successful extract (media lives on wininstall).
if [[ -f $ISO_PATH ]]; then
  log "removing ISO cache $ISO_PATH (media on wininstall)"
  rm -f "$ISO_PATH" "$ISO_PATH.aria2"
fi

install_part="$(cat "/sys/class/block/$(basename "$install_dev")/partition")"
set_bootnext_setup "$install_part"

{
  echo "edition=$EDITION_NAME"
  echo "wim_index=$idx"
  echo "iso_sha256=$ISO_SHA256"
  echo "media_at=$(date -Iseconds)"
  echo "sku=IoTEnterpriseLTSC"
  echo "method=wininstall-setup"
  echo "install_part=$install_part"
} >"$MEDIA_READY"

log "done — Setup media on wininstall (part $install_part); no USB/external media"
log "next boot (BootNext): silent Setup → windows (part 3) → marker → reboot to NixOS"
if [[ $AUTO_REBOOT == "1" ]]; then
  log "rebooting into Windows Setup now"
  systemctl reboot
else
  log "AUTO_REBOOT=0 — reboot when ready to run Setup"
fi
