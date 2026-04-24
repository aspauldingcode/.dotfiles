#!/usr/bin/env bash

# Exit on error
set -e

echo "Ensuring nix-darwin is installed and configured using the local flake..."

# Change to the dotfiles directory
cd "$(dirname "$0")"

# We use nix run to evaluate and apply the nix-darwin configuration for this machine directly
# from the flake. We assume the configuration name is 'mba'.
# For other hosts, this might need to be parameterized.

if [ "$1" != "" ]; then
  HOSTNAME="$1"
else
  HOSTNAME="mba"
  echo "Defaulting to hostname 'mba'. Pass an argument to specify a different hostname (e.g. ./install-mac.sh my-macbook)"
fi

echo "Running darwin-rebuild for '$HOSTNAME'..."
# Provide the flake path to nix run
nix --extra-experimental-features "nix-command flakes" run nix-darwin/master#darwin-rebuild -- switch --flake ".#${HOSTNAME}"

echo ""
echo "Installation complete!"
echo "If you want to update it in the future, you can just use 'darwin-rebuild switch --flake .' or rerun this script."
