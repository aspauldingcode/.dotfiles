#!/usr/bin/env bash
# Sync or restore SSH / GnuPG / password-store vault on PARTLABEL=nixinstall.
# Usage:
#   dendritic-vault-sync              # live home → /mnt/nixinstall/vault
#   dendritic-vault-restore [ROOT]    # vault → ROOT/home/alex (default /mnt)
set -euo pipefail

MODE="${1:-sync}"
TARGET_ROOT="${2:-/mnt}"
VAULT_MNT="${DENDRITIC_VAULT_MNT:-/mnt/nixinstall}"
VAULT="$VAULT_MNT/vault"
USER_NAME="${DENDRITIC_VAULT_USER:-alex}"

log() { echo "dendritic-vault: $*"; }
die() {
  echo "dendritic-vault: ERROR: $*" >&2
  exit 1
}

ensure_mount() {
  # When booted from nixinstall, vault is on the installer's own root.
  if [[ $VAULT_MNT == / ]]; then
    VAULT="/vault"
    [[ -d $VAULT ]] || die "vault missing at /vault (booted from nixinstall?)"
    return
  fi
  mkdir -p "$VAULT_MNT"
  if ! findmnt -n "$VAULT_MNT" >/dev/null 2>&1; then
    dev="$(readlink -f /dev/disk/by-partlabel/nixinstall 2>/dev/null || true)"
    [[ -b $dev ]] || die "PARTLABEL=nixinstall missing — create via bootstrap first"
    mount -t ext4 "$dev" "$VAULT_MNT" || die "mount nixinstall failed"
  fi
}

sync_vault() {
  ensure_mount
  mkdir -p "$VAULT"/{ssh,gnupg,password-store}
  local home="/home/$USER_NAME"
  [[ -d $home ]] || die "home $home missing"

  if [[ -d $home/.ssh ]]; then
    rsync -aH --delete "$home/.ssh/" "$VAULT/ssh/"
    log "synced .ssh"
  else
    log "WARNING: $home/.ssh missing"
  fi

  if [[ -d $home/.gnupg ]]; then
    rsync -aH --delete "$home/.gnupg/" "$VAULT/gnupg/"
    log "synced .gnupg"
  else
    log "WARNING: $home/.gnupg missing"
  fi

  local passdir="${PASSWORD_STORE_DIR:-$home/.password-store}"
  if [[ -d $passdir ]]; then
    rsync -aH --delete "$passdir/" "$VAULT/password-store/"
    log "synced password-store"
  else
    log "WARNING: password-store missing at $passdir"
  fi

  {
    echo "user=$USER_NAME"
    echo "synced_at=$(date -Iseconds)"
    echo "host=$(hostname)"
  } >"$VAULT/META"
  chmod -R go-rwx "$VAULT" || true
  sync
  log "vault OK at $VAULT"
}

restore_vault() {
  ensure_mount
  [[ -d $VAULT/ssh ]] || die "vault empty at $VAULT — run dendritic-vault-sync first"
  local home="$TARGET_ROOT/home/$USER_NAME"
  mkdir -p "$home"
  if [[ -d $VAULT/ssh ]]; then
    mkdir -p "$home/.ssh"
    rsync -aH "$VAULT/ssh/" "$home/.ssh/"
    chmod 700 "$home/.ssh"
    find "$home/.ssh" -type f -exec chmod 600 {} \;
    log "restored .ssh → $home/.ssh"
  fi
  if [[ -d $VAULT/gnupg ]]; then
    mkdir -p "$home/.gnupg"
    rsync -aH "$VAULT/gnupg/" "$home/.gnupg/"
    chmod 700 "$home/.gnupg"
    log "restored .gnupg → $home/.gnupg"
  fi
  if [[ -d $VAULT/password-store ]]; then
    mkdir -p "$home/.password-store"
    rsync -aH "$VAULT/password-store/" "$home/.password-store/"
    log "restored password-store → $home/.password-store"
  fi
  if [[ -n ${SUDO_UID:-} ]]; then
    chown -R "$SUDO_UID:${SUDO_GID:-$SUDO_UID}" "$home/.ssh" "$home/.gnupg" "$home/.password-store" 2>/dev/null || true
  elif id "$USER_NAME" >/dev/null 2>&1; then
    chown -R "$USER_NAME:$USER_NAME" "$home/.ssh" "$home/.gnupg" "$home/.password-store" 2>/dev/null || true
  fi
  log "restore done under $home"
}

case "$MODE" in
sync) sync_vault ;;
restore)
  TARGET_ROOT="${2:-/mnt}"
  restore_vault
  ;;
check)
  ensure_mount
  [[ -f $VAULT/META ]] || die "vault META missing"
  [[ -d $VAULT/ssh ]] || die "vault ssh missing"
  log "vault present ($(cat "$VAULT/META" | tr '\n' ' '))"
  ;;
*)
  die "usage: dendritic-vault-sync | dendritic-vault-restore [ROOT] | dendritic-vault check"
  ;;
esac
