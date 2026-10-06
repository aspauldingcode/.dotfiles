#!/usr/bin/env bash
# Automatic emergency recovery for sliceanddice
# Run this script to automatically fix the emergency mode issue
#
# Usage:
#   bash fix-emergency-auto.sh [--force]

set -euo pipefail

FORCE=false
if [[ "${1:-}" == "--force" ]]; then
    FORCE=true
fi

DOTFILES_DIR="/etc/nixos/.dotfiles"
HOST="sliceanddice"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     sliceanddice Emergency Recovery - Automatic Fixer         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if we're running as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

# Check if dotfiles directory exists
if [[ ! -d "$DOTFILES_DIR" ]]; then
    echo "❌ Dotfiles directory not found: $DOTFILES_DIR"
    echo "   Expected location: /etc/nixos/.dotfiles"
    exit 1
fi

cd "$DOTFILES_DIR"

echo "📍 Current location: $(pwd)"
echo ""

# Check git status
echo "🔍 Checking git status..."
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "   Current branch: $CURRENT_BRANCH"

# Check if disko.nix exists
DISKO_EXISTS=false
if [[ -f "hosts/nixos/sliceanddice/disko.nix" ]]; then
    DISKO_EXISTS=true
    echo "   ✓ disko.nix exists"
else
    echo "   ✗ disko.nix missing"
fi

# Check if default.nix imports disko
IMPORTS_DISKO=false
if grep -q "./disko.nix" hosts/nixos/sliceanddice/default.nix 2>/dev/null; then
    IMPORTS_DISKO=true
    echo "   ⚠ default.nix imports disko.nix"
else
    echo "   ✓ default.nix does NOT import disko.nix"
fi

echo ""

# Determine if we need to fix
NEED_FIX=false
FIX_REASON=""

if [[ "$IMPORTS_DISKO" == true && "$DISKO_EXISTS" == false ]]; then
    NEED_FIX=true
    FIX_REASON="default.nix imports disko.nix but file is missing"
elif [[ "$CURRENT_BRANCH" == "development" ]]; then
    NEED_FIX=true
    FIX_REASON="on development branch which may have incomplete features"
fi

if [[ "$NEED_FIX" == false ]]; then
    echo "✅ Configuration appears correct!"
    echo "   No automatic fix needed."
    echo ""
    echo "   If you're still experiencing issues, see:"
    echo "   - EMERGENCY_RECOVERY.md for manual steps"
    echo "   - diagnose-emergency.sh for diagnostics"
    exit 0
fi

echo "⚠️  Issue detected: $FIX_REASON"
echo ""

if [[ "$FORCE" == false ]]; then
    echo "Proposed fix:"
    echo "  1. Fetch latest from origin"
    echo "  2. Switch to stable master branch"
    echo "  3. Reset to origin/master"
    echo "  4. Rebuild NixOS configuration"
    echo ""
    read -p "Apply this fix? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted by user"
        exit 1
    fi
fi

echo ""
echo "🔧 Applying fix..."
echo ""

# Step 1: Fetch
echo "→ Fetching from origin..."
if ! git fetch origin; then
    echo "⚠️  Git fetch failed. Continuing anyway..."
fi

# Step 2: Checkout master
echo "→ Switching to master branch..."
if ! git checkout master; then
    echo "❌ Failed to checkout master branch"
    exit 1
fi

# Step 3: Reset to origin/master
echo "→ Resetting to origin/master..."
if ! git reset --hard origin/master; then
    echo "⚠️  Git reset failed. Continuing anyway..."
fi

# Step 4: Show current state
echo ""
echo "📊 Current configuration:"
echo "   Branch: $(git branch --show-current)"
echo "   Commit: $(git log -1 --oneline)"
echo ""

# Step 5: Rebuild
echo "→ Rebuilding NixOS configuration..."
echo "   This may take several minutes..."
echo ""

if nixos-rebuild switch --flake "$DOTFILES_DIR#$HOST"; then
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                  ✅ FIX APPLIED SUCCESSFULLY!                  ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Next steps:"
    echo "  1. Verify the system is working correctly"
    echo "  2. Reboot to ensure it boots cleanly: sudo reboot"
    echo ""
    echo "Your system should now be running on the stable master branch."
else
    echo ""
    echo "❌ nixos-rebuild failed!"
    echo ""
    echo "This could mean:"
    echo "  - Network issues preventing package downloads"
    echo "  - Evaluation errors in the configuration"
    echo "  - Hardware issues"
    echo ""
    echo "Next steps:"
    echo "  1. Check the error messages above"
    echo "  2. Try rebooting to a previous generation"
    echo "  3. See EMERGENCY_RECOVERY.md for manual recovery"
    echo ""
    exit 1
fi
