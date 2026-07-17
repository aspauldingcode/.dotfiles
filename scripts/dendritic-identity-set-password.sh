#!/usr/bin/env bash
# Set shared NixOS/Windows login password in the private pass store, materialize,
# and restart apply/sync units. Password is never written to sops or the flake.
#
# Usage:
#   ./scripts/dendritic-identity-set-password.sh
#   printf '%s' 'secret' | ./scripts/dendritic-identity-set-password.sh --stdin
set -euo pipefail

PASS_PATH="${DENDRITIC_IDENTITY_PASS_PATH:-secretspec/shared/default/LOGIN_PASSWORD}"
MATERIALIZE_REL="${DENDRITIC_IDENTITY_MATERIALIZE:-.config/dendritic/identity/login.password}"
out="${HOME}/${MATERIALIZE_REL}"

if [[ ${1:-} == "--stdin" ]]; then
  pw="$(cat)"
else
  read -r -s -p "Shared login password: " pw
  echo
  read -r -s -p "Confirm: " pw2
  echo
  [[ $pw == "$pw2" ]] || {
    echo "mismatch" >&2
    exit 1
  }
fi
[[ -n $pw ]] || {
  echo "empty password" >&2
  exit 1
}

export PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
tmp=$(mktemp)
chmod 600 "$tmp"
printf '%s\n' "$pw" >"$tmp"
# -e reads first line from stdin; -f overwrites.
pass insert -e -f "$PASS_PATH" <"$tmp"
rm -f "$tmp"
unset pw

umask 077
mkdir -p "$(dirname "$out")"
# Re-materialize just this key via secretspec when available; else pass show.
if command -v secretspec >/dev/null 2>&1 && [[ -f ${HOME}/.dotfiles/home/secretspec.toml || -f /etc/nixos/.dotfiles/home/secretspec.toml ]]; then
  toml=/etc/nixos/.dotfiles/home/secretspec.toml
  [[ -f $HOME/.dotfiles/home/secretspec.toml ]] && toml=$HOME/.dotfiles/home/secretspec.toml
  val="$(secretspec get -f "$toml" LOGIN_PASSWORD 2>/dev/null || true)"
  if [[ -n $val ]]; then
    printf '%s\n' "$val" >"$out"
  else
    pass show "$PASS_PATH" | head -n1 >"$out"
  fi
else
  pass show "$PASS_PATH" | head -n1 >"$out"
fi
chmod 600 "$out"

if command -v pass-materialize >/dev/null 2>&1; then
  pass-materialize >/dev/null 2>&1 || true
fi

echo "Updated pass:${PASS_PATH} and materialized ~/${MATERIALIZE_REL}" >&2
echo "Restarting identity / Windows sync units (if present)…" >&2
systemctl start dendritic-identity-apply-nixos-password.service 2>/dev/null || true
systemctl start dendritic-windows-ensure-password.service 2>/dev/null || true
systemctl start dendritic-windows-sync-login.service 2>/dev/null || true
echo 'Boot Windows once after sync-login stages C:\dendritic\sync-login.cmd.' >&2
