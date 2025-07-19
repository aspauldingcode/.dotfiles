#!/usr/bin/env bash

# Production Secrets Management Script
# Provides comprehensive secrets management for the Nix flake

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SECRETS_DIR="$DOTFILES_ROOT/secrets"
SOPS_CONFIG="$DOTFILES_ROOT/.sops.yaml"
AGE_KEY_FILE="${HOME}/.config/sops/age/keys.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
🔐 Production Secrets Management Script

USAGE:
    $0 <command> [options]

COMMANDS:
    init                    Initialize secrets management
    encrypt <file>          Encrypt a secrets file
    decrypt <file>          Decrypt a secrets file
    edit <file>             Edit an encrypted secrets file
    rotate-keys             Rotate SOPS encryption keys
    validate                Validate all secrets files
    backup                  Backup secrets and keys
    restore <backup>        Restore from backup
    audit                   Audit secrets for security issues
    sync                    Sync secrets across environments
    status                  Show secrets management status

ENVIRONMENTS:
    production              Production environment secrets
    staging                 Staging environment secrets  
    development             Development environment secrets
    users/<username>        User-specific secrets
    systems/<hostname>      System-specific secrets

EXAMPLES:
    $0 init
    $0 encrypt secrets/production/secrets.yaml
    $0 edit secrets/development/secrets.yaml
    $0 validate
    $0 rotate-keys
    $0 backup
    $0 audit

OPTIONS:
    -h, --help             Show this help message
    -v, --verbose          Enable verbose output
    -e, --environment ENV  Specify environment (production|staging|development)
    --dry-run              Show what would be done without executing

EOF
}

# Check dependencies
check_dependencies() {
    local deps=("sops" "age" "jq" "git")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_info "Install missing dependencies and try again"
        exit 1
    fi
}

# Initialize secrets management
init_secrets() {
    log_info "Initializing secrets management..."
    
    # Create directory structure
    mkdir -p "$SECRETS_DIR"/{production,staging,development,users,systems}
    mkdir -p "${HOME}/.config/sops/age"
    
    # Generate age key if it doesn't exist
    if [ ! -f "$AGE_KEY_FILE" ]; then
        log_info "Generating new age key..."
        age-keygen -o "$AGE_KEY_FILE"
        chmod 600 "$AGE_KEY_FILE"
        log_success "Age key generated at $AGE_KEY_FILE"
        
        # Show public key for SOPS configuration
        local public_key
        public_key=$(age-keygen -y "$AGE_KEY_FILE")
        log_info "Public key for SOPS configuration: $public_key"
        log_warning "Update .sops.yaml with this public key!"
    else
        log_info "Age key already exists at $AGE_KEY_FILE"
    fi
    
    # Set up git hooks for secrets validation
    setup_git_hooks
    
    log_success "Secrets management initialized"
}

# Set up git hooks
setup_git_hooks() {
    local hooks_dir="$DOTFILES_ROOT/.git/hooks"
    mkdir -p "$hooks_dir"
    
    # Pre-commit hook to validate secrets
    cat > "$hooks_dir/pre-commit" << 'EOF'
#!/bin/bash
# Validate secrets before commit
exec "$(git rev-parse --show-toplevel)/scripts/secrets-manager.sh" validate
EOF
    chmod +x "$hooks_dir/pre-commit"
    
    log_info "Git hooks configured for secrets validation"
}

# Encrypt a secrets file
encrypt_file() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        log_error "File not found: $file"
        exit 1
    fi
    
    log_info "Encrypting $file..."
    sops --encrypt --in-place "$file"
    log_success "File encrypted: $file"
}

# Decrypt a secrets file
decrypt_file() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        log_error "File not found: $file"
        exit 1
    fi
    
    log_info "Decrypting $file..."
    sops --decrypt "$file"
}

# Edit an encrypted secrets file
edit_file() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        log_error "File not found: $file"
        exit 1
    fi
    
    log_info "Editing $file..."
    sops "$file"
}

# Validate all secrets files
validate_secrets() {
    log_info "Validating secrets files..."
    local errors=0
    
    # Find all encrypted YAML files
    while IFS= read -r -d '' file; do
        log_info "Validating $file..."
        
        # Check if file is properly encrypted
        if ! sops --decrypt "$file" > /dev/null 2>&1; then
            log_error "Failed to decrypt: $file"
            ((errors++))
            continue
        fi
        
        # Validate YAML syntax
        if ! sops --decrypt "$file" | yq eval '.' > /dev/null 2>&1; then
            log_error "Invalid YAML syntax: $file"
            ((errors++))
            continue
        fi
        
        log_success "Valid: $file"
    done < <(find "$SECRETS_DIR" -name "*.yaml" -type f -print0)
    
    if [ $errors -eq 0 ]; then
        log_success "All secrets files are valid"
        return 0
    else
        log_error "Found $errors invalid secrets files"
        return 1
    fi
}

# Rotate SOPS keys
rotate_keys() {
    log_warning "Key rotation will re-encrypt all secrets with new keys"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Key rotation cancelled"
        return 0
    fi
    
    log_info "Starting key rotation..."
    
    # Backup current key
    local backup_dir="/tmp/sops-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    cp "$AGE_KEY_FILE" "$backup_dir/old-key.txt"
    
    # Generate new key
    age-keygen -o "${AGE_KEY_FILE}.new"
    local new_public_key
    new_public_key=$(age-keygen -y "${AGE_KEY_FILE}.new")
    
    log_info "New public key: $new_public_key"
    log_warning "Update .sops.yaml with the new public key before continuing"
    read -p "Press Enter after updating .sops.yaml..."
    
    # Re-encrypt all secrets
    while IFS= read -r -d '' file; do
        log_info "Re-encrypting $file..."
        sops --rotate --in-place "$file"
    done < <(find "$SECRETS_DIR" -name "*.yaml" -type f -print0)
    
    # Replace old key with new key
    mv "${AGE_KEY_FILE}.new" "$AGE_KEY_FILE"
    
    log_success "Key rotation completed"
    log_info "Backup of old key saved to: $backup_dir/old-key.txt"
}

# Backup secrets and keys
backup_secrets() {
    local backup_dir="${HOME}/.dotfiles-secrets-backup/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    log_info "Creating secrets backup..."
    
    # Backup secrets directory
    cp -r "$SECRETS_DIR" "$backup_dir/"
    
    # Backup SOPS configuration
    cp "$SOPS_CONFIG" "$backup_dir/"
    
    # Backup age keys
    if [ -f "$AGE_KEY_FILE" ]; then
        mkdir -p "$backup_dir/.config/sops/age"
        cp "$AGE_KEY_FILE" "$backup_dir/.config/sops/age/"
    fi
    
    # Create backup manifest
    cat > "$backup_dir/manifest.json" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "hostname": "$(hostname)",
  "user": "$(whoami)",
  "dotfiles_path": "$DOTFILES_ROOT",
  "secrets_count": $(find "$SECRETS_DIR" -name "*.yaml" -type f | wc -l),
  "backup_size": "$(du -sh "$backup_dir" | cut -f1)"
}
EOF
    
    log_success "Backup created: $backup_dir"
    log_info "Backup size: $(du -sh "$backup_dir" | cut -f1)"
}

# Audit secrets for security issues
audit_secrets() {
    log_info "Auditing secrets for security issues..."
    local issues=0
    
    # Check file permissions
    log_info "Checking file permissions..."
    while IFS= read -r -d '' file; do
        local perms
        perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%A" "$file" 2>/dev/null)
        if [ "$perms" != "600" ] && [ "$perms" != "0600" ]; then
            log_warning "Insecure permissions on $file: $perms (should be 600)"
            ((issues++))
        fi
    done < <(find "$SECRETS_DIR" -name "*.yaml" -type f -print0)
    
    # Check for unencrypted secrets
    log_info "Checking for unencrypted secrets..."
    while IFS= read -r -d '' file; do
        if ! grep -q "sops:" "$file"; then
            log_error "Unencrypted secrets file: $file"
            ((issues++))
        fi
    done < <(find "$SECRETS_DIR" -name "*.yaml" -type f -print0)
    
    # Check for weak patterns
    log_info "Checking for weak secret patterns..."
    local weak_patterns=("password123" "admin" "test" "changeme" "CHANGE_ME")
    for pattern in "${weak_patterns[@]}"; do
        if grep -r "$pattern" "$SECRETS_DIR" > /dev/null 2>&1; then
            log_warning "Found weak pattern '$pattern' in secrets"
            ((issues++))
        fi
    done
    
    # Check age key security
    if [ -f "$AGE_KEY_FILE" ]; then
        local key_perms
        key_perms=$(stat -c "%a" "$AGE_KEY_FILE" 2>/dev/null || stat -f "%A" "$AGE_KEY_FILE" 2>/dev/null)
        if [ "$key_perms" != "600" ] && [ "$key_perms" != "0600" ]; then
            log_error "Insecure permissions on age key: $key_perms (should be 600)"
            ((issues++))
        fi
    fi
    
    if [ $issues -eq 0 ]; then
        log_success "No security issues found"
        return 0
    else
        log_error "Found $issues security issues"
        return 1
    fi
}

# Show secrets management status
show_status() {
    log_info "Secrets Management Status"
    echo "========================="
    
    # Age key status
    if [ -f "$AGE_KEY_FILE" ]; then
        local public_key
        public_key=$(age-keygen -y "$AGE_KEY_FILE")
        echo "🔑 Age Key: Present"
        echo "   Public Key: $public_key"
        echo "   File: $AGE_KEY_FILE"
    else
        echo "🔑 Age Key: Missing"
    fi
    
    # SOPS configuration
    if [ -f "$SOPS_CONFIG" ]; then
        echo "⚙️  SOPS Config: Present ($SOPS_CONFIG)"
    else
        echo "⚙️  SOPS Config: Missing"
    fi
    
    # Secrets files count
    local secrets_count
    secrets_count=$(find "$SECRETS_DIR" -name "*.yaml" -type f 2>/dev/null | wc -l)
    echo "📁 Secrets Files: $secrets_count"
    
    # Environment breakdown
    for env in production staging development users systems; do
        local env_count
        env_count=$(find "$SECRETS_DIR/$env" -name "*.yaml" -type f 2>/dev/null | wc -l)
        echo "   $env: $env_count files"
    done
    
    # Recent activity
    echo "📅 Recent Activity:"
    find "$SECRETS_DIR" -name "*.yaml" -type f -mtime -7 2>/dev/null | head -5 | while read -r file; do
        echo "   $(basename "$file") ($(stat -c "%y" "$file" 2>/dev/null || stat -f "%Sm" "$file" 2>/dev/null))"
    done
}

# Main function
main() {
    local command="${1:-}"
    
    case "$command" in
        "init")
            check_dependencies
            init_secrets
            ;;
        "encrypt")
            check_dependencies
            encrypt_file "${2:-}"
            ;;
        "decrypt")
            check_dependencies
            decrypt_file "${2:-}"
            ;;
        "edit")
            check_dependencies
            edit_file "${2:-}"
            ;;
        "validate")
            check_dependencies
            validate_secrets
            ;;
        "rotate-keys")
            check_dependencies
            rotate_keys
            ;;
        "backup")
            check_dependencies
            backup_secrets
            ;;
        "audit")
            check_dependencies
            audit_secrets
            ;;
        "status")
            show_status
            ;;
        "help"|"-h"|"--help"|"")
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"