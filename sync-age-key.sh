#!/usr/bin/env bash
set -euo pipefail

REPO="aspauldingcode/age-key-store"
DEST1="/var/lib/sops-nix/key.txt"
DEST2="$HOME/.config/sops/age/keys.txt"

# Download the file from GitHub
gh repo clone "$REPO" /tmp/age-key-store
cp /tmp/age-key-store/key.txt /tmp/key.txt
rm -rf /tmp/age-key-store

# Place the keys
sudo mkdir -p "$(dirname "$DEST1")"
mkdir -p "$(dirname "$DEST2")"

sudo mv /tmp/key.txt "$DEST1"
cp "$DEST1" "$DEST2"

# Fix permissions
sudo chown root:root "$DEST1"
sudo chmod 644 "$DEST1"
chmod 644 "$DEST2"

echo "✅ age key deployed successfully."
