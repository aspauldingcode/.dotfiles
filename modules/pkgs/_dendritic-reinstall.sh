#!/usr/bin/env bash
# From sliceanddice-installer: format main nixos as btrfs via disko, nixos-install, vault-restore.
set -euo pipefail

FLAKE="${DENDRITIC_FLAKE:-/mnt/nixinstall/flake}"
TARGET_ATTR="${DENDRITIC_TARGET_ATTR:-sliceanddice}"
DISK_ROOT="/mnt"
YES="${DENDRITIC_REINSTALL_YES:-0}"

log() { echo "dendritic-reinstall: $*"; }
die() {
  echo "dendritic-reinstall: ERROR: $*" >&2
  exit 1
}

[[ $(id -u) -eq 0 ]] || die "run as root"
hostname | grep -q installer || log "WARNING: expected installer hostname"

if [[ $YES != "1" ]]; then
  echo "This will DESTROY PARTLABEL=nixos and reinstall $TARGET_ATTR from $FLAKE"
  echo "Vault on nixinstall must already exist (dendritic-vault-sync)."
  read -r -p "Type reinstall to continue: " ans
  [[ $ans == "reinstall" ]] || die "aborted"
fi

command -v dendritic-vault-sync >/dev/null && dendritic-vault-sync check ||
  die "vault check failed — boot main OS and run dendritic-vault-sync first"

[[ -e $FLAKE/flake.nix ]] || die "flake not found at $FLAKE — bootstrap should copy .dotfiles here"

log "disko destroy+format+mount for $TARGET_ATTR (nixinstall partition is not wiped by installer policy)"
# disko formats according to flake; nixinstall is a separate partition that stays mounted as /
nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- \
  --flake "$FLAKE#$TARGET_ATTR" \
  --mode destroy,format,mount

log "nixos-install $FLAKE#$TARGET_ATTR"
nixos-install --flake "$FLAKE#$TARGET_ATTR" --root "$DISK_ROOT" --no-root-password --no-channel-copy

log "vault-restore into $DISK_ROOT"
dendritic-vault-restore "$DISK_ROOT" || die "vault-restore failed"

# After btrfs install, liveExt4Compat should be false — ensure in flake; installer copies current flake.
log "done — reboot into $TARGET_ATTR (btrfs). Set dendritic.disk.liveExt4Compat = false on first nh os switch if needed."
