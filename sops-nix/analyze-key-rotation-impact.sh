#!/bin/bash

# SOPS Key Rotation Impact Analysis
# This script analyzes all encrypted files to determine the scope of key rotation

set -e

echo "🔍 SOPS Key Rotation Impact Analysis"
echo "===================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Current key being used everywhere
CURRENT_KEY="age1hcsxwhtcgdk2sknhk5eyug5thvuqsf0k9ytagd6ce6tzv3flfd3qz5tgk2"

echo -e "${BLUE}Current primary key:${NC} $CURRENT_KEY"
echo

# Find all encrypted SOPS files
echo -e "${BLUE}📁 Finding all encrypted SOPS files...${NC}"
ENCRYPTED_FILES=(
    "./secrets/staging/secrets.yaml"
    "./secrets/development/secrets.yaml" 
    "./secrets/users/alex.yaml"
    "./secrets/production/secrets.yaml"
    "./secrets/systems/NIXY.yaml"
    "./sops-nix/secrets.yaml"
)

echo "Found ${#ENCRYPTED_FILES[@]} encrypted files:"
for file in "${ENCRYPTED_FILES[@]}"; do
    echo "  - $file"
done
echo

# Analyze each file
echo -e "${BLUE}🔐 Analyzing encryption recipients for each file...${NC}"
echo

for file in "${ENCRYPTED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo -e "${YELLOW}📄 $file${NC}"
        
        # Extract age recipients from the sops metadata section
        recipients=$(grep -A 20 "sops:" "$file" | grep -A 5 "age:" | grep "recipient:" | sed 's/.*recipient: //' || true)
        
        if [[ -n "$recipients" ]]; then
            echo "  Age recipients:"
            while IFS= read -r recipient; do
                if [[ "$recipient" == "$CURRENT_KEY" ]]; then
                    echo -e "    ✅ ${GREEN}$recipient${NC} (current key)"
                else
                    echo -e "    ❓ ${YELLOW}$recipient${NC} (different key)"
                fi
            done <<< "$recipients"
        else
            echo -e "    ${RED}❌ No age recipients found${NC}"
        fi
        echo
    else
        echo -e "${RED}❌ File not found: $file${NC}"
        echo
    fi
done

# Check .sops.yaml configurations
echo -e "${BLUE}⚙️  Checking SOPS configuration files...${NC}"
echo

SOPS_CONFIGS=(
    "./.sops.yaml"
    "./sops-nix/.sops.yaml"
)

for config in "${SOPS_CONFIGS[@]}"; do
    if [[ -f "$config" ]]; then
        echo -e "${YELLOW}📄 $config${NC}"
        
        # Count occurrences of the current key
        key_count=$(grep -c "$CURRENT_KEY" "$config" || echo "0")
        echo "  Current key appears $key_count times"
        
        # Show unique age keys in this config
        unique_keys=$(grep -o "age1[a-z0-9]\{58\}" "$config" | sort | uniq || true)
        if [[ -n "$unique_keys" ]]; then
            echo "  Unique age keys found:"
            while IFS= read -r key; do
                if [[ "$key" == "$CURRENT_KEY" ]]; then
                    echo -e "    ✅ ${GREEN}$key${NC} (current key)"
                else
                    echo -e "    ❓ ${YELLOW}$key${NC} (different key)"
                fi
            done <<< "$unique_keys"
        fi
        echo
    else
        echo -e "${RED}❌ Config not found: $config${NC}"
        echo
    fi
done

# Summary and recommendations
echo -e "${BLUE}📊 SUMMARY AND IMPACT ANALYSIS${NC}"
echo "================================"
echo

# Check if all files use the same key
all_same_key=true
different_keys_found=false

for file in "${ENCRYPTED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        recipients=$(grep -A 20 "sops:" "$file" | grep -A 5 "age:" | grep "recipient:" | sed 's/.*recipient: //' || true)
        if [[ -n "$recipients" ]]; then
            while IFS= read -r recipient; do
                if [[ -n "$recipient" && "$recipient" != "$CURRENT_KEY" ]]; then
                    all_same_key=false
                    different_keys_found=true
                    break 2
                fi
            done <<< "$recipients"
        fi
    fi
done

if [[ "$all_same_key" == true ]]; then
    echo -e "${GREEN}✅ GOOD NEWS: All encrypted files use the same key!${NC}"
    echo -e "${GREEN}   Key rotation will affect ALL systems and users uniformly.${NC}"
    echo
    echo -e "${BLUE}🎯 KEY ROTATION SCOPE:${NC}"
    echo "   • ALL environments: production, staging, development"
    echo "   • ALL systems: NIXY, NIXY2, NIXSTATION64"  
    echo "   • ALL users: alex, susu"
    echo "   • ALL secret files: $(echo "${ENCRYPTED_FILES[@]}" | wc -w) files total"
    echo
    echo -e "${YELLOW}⚠️  IMPORTANT CONSIDERATIONS:${NC}"
    echo "   1. Key rotation will require updating the private key on ALL systems"
    echo "   2. All systems must have the new private key before rotation"
    echo "   3. Consider a staged rollout: add new key first, then remove old key"
    echo "   4. Test decryption on each system after rotation"
    echo
    echo -e "${BLUE}📋 RECOMMENDED ROTATION PROCESS:${NC}"
    echo "   1. Generate new age key"
    echo "   2. Deploy new private key to all systems"
    echo "   3. Add new key to all encrypted files (transition period)"
    echo "   4. Verify all systems can decrypt with new key"
    echo "   5. Remove old key from all encrypted files"
    echo "   6. Remove old private key from all systems"
else
    echo -e "${YELLOW}⚠️  MIXED KEY USAGE DETECTED${NC}"
    echo -e "${YELLOW}   Different files use different keys - rotation will be more complex.${NC}"
    echo
    echo -e "${RED}🚨 MANUAL REVIEW REQUIRED:${NC}"
    echo "   You'll need to rotate keys on a per-file basis."
    echo "   Check each file individually to determine the correct rotation strategy."
fi

echo
echo -e "${BLUE}🔧 TOOLS AVAILABLE:${NC}"
echo "   • Use the test-key-rotation.sh script as a template"
echo "   • Modify it to work with your actual key files"
echo "   • Test on a copy of your secrets first"
echo
echo "Analysis complete! 🎉"