#!/usr/bin/env bash
# Bootstrap sliceanddice with aspauldingcode/.dotfiles on NixOS.
# Run: sudo bash scripts/install-sliceanddice.sh
set -euo pipefail

TARGET_DIR="/etc/nixos/.dotfiles"
HOST="sliceanddice"
REPO_URL="https://github.com/aspauldingcode/.dotfiles.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo bash $0"
  exit 1
fi

# Back up existing dotfiles checkout if present
if [[ -d $TARGET_DIR && ! -f "$TARGET_DIR/flake.nix" ]]; then
  BAK="${TARGET_DIR}.bak.$(date +%Y%m%d%H%M%S)"
  echo "Backing up $TARGET_DIR -> $BAK"
  cp -a "$TARGET_DIR" "$BAK"
fi

# Preserve legacy hardware scan if /etc/nixos still has one
LEGACY_HW="/etc/nixos/hardware-configuration.nix"
HOST_HW="$SOURCE_DIR/hosts/nixos/sliceanddice/hardware-configuration.nix"
if [[ -f $LEGACY_HW && ! -f $HOST_HW ]]; then
  mkdir -p "$(dirname "$HOST_HW")"
  cp "$LEGACY_HW" "$HOST_HW"
fi

if [[ ! -f "$TARGET_DIR/flake.nix" ]]; then
  echo "Deploying dotfiles to $TARGET_DIR..."
  mkdir -p "$TARGET_DIR"
  rsync -a --delete "$SOURCE_DIR/" "$TARGET_DIR/"
else
  echo "Updating $TARGET_DIR from prepared source..."
  rsync -a "$SOURCE_DIR/" "$TARGET_DIR/"
fi

cd "$TARGET_DIR"

# Thin entrypoint so `nh os switch` works from /etc/nixos (repo stays in .dotfiles/).
echo "Installing /etc/nixos/flake.nix wrapper..."
install -Dm644 "$SOURCE_DIR/nixos/flake.nix" /etc/nixos/flake.nix

echo "First switch via nixos-rebuild (bootstrap)..."
nixos-rebuild switch --flake "/etc/nixos#$HOST"

echo ""
echo "Done. Future rebuilds:"
echo "  nh os switch              # from /etc/nixos (wrapper flake)"
echo "  cd $TARGET_DIR && nh os switch"
