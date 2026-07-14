#!/usr/bin/env bash
# Mass-rewrap every sops-encrypted file in this repo against the current
# recipient set in .sops.yaml.
#
# When to run:
#   - after adding/removing an age recipient in .sops.yaml,
#   - before retiring an old key (so files stop being encrypted to it),
#   - after onboarding a new machine/user that needs decryption access.
#
# What this does NOT do:
#   - generate new keys (use age-keygen or ssh-to-age),
#   - update .sops.yaml itself (that's a manual edit),
#   - decrypt or re-encrypt payloads (the data key gets re-wrapped, the
#     underlying ciphertext payload stays unchanged).
#
# Add new sops-encrypted files to FILES below as the surface grows.
set -euo pipefail

REPO_ROOT="${DOTFILES_ROOT:-}"
if [[ -z $REPO_ROOT || ! -f $REPO_ROOT/.sops.yaml ]]; then
  REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi
if [[ -z $REPO_ROOT || ! -f $REPO_ROOT/.sops.yaml ]]; then
  echo "fatal: cannot find .dotfiles root (set DOTFILES_ROOT or run from the checkout)" >&2
  exit 1
fi
cd "$REPO_ROOT"

if [ ! -f .sops.yaml ]; then
  echo "fatal: .sops.yaml not found at repo root ($REPO_ROOT)" >&2
  echo "       sops updatekeys needs the recipient config to rewrap." >&2
  exit 1
fi

if ! command -v sops >/dev/null 2>&1; then
  echo "fatal: 'sops' not in PATH. Install via 'nix shell nixpkgs#sops' or" >&2
  echo "       enter the repo devshell." >&2
  exit 1
fi

FILES=(
  "secrets/secrets.yaml"
  "secrets/sliceanddice-secrets.yaml"
)

failed=()
skipped=()
for f in "${FILES[@]}"; do
  if [ ! -f "$f" ]; then
    echo "skip: $f (missing)"
    continue
  fi
  echo "==> sops updatekeys $f"
  if ! sops updatekeys --yes "$f"; then
    echo "warn: could not rewrap $f (no local identity can decrypt — run updatekeys on a host that can)" >&2
    skipped+=("$f")
  fi
done

if [ ${#skipped[@]} -gt 0 ]; then
  echo >&2
  echo "note: ${#skipped[@]} file(s) not rewrapped here:" >&2
  printf '       - %s\n' "${skipped[@]}" >&2
  # Fail hard only if the primary shared secrets file was among them.
  for f in "${skipped[@]}"; do
    if [ "$f" = "secrets/secrets.yaml" ]; then
      exit 1
    fi
  done
fi

echo
echo "Done. Commit the rewrapped files together."
