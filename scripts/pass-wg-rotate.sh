#!/usr/bin/env bash
# Rotate WireGuard pairing material in pass (keys and/or PSK).
#
#   pass-wg-rotate                 # rotate PSK + both keypairs (--force bootstrap)
#   pass-wg-rotate --psk-only      # rotate PSK only (peers keep identity keys)
#   pass-wg-rotate --keys-only     # rotate keypairs; keep PSK
#   pass-wg-rotate --status
#
# After rotate: peers must pass-materialize && dendritic-wg-ensure (or wait for
# materialize hook). Old private keys stop working immediately.
set -euo pipefail

PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
export PASSWORD_STORE_DIR DOTFILES_ROOT

PSK_ONLY=false
KEYS_ONLY=false
DO_STATUS=false

die() {
  echo "pass-wg-rotate: error: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --psk-only) PSK_ONLY=true ;;
  --keys-only) KEYS_ONLY=true ;;
  --status) DO_STATUS=true ;;
  -h | --help)
    sed -n '2,12p' "$0" | sed 's/^# //; s/^#//'
    exit 0
    ;;
  *) die "unknown arg: $1" ;;
  esac
  shift
done

SCRIPT="${DOTFILES_ROOT}/scripts/pass-wg-bootstrap.sh"
[[ -x $SCRIPT || -r $SCRIPT ]] || die "missing $SCRIPT"

if $DO_STATUS; then
  exec bash "$SCRIPT" --status
fi

if $PSK_ONLY && $KEYS_ONLY; then
  die "choose at most one of --psk-only / --keys-only"
fi

if $PSK_ONLY; then
  command -v wg >/dev/null || die "missing wg"
  command -v pass >/dev/null || die "missing pass"
  psk="$(wg genpsk)"
  printf '%s\n' "$psk" | pass insert -e -f secretspec/shared/default/WG_PSK >/dev/null
  git -C "$PASSWORD_STORE_DIR" add -A
  if git -C "$PASSWORD_STORE_DIR" status --porcelain | grep -q .; then
    git -C "$PASSWORD_STORE_DIR" -c user.name="pass-store-sync" \
      -c user.email="pass-store-sync@localhost" commit -m "rotate: WG_PSK" >/dev/null 2>&1 || true
    git -C "$PASSWORD_STORE_DIR" push >/dev/null 2>&1 || true
  fi
  echo "pass-wg-rotate: rotated WG_PSK — rematerialize + dendritic-wg-ensure on both peers"
  exit 0
fi

# Full or keys-only: reuse bootstrap --force (always regenerates PSK too unless we
# snapshot PSK). For keys-only, preserve PSK.
if $KEYS_ONLY; then
  old_psk="$(pass show secretspec/shared/default/WG_PSK 2>/dev/null | head -n1 || true)"
  bash "$SCRIPT" --force
  if [[ -n $old_psk ]]; then
    printf '%s\n' "$old_psk" | pass insert -e -f secretspec/shared/default/WG_PSK >/dev/null
    git -C "$PASSWORD_STORE_DIR" add -A
    git -C "$PASSWORD_STORE_DIR" -c user.name="pass-store-sync" \
      -c user.email="pass-store-sync@localhost" commit -m "rotate: WG keypairs (keep PSK)" >/dev/null 2>&1 || true
    git -C "$PASSWORD_STORE_DIR" push >/dev/null 2>&1 || true
  fi
  echo "pass-wg-rotate: rotated keypairs (PSK preserved)"
  exit 0
fi

exec bash "$SCRIPT" --force
