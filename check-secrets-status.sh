#!/bin/bash

# Quick status check for sops-nix secrets management setup
# This script provides a summary of the current state

echo "🔐 SOPS-NIX Secrets Management Status"
echo "===================================="
echo

# Check if all secret files are encrypted
echo "📁 Secret Files Status:"
for file in secrets/development/secrets.yaml secrets/production/secrets.yaml secrets/staging/secrets.yaml secrets/systems/NIXY.yaml secrets/users/alex.yaml; do
    if [[ -f "$file" ]]; then
        if sops --decrypt "$file" >/dev/null 2>&1; then
            echo "  ✅ $file - Encrypted and decryptable"
        else
            echo "  ❌ $file - Cannot decrypt"
        fi
    else
        echo "  ⚠️  $file - File not found"
    fi
done

echo
echo "🔑 Age Key Status:"
if [[ -f ~/.config/sops/age/keys.txt ]]; then
    echo "  ✅ Age key file exists"
    key_perms=$(stat -f "%A" ~/.config/sops/age/keys.txt)
    if [[ "$key_perms" == "600" ]]; then
        echo "  ✅ Correct permissions (600)"
    else
        echo "  ⚠️  Permissions: $key_perms (should be 600)"
    fi
    
    # Extract public key
    if command -v age-keygen >/dev/null 2>&1; then
        public_key=$(age-keygen -y ~/.config/sops/age/keys.txt 2>/dev/null)
        echo "  🔑 Public key: $public_key"
    fi
else
    echo "  ❌ Age key file not found"
fi

echo
echo "⚙️  Configuration Status:"
if [[ -f .sops.yaml ]]; then
    echo "  ✅ .sops.yaml configuration exists"
    if sops --config .sops.yaml --encrypt /dev/null >/dev/null 2>&1; then
        echo "  ✅ SOPS configuration is valid"
    else
        echo "  ❌ SOPS configuration has errors"
    fi
else
    echo "  ❌ .sops.yaml not found"
fi

if [[ -f sopsConfig.nix ]]; then
    echo "  ✅ sopsConfig.nix exists"
    if nix-instantiate --eval --expr 'import ./sopsConfig.nix { environment = "development"; }' >/dev/null 2>&1; then
        echo "  ✅ sopsConfig.nix syntax is valid"
    else
        echo "  ❌ sopsConfig.nix has syntax errors"
    fi
else
    echo "  ❌ sopsConfig.nix not found"
fi

echo
echo "📋 Next Steps:"
echo "  1. Replace CHANGE_ME placeholders in secret files with actual values"
echo "  2. Generate actual production/staging age keys (currently using dev key)"
echo "  3. Update .sops.yaml with real production keys"
echo "  4. Test integration with your NixOS/Home Manager configurations"
echo
echo "📖 For detailed documentation, see: secrets/README.md"
echo "🔧 For validation details, run: ./validate-secrets.sh"