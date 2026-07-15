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

# pinentry-mac "Save in Keychain" stores wrong guesses under service GnuPG.
# Those poison later unlocks — delete on every preset cycle (Darwin only).
if [[ "$(uname -s)" == Darwin ]]; then
  while /usr/bin/security delete-generic-password -s 'GnuPG' >/dev/null 2>&1; do
    log "deleted GnuPG Keychain item"
  done
fi

preset_file() {
  local pass_file=$1
  [[ -r $pass_file ]] || return 0
  local pp
  pp=$(tr -d '\r\n' <"$pass_file")
  [[ -n $pp && $pp != placeholder ]] || return 0

  local grips grip
  grips=$("$GPG" --batch --with-colons --with-keygrip --list-secret-keys 2>/dev/null |
    awk -F: '/^grp:/ { print $10 }' || true)
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

# Ensure agent is up (best-effort).
"$GPG" --batch --list-secret-keys >/dev/null 2>&1 || true

preset_file "${DENDRITIC_GPG_PASSPHRASE_FILE:-}"
preset_file "${DENDRITIC_GPG_PASSPHRASE_PREVIOUS_FILE:-}"
log "done"
