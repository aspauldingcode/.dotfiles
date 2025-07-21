#!/usr/bin/env bash

# Quick launcher for the Nix-based secrets manager
# This script ensures we're in the right environment and launches the dialog-based UI

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🔐 Launching Nix Secrets Manager...${NC}"

# Check if we're in a Nix environment
if ! command -v nix >/dev/null 2>&1; then
    echo -e "${RED}❌ Nix not found in PATH${NC}"
    echo "Please ensure Nix is installed and available"
    exit 1
fi

# Set the dotfiles directory
export DOTFILES_DIR="$SCRIPT_DIR"

# Build and run the secrets manager
echo -e "${GREEN}📦 Building secrets manager...${NC}"
if nix build "$SCRIPT_DIR#secrets-manager" --no-link --print-out-paths >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Build successful, launching UI...${NC}"
    echo
    nix run "$SCRIPT_DIR#secrets-manager"
else
    echo -e "${RED}❌ Build failed${NC}"
    echo "Trying to run with nix-shell fallback..."
    echo
    
    # Fallback: use nix-shell with required dependencies
    nix-shell -p dialog sops age yq-go jq --run "
        export DOTFILES_DIR='$SCRIPT_DIR'
        if [[ -f '$SCRIPT_DIR/secrets-manager.sh' ]]; then
            '$SCRIPT_DIR/secrets-manager.sh'
        else
            echo 'Legacy secrets manager not found'
            exit 1
        fi
    "
fi