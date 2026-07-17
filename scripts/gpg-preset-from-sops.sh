#!/usr/bin/env bash
# Re-preset GPG passphrases from sops into gpg-agent, and (on Darwin)
# purge pinentry-mac GnuPG Keychain entries that fight the preset.
#
# Env:
#   DENDRITIC_GPG_PASSPHRASE_FILE
#   DENDRITIC_GPG_PASSPHRASE_PREVIOUS_FILE  (optional)
#   DENDRITIC_GPG_PRIVATE_KEY_FILE          (optional; re-import if missing)
set -euo pipefail

LOG_PREFIX="gpg-preset-from-sops"
log() { printf '%s %s: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$LOG_PREFIX" "$*"; }
warn() { log "warning: $*" >&2; }

GPG="${GPG:-gpg}"
PRESET="${GPG_PRESET_PASSPHRASE:-gpg-preset-passphrase}"

# Serialize overlapping path/timer starts (keyboxd lock storms).
LOCK_DIR="${GNUPGHOME:-${HOME:-/tmp}/.gnupg}"
mkdir -p "$LOCK_DIR" 2>/dev/null || true
LOCK_FILE="$LOCK_DIR/dendritic-preset.lock"
exec 9>"$LOCK_FILE" || true
if ! flock -n 9; then
  warn "another preset is running; skipping"
  exit 0
fi

# pinentry-mac "Save in Keychain" stores wrong guesses under service GnuPG.
# Those poison later unlocks — delete on every preset cycle (Darwin only).
if [[ "$(uname -s)" == Darwin ]]; then
  while /usr/bin/security delete-generic-password -s 'GnuPG' >/dev/null 2>&1; do
    log "deleted GnuPG Keychain item"
  done
fi

list_grips() {
  "$GPG" --batch --with-colons --with-keygrip --list-secret-keys 2>/dev/null |
    awk -F: '/^grp:/ { print $10 }' || true
}

maybe_import_key() {
  local key_file=$1
  local pass_file=$2
  [[ -n $key_file && -r $key_file ]] || return 0
  local key_content
  key_content=$(tr -d '\r' <"$key_file")
  [[ -n $key_content && $key_content != placeholder ]] || return 0
  if printf '%s\n' "$key_content" | "$GPG" --batch --import 2>/dev/null; then
    log "imported secret key"
    return 0
  fi
  [[ -r $pass_file ]] || return 0
  local pp
  pp=$(tr -d '\r\n' <"$pass_file")
  [[ -n $pp && $pp != placeholder ]] || return 0
  printf '%s\n' "$key_content" | "$GPG" --batch --yes \
    --pinentry-mode loopback --passphrase "$pp" --import 2>/dev/null || true
}

preset_file() {
  local pass_file=$1
  [[ -r $pass_file ]] || return 0
  local pp
  pp=$(tr -d '\r\n' <"$pass_file")
  [[ -n $pp && $pp != placeholder ]] || return 0

  local grips grip
  grips=$(list_grips)
  if [[ -z $grips ]]; then
    maybe_import_key "${DENDRITIC_GPG_PRIVATE_KEY_FILE:-}" "$pass_file"
    grips=$(list_grips)
  fi
  if [[ -z $grips ]]; then
    warn "no secret keygrips to preset"
    return 0
  fi
  while IFS= read -r grip; do
    [[ -n $grip ]] || continue
    if printf '%s' "$pp" | "$PRESET" --preset "$grip" 2>/dev/null; then
      log "preset ok grip=${grip:0:8}…"
    else
      warn "preset failed grip=${grip:0:8}…"
    fi
  done <<<"$grips"
}

preset_file "${DENDRITIC_GPG_PASSPHRASE_FILE:-}"
preset_file "${DENDRITIC_GPG_PASSPHRASE_PREVIOUS_FILE:-}"
log "done"
