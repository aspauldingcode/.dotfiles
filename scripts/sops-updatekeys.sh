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

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
)

failed=()
for f in "${FILES[@]}"; do
  if [ ! -f "$f" ]; then
    echo "skip: $f (missing)"
    continue
  fi
  echo "==> sops updatekeys $f"
  if ! sops updatekeys --yes "$f"; then
    failed+=("$f")
  fi
done

if [ ${#failed[@]} -gt 0 ]; then
  echo >&2
  echo "fatal: updatekeys failed for ${#failed[@]} file(s):" >&2
  printf '       - %s\n' "${failed[@]}" >&2
  exit 1
fi

echo
echo "Done. Commit the rewrapped files together."
