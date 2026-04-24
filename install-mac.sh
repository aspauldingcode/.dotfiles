#!/usr/bin/env bash

# Bootstraps Nix and applies the macOS configuration

set -e

# 1. Install Nix via Determinate Systems if missing
if ! command -v nix &> /dev/null; then
  echo "Nix not found. Installing Determinate Systems Nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# 2. Apply nix-darwin configuration
HOSTNAME="${1:-mba}"
echo "Applying nix-darwin configuration for '$HOSTNAME'..."

cd "$(dirname "$0")"
nix --extra-experimental-features "nix-command flakes" run nix-darwin/master#darwin-rebuild -- switch --flake ".#${HOSTNAME}"

echo "Installation complete!"
