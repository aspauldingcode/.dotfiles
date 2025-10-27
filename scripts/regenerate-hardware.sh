#!/usr/bin/env bash
set -euo pipefail

# Regenerate NixOS hardware-configuration.nix into this repo per host.
# Run this on the NixOS machine.

# Ensure we're on NixOS
if ! grep -qi 'ID=nixos' /etc/os-release; then
  echo "This script must be run on a NixOS host." >&2
  exit 1
fi

# Determine host name
HOST="$(hostnamectl --static 2>/dev/null || hostname -s || hostname)"

# Resolve repo root relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_DIR="${REPO_ROOT}/hardware"
mkdir -p "${TARGET_DIR}"
echo "Regenerating ${TARGET_DIR}/${HOST}.nix for host '${HOST}'..."
sudo nixos-generate-config --show-hardware-config | tee "${TARGET_DIR}/${HOST}.nix" >/dev/null
echo "Wrote: ${TARGET_DIR}/${HOST}.nix"

# Determine target output name
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)
    SYSTEM="x86_64-linux" ;;
  aarch64|arm64)
    SYSTEM="aarch64-linux" ;;
  *)
    SYSTEM="x86_64-linux" ;;
esac
echo "${SYSTEM}" > "${TARGET_DIR}/${HOST}.system"
echo "To switch: sudo nixos-rebuild switch --flake ${REPO_ROOT}#${HOST}"