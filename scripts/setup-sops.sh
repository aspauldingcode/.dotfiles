#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect hostname
if [[ "$OSTYPE" == "darwin"* ]]; then
    HOSTNAME=$(scutil --get ComputerName | grep -E '^(NIXY|NIXY2|NIXSTATION64|NIXEDUP)$' || echo "")
else
    HOSTNAME=$(hostname | grep -E '^(NIXY|NIXY2|NIXSTATION64|NIXEDUP)$' || echo "")
fi

if [ -z "$HOSTNAME" ]; then
    echo -e "${RED}Error: Hostname must be one of: NIXY, NIXY2, NIXSTATION64, NIXEDUP${NC}"
    exit 1
fi

echo -e "${BLUE}Setting up SOPS configuration for ${GREEN}${HOSTNAME}${NC}"

# Create secrets directory for this host
SECRETS_DIR="secrets/${HOSTNAME,,}"  # Convert to lowercase
mkdir -p "$SECRETS_DIR"

# 1. Setup personal age key
if [[ "$OSTYPE" == "darwin"* ]]; then
    PERSONAL_AGE_DIR="$HOME/Library/Application Support/sops/age"
    XDG_AGE_DIR="$HOME/.config/sops/age"  # Keep XDG path for compatibility
else
    PERSONAL_AGE_DIR="$HOME/.config/sops/age"
fi

echo -e "${BLUE}Setting up personal age key in $PERSONAL_AGE_DIR...${NC}"
mkdir -p "$PERSONAL_AGE_DIR"

if [[ "$OSTYPE" == "darwin"* ]]; then
    mkdir -p "$XDG_AGE_DIR"
    # Create symlink if it doesn't exist
    if [ ! -L "$XDG_AGE_DIR/keys.txt" ]; then
        ln -sf "$PERSONAL_AGE_DIR/keys.txt" "$XDG_AGE_DIR/keys.txt"
    fi
fi

if [ ! -f "$PERSONAL_AGE_DIR/keys.txt" ]; then
    echo -e "${GREEN}Converting user SSH key to age key...${NC}"
    if [ -f "$HOME/.ssh/id_ed25519" ]; then
        ssh-to-age -private-key -i "$HOME/.ssh/id_ed25519" > "$PERSONAL_AGE_DIR/keys.txt"
    else
        echo -e "${YELLOW}No SSH key found, generating new age key...${NC}"
        age-keygen -o "$PERSONAL_AGE_DIR/keys.txt"
    fi
else
    echo -e "${YELLOW}Personal age key already exists at $PERSONAL_AGE_DIR/keys.txt${NC}"
    echo -e "${YELLOW}Keeping existing key to preserve access to existing secrets${NC}"
fi

PERSONAL_AGE_KEY=$(age-keygen -y "$PERSONAL_AGE_DIR/keys.txt")
echo -e "${GREEN}Personal age key: $PERSONAL_AGE_KEY${NC}"

# 2. Setup system SSH key
echo -e "${BLUE}Setting up system SSH key...${NC}"
if [ ! -f "/etc/ssh/ssh_host_ed25519_key" ]; then
    echo -e "${GREEN}Generating new system SSH key...${NC}"
    sudo ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
else
    echo -e "${YELLOW}System SSH key already exists${NC}"
    echo -e "${YELLOW}Keeping existing key to preserve system access${NC}"
fi

# 3. Convert system SSH key to age key
echo -e "${BLUE}Converting system SSH key to age key...${NC}"
SYSTEM_AGE_KEY=$(ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub)
echo -e "${GREEN}System age key: $SYSTEM_AGE_KEY${NC}"

# 4. Update .sops.yaml
echo -e "${BLUE}Updating .sops.yaml...${NC}"
SOPS_YAML=".sops.yaml"

# Create backup
cp "$SOPS_YAML" "${SOPS_YAML}.bak"

# Create a temporary file
TMP_YAML="${SOPS_YAML}.tmp"

# Process the file with awk to ensure single entries
HOST_VAR="host_${HOSTNAME,,}"
awk -v admin_key="$PERSONAL_AGE_KEY" -v host_key="$SYSTEM_AGE_KEY" -v host_var="$HOST_VAR" '
    BEGIN { 
        admin_found=0; 
        host_found=0;
        valid_hosts = "^[[:space:]]*-[[:space:]]*&(host_nixy|host_nixy2|host_nixstation64|host_nixedup)[[:space:]]";
    }
    # Match admin key with exact indentation
    /^[[:space:]]*-[[:space:]]*&admin_alex[[:space:]]/ { 
        if (!admin_found) {
            print "  - &admin_alex " admin_key;
            admin_found=1
        }
        next
    }
    # Match current host key with exact indentation
    $0 ~ "^[[:space:]]*-[[:space:]]*&" host_var "[[:space:]]" {
        if (!host_found) {
            print "  - &" host_var " " host_key;
            host_found=1
        }
        next
    }
    # Print all other lines unchanged, including other host entries
    { print }
' "$SOPS_YAML" > "$TMP_YAML"

# Replace original with processed file
mv "$TMP_YAML" "$SOPS_YAML"

# 5. Initialize secrets file if it doesn't exist
echo -e "${BLUE}Setting up secrets file...${NC}"
SECRETS_FILE="$SECRETS_DIR/secrets.yaml"

# Create initial secrets file if it doesn't exist
if [ ! -f "$SECRETS_FILE" ]; then
    echo -e "${GREEN}Creating new secrets file...${NC}"
    
    # Create initial unencrypted file
    cat > "$SECRETS_FILE" << EOL
test_secret: mysecretvalue
EOL

    # Encrypt the file using sops
    echo -e "${GREEN}Encrypting secrets file...${NC}"
    SOPS_AGE_KEY_FILE="$PERSONAL_AGE_DIR/keys.txt" sops --encrypt --in-place "$SECRETS_FILE"
else
    echo -e "${YELLOW}Secrets file already exists at $SECRETS_FILE${NC}"
    echo -e "${YELLOW}Keeping existing secrets${NC}"
fi

echo -e "${GREEN}Setup complete!${NC}"
echo -e "${BLUE}Personal age key location: $PERSONAL_AGE_DIR/keys.txt${NC}"
echo -e "${BLUE}System SSH key location: /etc/ssh/ssh_host_ed25519_key${NC}"
echo -e "${BLUE}Updated .sops.yaml with new keys${NC}"
echo -e "${BLUE}Backup of original .sops.yaml saved as ${SOPS_YAML}.bak${NC}"
echo -e "${BLUE}Secrets directory: $SECRETS_DIR${NC}" 