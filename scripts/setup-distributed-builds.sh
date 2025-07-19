#!/usr/bin/env bash
# Setup Distributed Builds with NIXSTATION64
# This script helps configure SSH access and get the host key for distributed builds

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Configuration
NIXSTATION64_HOST="${1:-nixstation64.local}"
SSH_USER="alex"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"

main() {
    log_info "Setting up distributed builds with NIXSTATION64"
    echo "Host: $NIXSTATION64_HOST"
    echo "User: $SSH_USER"
    echo "SSH Key: $SSH_KEY_PATH"
    echo

    # Check if SSH key exists
    if [[ ! -f "$SSH_KEY_PATH" ]]; then
        log_warning "SSH key not found at $SSH_KEY_PATH"
        read -p "Generate new SSH key? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Generating new SSH key..."
            ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N ""
            log_success "SSH key generated"
        else
            log_error "SSH key required for distributed builds"
            exit 1
        fi
    fi

    # Test SSH connection
    log_info "Testing SSH connection to $NIXSTATION64_HOST..."
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$SSH_USER@$NIXSTATION64_HOST" exit 2>/dev/null; then
        log_success "SSH connection successful"
    else
        log_warning "SSH connection failed"
        log_info "You may need to:"
        echo "1. Copy your public key to NIXSTATION64:"
        echo "   ssh-copy-id $SSH_USER@$NIXSTATION64_HOST"
        echo "2. Ensure NIXSTATION64 is running and accessible"
        echo "3. Check the hostname/IP address"
        echo
        read -p "Continue anyway to get host key? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Get SSH host key
    log_info "Getting SSH host key from $NIXSTATION64_HOST..."
    HOST_KEY=$(ssh-keyscan -t ed25519 "$NIXSTATION64_HOST" 2>/dev/null | head -n1 | cut -d' ' -f3)
    
    if [[ -n "$HOST_KEY" ]]; then
        log_success "Host key retrieved"
        echo "Host key: $HOST_KEY"
        echo
        
        # Update the configuration file
        CONFIG_FILE="$HOME/.dotfiles/system/NIXY/configuration/default.nix"
        log_info "Updating configuration file..."
        
        # Create a backup
        cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
        
        # Replace the placeholder host key
        sed -i.tmp "s/c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUE=/$HOST_KEY/g" "$CONFIG_FILE"
        rm "$CONFIG_FILE.tmp"
        
        log_success "Configuration updated with real host key"
        
        # Show next steps
        echo
        log_info "Next steps:"
        echo "1. Ensure NIXSTATION64 has Nix daemon running:"
        echo "   ssh $SSH_USER@$NIXSTATION64_HOST 'sudo systemctl enable --now nix-daemon'"
        echo
        echo "2. Copy your SSH public key to NIXSTATION64 if not done already:"
        echo "   ssh-copy-id $SSH_USER@$NIXSTATION64_HOST"
        echo
        echo "3. Test the distributed build:"
        echo "   nix build .#packages.x86_64-linux.default --builders 'ssh://$SSH_USER@$NIXSTATION64_HOST'"
        echo
        echo "4. Rebuild your Darwin configuration:"
        echo "   darwin-rebuild switch --flake .#NIXY"
        
    else
        log_error "Failed to retrieve host key from $NIXSTATION64_HOST"
        log_info "Make sure the host is reachable and SSH is enabled"
        exit 1
    fi
}

# Show usage if help requested
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage: $0 [hostname]"
    echo
    echo "Setup distributed builds with NIXSTATION64"
    echo
    echo "Arguments:"
    echo "  hostname    NIXSTATION64 hostname or IP (default: nixstation64.local)"
    echo
    echo "Examples:"
    echo "  $0                          # Use default hostname"
    echo "  $0 192.168.1.100           # Use IP address"
    echo "  $0 nixstation64.example.com # Use custom hostname"
    exit 0
fi

main "$@"