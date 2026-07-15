#!/usr/bin/env bash
# From sliceanddice-installer: reformat PARTLABEL=nixos as btrfs, carve
# windows/wininstall/swap in the gap before nixinstall, nixos-install, vault-restore.
#
# NEVER sgdisk --clear / disko destroy — that would wipe nixinstall (live root + vault).
set -euo pipefail

FLAKE="${DENDRITIC_FLAKE:-/flake}"
[[ -e $FLAKE/flake.nix ]] || FLAKE="/mnt/nixinstall/flake"
TARGET_ATTR="${DENDRITIC_TARGET_ATTR:-sliceanddice}"
DISK_ROOT="/mnt"
YES="${DENDRITIC_REINSTALL_YES:-0}"
DISK="${DENDRITIC_DISK:-/dev/disk/by-id/ata-Samsung_SSD_870_EVO_500GB_S62ANJ0R238724D}"

WINDOWS_GIB=64
WININSTALL_GIB=8
MIN_SWAP_GIB=4
MIN_NIXOS_GIB=100

log() { echo "dendritic-reinstall: $*"; }
die() {
  echo "dendritic-reinstall: ERROR: $*" >&2
  exit 1
}

[[ $(id -u) -eq 0 ]] || die "run as root"
hostname | grep -q installer || log "WARNING: expected installer hostname"

if [[ $YES != "1" ]]; then
  echo "This will DESTROY PARTLABEL=nixos (ext4→btrfs) and carve windows/wininstall/swap."
  echo "PARTLABEL=nixinstall (this root + vault) is preserved."
  read -r -p "Type reinstall to continue: " ans
  [[ $ans == "reinstall" ]] || die "aborted"
fi

if [[ -d /vault/ssh ]]; then
  export DENDRITIC_VAULT_MNT=/
elif [[ -d /mnt/nixinstall/vault/ssh ]]; then
  export DENDRITIC_VAULT_MNT=/mnt/nixinstall
else
  die "vault missing — boot main OS and run dendritic-vault-sync first"
fi

if command -v dendritic-vault-sync >/dev/null; then
  dendritic-vault-sync check || die "vault check failed"
else
  die "dendritic-vault-sync missing from PATH"
fi

[[ -e $FLAKE/flake.nix ]] || die "flake not found at $FLAKE"
[[ -b $DISK ]] || die "disk $DISK missing"
[[ -b /dev/disk/by-partlabel/nixinstall ]] || die "nixinstall partition missing"
[[ -b /dev/disk/by-partlabel/ESP ]] || die "ESP missing"

nixinstall_dev="$(readlink -f /dev/disk/by-partlabel/nixinstall)"
nixinstall_start="$(cat "/sys/class/block/$(basename "$nixinstall_dev")/start")"
[[ -n $nixinstall_start && $nixinstall_start -gt 0 ]] || die "could not read nixinstall start sector"

esp_dev="$(readlink -f /dev/disk/by-partlabel/ESP)"
esp_start="$(cat "/sys/class/block/$(basename "$esp_dev")/start")"
esp_size="$(cat "/sys/class/block/$(basename "$esp_dev")/size")"
nixos_start=$((esp_start + esp_size))
nixos_start=$(((nixos_start + 2047) / 2048 * 2048))

sectors_per_gib=$((1024 * 1024 * 1024 / 512))
win_sect=$(((WINDOWS_GIB * sectors_per_gib + 2047) / 2048 * 2048))
wini_sect=$(((WININSTALL_GIB * sectors_per_gib + 2047) / 2048 * 2048))
min_swap_sect=$((MIN_SWAP_GIB * sectors_per_gib))
min_nixos_sect=$((MIN_NIXOS_GIB * sectors_per_gib))

# Layout: nixos | windows | wininstall | swap | nixinstall(fixed)
# Place windows+wininstall+min_swap just before nixinstall; swap absorbs alignment slack.
nixos_end=$((nixinstall_start - win_sect - wini_sect - min_swap_sect))
nixos_end=$((nixos_end / 2048 * 2048))
[[ $((nixos_end - nixos_start)) -ge $min_nixos_sect ]] || die "nixos would be too small"

win_start=$nixos_end
wini_start=$((win_start + win_sect))
swap_start=$((wini_start + wini_sect))
swap_size=$((nixinstall_start - swap_start))
[[ $swap_size -ge $min_swap_sect ]] || die "swap region too small ($swap_size sectors)"

log "plan: nixos [$nixos_start,$nixos_end) win@$win_start wini@$wini_start swap@$swap_start+${swap_size} (nixinstall @$nixinstall_start untouched)"

umount -R "$DISK_ROOT" 2>/dev/null || true
swapoff -a 2>/dev/null || true

log "repartition: shrink nixos, add windows/wininstall/swap (preserve nixinstall)"
sgdisk -d 2 "$DISK" || true
for n in 4 5 6 7 8 9; do
  sgdisk -d "$n" "$DISK" 2>/dev/null || true
done
sgdisk \
  -n "2:$nixos_start:$((nixos_end - 1))" -c 2:nixos -t 2:8300 \
  -n "4:$win_start:$((wini_start - 1))" -c 4:windows -t 4:0700 \
  -n "5:$wini_start:$((swap_start - 1))" -c 5:wininstall -t 5:0700 \
  -n "6:$swap_start:$((nixinstall_start - 1))" -c 6:swap -t 6:8200 \
  "$DISK"

partprobe "$DISK" 2>/dev/null || partx -u "$DISK" 2>/dev/null || true
udevadm settle || true
sleep 1

[[ -b /dev/disk/by-partlabel/nixos ]] || die "nixos partlabel missing after repartition"
[[ -b /dev/disk/by-partlabel/nixinstall ]] || die "nixinstall vanished — abort"
[[ -b /dev/disk/by-partlabel/windows ]] || die "windows partlabel missing"
[[ -b /dev/disk/by-partlabel/wininstall ]] || die "wininstall partlabel missing"
[[ -b /dev/disk/by-partlabel/swap ]] || die "swap partlabel missing"

log "mkfs: btrfs nixos + ntfs windows/wininstall + swap"
mkfs.btrfs -f -L nixos /dev/disk/by-partlabel/nixos
mkfs.ntfs -F -L windows /dev/disk/by-partlabel/windows
mkfs.ntfs -F -L wininstall /dev/disk/by-partlabel/wininstall
mkswap -L swap /dev/disk/by-partlabel/swap

log "btrfs subvolumes"
mkdir -p /mnt
mount -t btrfs /dev/disk/by-partlabel/nixos /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
umount /mnt

btrfs_opts="compress=zstd,ssd,noatime,discard=async"
mount -t btrfs -o "subvol=@,$btrfs_opts" /dev/disk/by-partlabel/nixos /mnt
mkdir -p /mnt/{nix,home,var/log,boot,mnt/nixinstall,mnt/windows,mnt/wininstall}
mount -t btrfs -o "subvol=@nix,$btrfs_opts" /dev/disk/by-partlabel/nixos /mnt/nix
mount -t btrfs -o "subvol=@home,$btrfs_opts" /dev/disk/by-partlabel/nixos /mnt/home
mount -t btrfs -o "subvol=@log,$btrfs_opts" /dev/disk/by-partlabel/nixos /mnt/var/log
mount /dev/disk/by-partlabel/ESP /mnt/boot

log "nixos-install $FLAKE#$TARGET_ATTR (liveExt4Compat must be false in flake)"
nixos-install --flake "$FLAKE#$TARGET_ATTR" --root "$DISK_ROOT" --no-root-password --no-channel-copy

log "vault-restore into $DISK_ROOT"
dendritic-vault-restore "$DISK_ROOT" || die "vault-restore failed"

log "done — reboot into sliceanddice (btrfs). nixinstall preserved."
