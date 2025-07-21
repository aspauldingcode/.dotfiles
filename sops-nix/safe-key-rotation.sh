#!/bin/bash

# Safe SOPS Key Rotation Script for Distributed Systems
# This script handles offline systems by using a two-phase rotation approach

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OLD_KEY_FILE="test-keys/old-key.txt"
NEW_KEY_FILE="test-keys/new-key.txt"

# Extract public keys
OLD_PUBLIC_KEY=$(grep "# public key:" "$OLD_KEY_FILE" | cut -d' ' -f4)
NEW_PUBLIC_KEY=$(grep "# public key:" "$NEW_KEY_FILE" | cut -d' ' -f4)

echo -e "${BLUE}🔐 Safe SOPS Key Rotation for Distributed Systems${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: This is a TWO-PHASE process to handle offline systems${NC}"
echo ""

# Find all encrypted files
ENCRYPTED_FILES=($(find . -name "*.yaml" -path "*/secrets/*" -exec grep -l "sops:" {} \; 2>/dev/null || true))
ENCRYPTED_FILES+=($(find . -name "secrets.yaml" -path "*/sops-nix/*" -exec grep -l "sops:" {} \; 2>/dev/null || true))

echo -e "${BLUE}📁 Found ${#ENCRYPTED_FILES[@]} encrypted files:${NC}"
for file in "${ENCRYPTED_FILES[@]}"; do
    echo "  - $file"
done
echo ""

# Phase selection
echo -e "${YELLOW}Select rotation phase:${NC}"
echo "1) PHASE 1: Add new key (keeps old key - SAFE for offline systems)"
echo "2) PHASE 2: Remove old key (after ALL systems are online with new key)"
echo "3) STATUS: Check current key status of all files"
echo "4) ROLLBACK: Remove new key and keep only old key"
echo ""
read -p "Enter choice (1-4): " phase

case $phase in
    1)
        echo -e "${GREEN}🚀 PHASE 1: Adding new key to all files${NC}"
        echo -e "${YELLOW}This keeps the old key, so offline systems will still work${NC}"
        echo ""
        
        for file in "${ENCRYPTED_FILES[@]}"; do
            echo -e "${BLUE}Processing: $file${NC}"
            
            # Check if new key is already present
            if sops --decrypt --extract '["sops"]["age"]' "$file" 2>/dev/null | grep -q "$NEW_PUBLIC_KEY"; then
                echo -e "  ${GREEN}✅ New key already present${NC}"
            else
                echo -e "  ${YELLOW}➕ Adding new key...${NC}"
                sops --rotate --add-age "$NEW_PUBLIC_KEY" "$file"
                echo -e "  ${GREEN}✅ New key added${NC}"
            fi
            echo ""
        done
        
        echo -e "${GREEN}🎉 PHASE 1 COMPLETE!${NC}"
        echo -e "${YELLOW}📋 Next steps:${NC}"
        echo "1. Commit and push these changes"
        echo "2. Deploy new private key to ALL systems"
        echo "3. Verify ALL systems can decrypt with new key"
        echo "4. Only then run PHASE 2 to remove old key"
        ;;
        
    2)
        echo -e "${RED}⚠️  PHASE 2: Removing old key from all files${NC}"
        echo -e "${RED}WARNING: After this, systems with only the old key CANNOT decrypt!${NC}"
        echo ""
        read -p "Are you SURE all systems have the new private key? (yes/no): " confirm
        
        if [[ "$confirm" != "yes" ]]; then
            echo -e "${YELLOW}❌ Aborted. Deploy new keys to all systems first.${NC}"
            exit 1
        fi
        
        for file in "${ENCRYPTED_FILES[@]}"; do
            echo -e "${BLUE}Processing: $file${NC}"
            
            # Check if old key is still present
            if sops --decrypt --extract '["sops"]["age"]' "$file" 2>/dev/null | grep -q "$OLD_PUBLIC_KEY"; then
                echo -e "  ${YELLOW}➖ Removing old key...${NC}"
                sops --rotate --rm-age "$OLD_PUBLIC_KEY" "$file"
                echo -e "  ${GREEN}✅ Old key removed${NC}"
            else
                echo -e "  ${GREEN}✅ Old key already removed${NC}"
            fi
            echo ""
        done
        
        echo -e "${GREEN}🎉 PHASE 2 COMPLETE!${NC}"
        echo -e "${YELLOW}📋 Next steps:${NC}"
        echo "1. Commit and push these changes"
        echo "2. Remove old private key from ALL systems"
        echo "3. Key rotation is now complete!"
        ;;
        
    3)
        echo -e "${BLUE}📊 Current key status:${NC}"
        echo ""
        
        for file in "${ENCRYPTED_FILES[@]}"; do
            echo -e "${BLUE}📄 $file${NC}"
            
            # Check for both keys
            age_recipients=$(sops --decrypt --extract '["sops"]["age"]' "$file" 2>/dev/null || echo "[]")
            
            old_key_present=false
            new_key_present=false
            
            if echo "$age_recipients" | grep -q "$OLD_PUBLIC_KEY"; then
                old_key_present=true
            fi
            
            if echo "$age_recipients" | grep -q "$NEW_PUBLIC_KEY"; then
                new_key_present=true
            fi
            
            if $old_key_present && $new_key_present; then
                echo -e "  ${YELLOW}🔄 TRANSITION STATE: Both keys present${NC}"
            elif $old_key_present && ! $new_key_present; then
                echo -e "  ${RED}🔴 OLD KEY ONLY${NC}"
            elif ! $old_key_present && $new_key_present; then
                echo -e "  ${GREEN}🟢 NEW KEY ONLY${NC}"
            else
                echo -e "  ${RED}❌ NO RECOGNIZED KEYS${NC}"
            fi
            echo ""
        done
        ;;
        
    4)
        echo -e "${YELLOW}🔄 ROLLBACK: Removing new key and keeping old key${NC}"
        echo ""
        
        for file in "${ENCRYPTED_FILES[@]}"; do
            echo -e "${BLUE}Processing: $file${NC}"
            
            # Check if new key is present
            if sops --decrypt --extract '["sops"]["age"]' "$file" 2>/dev/null | grep -q "$NEW_PUBLIC_KEY"; then
                echo -e "  ${YELLOW}➖ Removing new key...${NC}"
                sops --rotate --rm-age "$NEW_PUBLIC_KEY" "$file"
                echo -e "  ${GREEN}✅ New key removed (rollback)${NC}"
            else
                echo -e "  ${GREEN}✅ New key not present${NC}"
            fi
            echo ""
        done
        
        echo -e "${GREEN}🎉 ROLLBACK COMPLETE!${NC}"
        ;;
        
    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac