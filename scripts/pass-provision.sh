#!/usr/bin/env bash
# Full live provision: genesis + private GH repo + template secrets + CI key + Actions secrets.
set -euo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
PASSWORD_STORE_DIR="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
STORE_REPO="${STORE_REPO:-aspauldingcode/.password-store}"
GNUPGHOME="${GNUPGHOME:-$HOME/.gnupg}"
GPG_NAME="${GPG_NAME:-Alex Spaulding}"
GPG_EMAIL="${GPG_EMAIL:-alex@aspauldingcode.com}"

export PASSWORD_STORE_DIR GNUPGHOME DOTFILES_ROOT

die() {
  echo "error: $*" >&2
  exit 1
}
need() { command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"; }

need gh
need gpg
need pass
need git
need sops
need openssl

# Prefer existing token; otherwise lift from sops (same source as modules/apps/gh.nix).
if [[ -z ${GH_TOKEN:-} && -z ${GITHUB_TOKEN:-} ]]; then
  export GH_TOKEN
  GH_TOKEN="$(sops -d --extract '["gh_token"]' "$DOTFILES_ROOT/secrets/secrets.yaml" | tr -d '[:space:]')"
fi

cd "$DOTFILES_ROOT"
chmod +x "$DOTFILES_ROOT/scripts/pass-genesis.sh" "$DOTFILES_ROOT/scripts/pass-rotate-gpg.sh"

echo "==> Running genesis..."
"$DOTFILES_ROOT/scripts/pass-genesis.sh"

FPR="$(tr -d '[:space:]' <"$DOTFILES_ROOT/docs/pass-gpg-fingerprint.txt")"
[[ -n $FPR ]] || die "missing fingerprint after genesis"
PASSPHRASE="$(sops -d --extract '["gpg_passphrase"]' "$DOTFILES_ROOT/secrets/secrets.yaml")"
export PASSWORD_STORE_GPG_OPTS="--pinentry-mode loopback --passphrase ${PASSPHRASE}"

# Preset passphrase for inserts / decrypts
PRESET=""
for c in \
  "$(dirname "$(command -v gpg)")/../libexec/gpg-preset-passphrase" \
  /opt/homebrew/libexec/gpg-preset-passphrase \
  /run/current-system/sw/libexec/gpg-preset-passphrase; do
  [[ -x $c ]] && PRESET="$c" && break
done
# Resolve via nix if needed
if [[ -z $PRESET ]]; then
  PRESET="$(nix --extra-experimental-features 'nix-command flakes' eval --raw nixpkgs#gnupg.outPath 2>/dev/null)/libexec/gpg-preset-passphrase" || true
  [[ -x $PRESET ]] || PRESET=""
fi
if [[ -n $PRESET ]]; then
  gpg --batch --with-colons --with-keygrip --list-secret-keys |
    awk -F: '/^grp:/ { print $10 }' |
    while read -r grip; do
      [[ -n $grip ]] || continue
      printf '%s' "$PASSPHRASE" | "$PRESET" --preset "$grip" || true
    done
fi

insert_multiline() {
  local path="$1"
  local content="$2"
  printf '%s\n' "$content" | pass insert -m -f "$path"
}

insert_echo() {
  local path="$1"
  local content="$2"
  printf '%s\n' "$content" | pass insert -e -f "$path"
}

echo "==> Seeding template passwords..."
insert_echo "_bootstrap/ok" "ok"
insert_multiline "test/example-login" $'user: demo@example.com\npassword: demo-password-not-real'
insert_echo "secretspec/shared/default/DEMO_API_KEY" "demo-not-a-real-key"
insert_echo "secretspec/shared/default/DEMO_DATABASE_URL" "postgres://demo:demo@localhost/demo"

echo "==> Creating CI-only GPG identity..."
CI_PASSPHRASE="$(openssl rand -base64 24 | tr -d '\n')"
CI_BATCH="$(mktemp)"
CI_KEY="$(mktemp)"
trap 'rm -f "$CI_BATCH" "$CI_KEY"' EXIT
cat >"$CI_BATCH" <<EOF
%echo Generating CI canary key for password-store smoke tests
Key-Type: eddsa
Key-Curve: Ed25519
Subkey-Type: ecdh
Subkey-Curve: Curve25519
Name-Real: Password Store CI
Name-Email: pass-ci@aspauldingcode.com
Expire-Date: 0
Passphrase: ${CI_PASSPHRASE}
%commit
%echo done
EOF
gpg --batch --generate-key "$CI_BATCH"
CI_FPR="$(gpg --batch --with-colons --list-secret-keys pass-ci@aspauldingcode.com | awk -F: '/^fpr:/ { print $10; exit }')"
[[ -n $CI_FPR ]] || die "failed to create CI GPG key"
gpg --batch --yes --pinentry-mode loopback --passphrase "$CI_PASSPHRASE" \
  --armor --export-secret-keys "$CI_FPR" >"$CI_KEY"
printf '%s\n' "$CI_FPR" >"$PASSWORD_STORE_DIR/.ci-gpg-id"

echo "==> Dual-encrypting template paths for Alex + CI..."
dual_encrypt() {
  local rel="$1"
  local file="$PASSWORD_STORE_DIR/${rel}.gpg"
  [[ -f $file ]] || die "missing $file"
  local plain tmp
  plain="$(mktemp)"
  tmp="$(mktemp)"
  gpg --batch --quiet --pinentry-mode loopback --passphrase "$PASSPHRASE" --decrypt "$file" >"$plain"
  gpg --batch --yes --trust-model always \
    --recipient "$FPR" --recipient "$CI_FPR" \
    --encrypt --output "$tmp" "$plain"
  mv "$tmp" "$file"
  rm -f "$plain"
}
dual_encrypt "_bootstrap/ok"
dual_encrypt "test/example-login"
dual_encrypt "secretspec/shared/default/DEMO_API_KEY"
dual_encrypt "secretspec/shared/default/DEMO_DATABASE_URL"

echo "==> Ensuring private GitHub repo $STORE_REPO exists..."
if gh repo view "$STORE_REPO" >/dev/null 2>&1; then
  echo "Repo already exists."
else
  gh repo create "$STORE_REPO" --private \
    --description "Encrypted pass password-store (GPG). Template secrets only for CI canary key."
fi

if [[ ! -d "$PASSWORD_STORE_DIR/.git" ]]; then
  git -C "$PASSWORD_STORE_DIR" init
fi
git -C "$PASSWORD_STORE_DIR" config user.name "$GPG_NAME"
git -C "$PASSWORD_STORE_DIR" config user.email "$GPG_EMAIL"

# Install CI workflow into the store repo before first push
mkdir -p "$PASSWORD_STORE_DIR/.github/workflows"
cp "$DOTFILES_ROOT/scripts/password-store-secrets-smoke.yml" \
  "$PASSWORD_STORE_DIR/.github/workflows/secrets-smoke.yml"
# Embed demo secretspec.toml for CI
mkdir -p "$PASSWORD_STORE_DIR/.ci"
cp "$DOTFILES_ROOT/testdata/secretspec-demo/secretspec.toml" \
  "$PASSWORD_STORE_DIR/.ci/secretspec.toml"

# README (no secrets)
cat >"$PASSWORD_STORE_DIR/README.md" <<'EOF'
# Password store

Private GPG-encrypted [`pass`](https://www.passwordstore.org/) store for Alex Spaulding.

- Personal secrets: encrypted to Alex's GPG key only.
- Template/CI canaries under `_bootstrap/`, `test/`, and `secretspec/shared/default/DEMO_*` are dual-encrypted to Alex + CI canary key for GitHub Actions smoke tests.
- Never commit plaintext. Sync with `pass git push` / `pass git pull`.
EOF

git -C "$PASSWORD_STORE_DIR" add -A
git -C "$PASSWORD_STORE_DIR" commit -m "Initial encrypted password-store with template secrets" || true

# Set remote and push
if git -C "$PASSWORD_STORE_DIR" remote get-url origin >/dev/null 2>&1; then
  git -C "$PASSWORD_STORE_DIR" remote set-url origin "git@github.com:${STORE_REPO}.git"
else
  git -C "$PASSWORD_STORE_DIR" remote add origin "git@github.com:${STORE_REPO}.git"
fi
git -C "$PASSWORD_STORE_DIR" branch -M main
git -C "$PASSWORD_STORE_DIR" push -u origin main

echo "==> Setting GitHub Actions secrets on $STORE_REPO..."
gh secret set CI_GPG_PRIVATE_KEY --repo "$STORE_REPO" <"$CI_KEY"
printf '%s' "$CI_PASSPHRASE" | gh secret set CI_GPG_PASSPHRASE --repo "$STORE_REPO"

# Keep CI *public* key locally for dual-encrypt during future rotations; drop secret.
gpg --batch --yes --armor --export "$CI_FPR" >"${CI_KEY}.pub"
gpg --batch --yes --delete-secret-and-public-keys "$CI_FPR"
gpg --batch --yes --import "${CI_KEY}.pub"
rm -f "${CI_KEY}.pub"

echo
echo "Provision complete."
echo "  store repo:  https://github.com/$STORE_REPO"
echo "  fingerprint: $FPR"
echo "  ci fpr:      $CI_FPR"
echo "  Next: enable dendritic.apps.pass on hosts and rebuild."
