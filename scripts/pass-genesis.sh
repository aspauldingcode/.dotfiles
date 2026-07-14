#!/usr/bin/env bash
# One-time genesis: GPG identity + sops seed + local pass init.
set -euo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SOPS_FILE="${SOPS_FILE:-$DOTFILES_ROOT/secrets/secrets.yaml}"
PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
GPG_NAME="${GPG_NAME:-Alex Spaulding}"
GPG_EMAIL="${GPG_EMAIL:-alex@aspauldingcode.com}"
GNUPGHOME="${GNUPGHOME:-$HOME/.gnupg}"

export PASSWORD_STORE_DIR GNUPGHOME

die() {
  echo "error: $*" >&2
  exit 1
}
need() { command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"; }

need gpg
need pass
need sops
need openssl
need git

mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
cd "$DOTFILES_ROOT"

if [[ -f "$PASSWORD_STORE_DIR/.gpg-id" ]] && [[ -s "$PASSWORD_STORE_DIR/.gpg-id" ]]; then
  echo "pass store already initialized at $PASSWORD_STORE_DIR (.gpg-id present)."
  echo "Refusing to re-run genesis. Use pass-rotate for key rotation."
  exit 0
fi

PASSPHRASE="$(openssl rand -base64 32 | tr -d '\n')"
BATCH="$(mktemp)"
KEY_EXPORT="$(mktemp)"
PP_FILE="$(mktemp)"
trap 'rm -f "$BATCH" "$KEY_EXPORT" "$PP_FILE"' EXIT

cat >"$BATCH" <<EOF
%echo Generating Alex Spaulding pass master key
Key-Type: eddsa
Key-Curve: Ed25519
Subkey-Type: ecdh
Subkey-Curve: Curve25519
Name-Real: ${GPG_NAME}
Name-Email: ${GPG_EMAIL}
Expire-Date: 0
Passphrase: ${PASSPHRASE}
%commit
%echo done
EOF

echo "Generating GPG key for ${GPG_NAME} <${GPG_EMAIL}>..."
gpg --batch --generate-key "$BATCH"

FPR="$(gpg --batch --with-colons --list-secret-keys "$GPG_EMAIL" | awk -F: '/^fpr:/ { print $10; exit }')"
[[ -n $FPR ]] || die "failed to resolve GPG fingerprint"
echo "Fingerprint: $FPR"

gpg --batch --yes --pinentry-mode loopback --passphrase "$PASSPHRASE" \
  --armor --export-secret-keys "$FPR" >"$KEY_EXPORT"
printf '%s' "$PASSPHRASE" >"$PP_FILE"

echo "Writing GPG material into $SOPS_FILE via sops set..."
# JSON-string encode via python for sops set value argument
json_str() { python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'; }

sops set "$SOPS_FILE" '["gpg_private_key"]' "$(json_str <"$KEY_EXPORT")"
sops set "$SOPS_FILE" '["gpg_passphrase"]' "$(json_str <"$PP_FILE")"
sops set "$SOPS_FILE" '["gpg_private_key_previous"]' '"placeholder"'
sops set "$SOPS_FILE" '["gpg_passphrase_previous"]' '"placeholder"'

mkdir -p "$PASSWORD_STORE_DIR"
pass init "$FPR"
if [[ ! -d "$PASSWORD_STORE_DIR/.git" ]]; then
  git -C "$PASSWORD_STORE_DIR" init
fi
git -C "$PASSWORD_STORE_DIR" config user.name "$GPG_NAME"
git -C "$PASSWORD_STORE_DIR" config user.email "$GPG_EMAIL"

mkdir -p "$DOTFILES_ROOT/docs"
printf '%s\n' "$FPR" >"$DOTFILES_ROOT/docs/pass-gpg-fingerprint.txt"
python3 - <<PY
import json
from pathlib import Path
from datetime import datetime, timezone
Path("$DOTFILES_ROOT/docs/pass-rotation-state.json").write_text(
    json.dumps({
        "fingerprint": "$FPR",
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "pending_finalize": False,
    }, indent=2) + "\n"
)
PY

echo "Genesis complete."
echo "  fingerprint: $FPR"
echo "  store:       $PASSWORD_STORE_DIR"
echo "  sops:        $SOPS_FILE"
