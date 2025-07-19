#!/usr/bin/env bash
set -euo pipefail

REPO="aspauldingcode/age-key-store"
DEST1="/var/lib/sops-nix/key.txt"
DEST2="$HOME/.config/sops/age/keys.txt"

# Automatically authenticate with GitHub if not already logged in
if ! gh auth status &>/dev/null; then
  gh auth login
fi

# Confirm operation
dialog --title "Deploy Age Key" \
  --yesno "This will download and deploy the age key.\n\nContinue?" 10 50

response=$?
clear

if [[ $response -ne 0 ]]; then
  echo "❌ Operation cancelled by user."
  exit 1
fi

# Clone repo and copy key
gh repo clone "$REPO" /tmp/age-key-store
cp /tmp/age-key-store/key.txt /tmp/key.txt
rm -rf /tmp/age-key-store

# Place the keys
sudo mkdir -p "$(dirname "$DEST1")"
mkdir -p "$(dirname "$DEST2")"

sudo mv /tmp/key.txt "$DEST1"
cp "$DEST1" "$DEST2"

# Fix permissions
sudo chmod 644 "$DEST1"
chmod 644 "$DEST2"

# Show success dialog
dialog --title "Success" --msgbox "✅ age key deployed successfully." 7 40
clear
