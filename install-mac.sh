#!/usr/bin/env bash

# Bootstraps Nix and applies the macOS configuration

set -e

# Always source Nix if it exists to ensure it is in the PATH
if [ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
  . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
fi

# 1. Install Nix via Determinate Systems if missing
if ! command -v nix &> /dev/null; then
  echo "Nix not found. Installing Determinate Systems Nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
  . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
fi

# 2. Apply nix-darwin configuration
HOSTNAME="${1:-mba}"
echo "Applying nix-darwin configuration for '$HOSTNAME'..."

# If we are being piped into bash, $0 is bash. Require being run from the clone.
if [[ "$0" == *"bash"* ]] || [[ "$0" == *"/dev/fd/"* ]]; then
  echo "Error: Please run this script directly from the cloned repository, not via a pipe."
  exit 1
fi

cd "$(dirname "$0")"
nix --extra-experimental-features "nix-command flakes" run nix-darwin/master#darwin-rebuild -- switch --flake ".#${HOSTNAME}"

echo "Installation complete!"
