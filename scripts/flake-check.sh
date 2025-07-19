#!/usr/bin/env bash

# Quick Flake Check Script
# Fast validation for development workflow

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_failure() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
🔍 Quick Flake Check

USAGE:
    $0 [options]

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    --current-system        Check only current system
    --syntax-only           Check only syntax and formatting
    --build-only            Check only build validation
    --secrets-only          Check only secrets validation
    --fix                   Attempt to fix issues automatically

EXAMPLES:
    $0                      # Run all quick checks
    $0 --current-system     # Check current system only
    $0 --syntax-only        # Check syntax and formatting only
    $0 --fix                # Run checks and fix issues

EOF
}

# Get current system
get_current_system() {
    local arch
    arch=$(uname -m)
    local os
    os=$(uname -s)
    
    case "$os" in
        "Darwin")
            case "$arch" in
                "arm64") echo "aarch64-darwin" ;;
                "x86_64") echo "x86_64-darwin" ;;
                *) echo "unknown-darwin" ;;
            esac
            ;;
        "Linux")
            case "$arch" in
                "aarch64") echo "aarch64-linux" ;;
                "x86_64") echo "x86_64-linux" ;;
                *) echo "unknown-linux" ;;
            esac
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Check syntax and formatting
check_syntax() {
    log_info "Checking syntax and formatting..."
    
    cd "$DOTFILES_ROOT"
    
    # Check Nix syntax
    if find . -name "*.nix" -not -path "./.git/*" -exec nix-instantiate --parse {} \; > /dev/null 2>&1; then
        log_success "Nix syntax is valid"
    else
        log_failure "Nix syntax errors found"
        return 1
    fi
    
    # Check formatting
    if [ "$FIX_ISSUES" = "true" ]; then
        log_info "Fixing formatting..."
        nix fmt || true
        log_success "Formatting applied"
    else
        if nix fmt -- --check . > /dev/null 2>&1; then
            log_success "Code is properly formatted"
        else
            log_warning "Code formatting issues found (use --fix to auto-format)"
        fi
    fi
    
    # Check YAML syntax
    if command -v yq > /dev/null 2>&1; then
        if find . -name "*.yaml" -not -path "./.git/*" -exec yq eval '.' {} \; > /dev/null 2>&1; then
            log_success "YAML syntax is valid"
        else
            log_failure "YAML syntax errors found"
            return 1
        fi
    fi
    
    return 0
}

# Check flake evaluation
check_flake() {
    log_info "Checking flake evaluation..."
    
    cd "$DOTFILES_ROOT"
    
    # Check flake metadata
    if nix flake metadata > /dev/null 2>&1; then
        log_success "Flake metadata is valid"
    else
        log_failure "Flake metadata errors"
        return 1
    fi
    
    # Check flake show
    if nix flake show > /dev/null 2>&1; then
        log_success "Flake outputs are valid"
    else
        log_failure "Flake output errors"
        return 1
    fi
    
    return 0
}

# Check build validation
check_build() {
    log_info "Checking build validation..."
    
    cd "$DOTFILES_ROOT"
    
    local current_system
    current_system=$(get_current_system)
    
    if [ "$CURRENT_SYSTEM_ONLY" = "true" ]; then
        log_info "Checking current system: $current_system"
        
        # Determine configuration type and check
        case "$current_system" in
            *"darwin"*)
                # Find Darwin configuration for current system
                local darwin_configs
                darwin_configs=$(nix eval .#darwinConfigurations --apply builtins.attrNames --json 2>/dev/null | jq -r '.[]' || echo "")
                
                if [ -n "$darwin_configs" ]; then
                    local config
                    config=$(echo "$darwin_configs" | head -1)
                    if nix build ".#darwinConfigurations.$config.system" --no-link --dry-run > /dev/null 2>&1; then
                        log_success "Darwin configuration builds successfully"
                    else
                        log_failure "Darwin configuration build failed"
                        return 1
                    fi
                fi
                ;;
            *"linux"*)
                # Find NixOS configuration for current system
                local nixos_configs
                nixos_configs=$(nix eval .#nixosConfigurations --apply builtins.attrNames --json 2>/dev/null | jq -r '.[]' || echo "")
                
                if [ -n "$nixos_configs" ]; then
                    local config
                    config=$(echo "$nixos_configs" | head -1)
                    if nix build ".#nixosConfigurations.$config.config.system.build.toplevel" --no-link --dry-run > /dev/null 2>&1; then
                        log_success "NixOS configuration builds successfully"
                    else
                        log_failure "NixOS configuration build failed"
                        return 1
                    fi
                fi
                ;;
        esac
        
        # Check home configuration
        local home_configs
        home_configs=$(nix eval .#homeConfigurations --apply builtins.attrNames --json 2>/dev/null | jq -r '.[]' || echo "")
        
        if [ -n "$home_configs" ]; then
            local config
            config=$(echo "$home_configs" | head -1)
            if nix build ".#homeConfigurations.$config.activationPackage" --no-link --dry-run > /dev/null 2>&1; then
                log_success "Home configuration builds successfully"
            else
                log_warning "Home configuration build issues"
            fi
        fi
        
        # Check development shell
        if nix build ".#devShells.$current_system.default" --no-link --dry-run > /dev/null 2>&1; then
            log_success "Development shell builds successfully"
        else
            log_warning "Development shell build issues"
        fi
        
    else
        # Quick evaluation check for all configurations
        if nix eval .#nixosConfigurations --apply builtins.attrNames > /dev/null 2>&1; then
            log_success "NixOS configurations evaluate successfully"
        else
            log_failure "NixOS configuration evaluation failed"
            return 1
        fi
        
        if nix eval .#darwinConfigurations --apply builtins.attrNames > /dev/null 2>&1; then
            log_success "Darwin configurations evaluate successfully"
        else
            log_warning "Darwin configuration evaluation issues"
        fi
        
        if nix eval .#homeConfigurations --apply builtins.attrNames > /dev/null 2>&1; then
            log_success "Home configurations evaluate successfully"
        else
            log_warning "Home configuration evaluation issues"
        fi
    fi
    
    return 0
}

# Check secrets validation
check_secrets() {
    log_info "Checking secrets validation..."
    
    cd "$DOTFILES_ROOT"
    
    # Check SOPS configuration
    if [ -f ".sops.yaml" ]; then
        log_success "SOPS configuration found"
        
        # Check age key
        if [ -f "$HOME/.config/sops/age/keys.txt" ]; then
            log_success "Age key found"
        else
            log_warning "Age key not found at $HOME/.config/sops/age/keys.txt"
        fi
        
        # Check secrets files
        if find secrets -name "*.yaml" 2>/dev/null | grep -q .; then
            log_success "Secrets files found"
            
            # Test decryption if possible
            if command -v sops > /dev/null 2>&1; then
                local test_file
                test_file=$(find secrets -name "*.yaml" | head -1)
                if [ -n "$test_file" ] && sops --decrypt "$test_file" > /dev/null 2>&1; then
                    log_success "Secrets decryption works"
                else
                    log_warning "Secrets decryption issues (may need proper keys)"
                fi
            fi
        else
            log_warning "No secrets files found"
        fi
    else
        log_warning "SOPS configuration not found"
    fi
    
    # Check secrets manager script
    if [ -x "scripts/secrets-manager.sh" ]; then
        log_success "Secrets manager script found"
        
        if ./scripts/secrets-manager.sh status > /dev/null 2>&1; then
            log_success "Secrets manager works"
        else
            log_warning "Secrets manager issues"
        fi
    else
        log_warning "Secrets manager script not found or not executable"
    fi
    
    return 0
}

# Check Git status
check_git() {
    log_info "Checking Git status..."
    
    cd "$DOTFILES_ROOT"
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_warning "Not in a Git repository"
        return 0
    fi
    
    # Check for uncommitted changes
    if git diff --quiet && git diff --cached --quiet; then
        log_success "No uncommitted changes"
    else
        log_warning "Uncommitted changes found"
        if [ "$VERBOSE" = "true" ]; then
            git status --porcelain | head -5 | sed 's/^/  /'
        fi
    fi
    
    # Check for untracked files
    local untracked
    untracked=$(git ls-files --others --exclude-standard | wc -l)
    if [ "$untracked" -eq 0 ]; then
        log_success "No untracked files"
    else
        log_warning "$untracked untracked files found"
    fi
    
    return 0
}

# Main check function
run_checks() {
    local checks_passed=0
    local total_checks=0
    
    if [ "$SYNTAX_ONLY" = "true" ]; then
        ((total_checks++))
        if check_syntax; then
            ((checks_passed++))
        fi
    elif [ "$BUILD_ONLY" = "true" ]; then
        ((total_checks++))
        if check_flake; then
            ((checks_passed++))
        fi
        ((total_checks++))
        if check_build; then
            ((checks_passed++))
        fi
    elif [ "$SECRETS_ONLY" = "true" ]; then
        ((total_checks++))
        if check_secrets; then
            ((checks_passed++))
        fi
    else
        # Run all checks
        ((total_checks++))
        if check_syntax; then
            ((checks_passed++))
        fi
        
        ((total_checks++))
        if check_flake; then
            ((checks_passed++))
        fi
        
        ((total_checks++))
        if check_build; then
            ((checks_passed++))
        fi
        
        ((total_checks++))
        if check_secrets; then
            ((checks_passed++))
        fi
        
        ((total_checks++))
        if check_git; then
            ((checks_passed++))
        fi
    fi
    
    echo "========================================"
    if [ $checks_passed -eq $total_checks ]; then
        log_success "All checks passed ($checks_passed/$total_checks)"
        return 0
    else
        log_failure "Some checks failed ($checks_passed/$total_checks)"
        return 1
    fi
}

# Parse command line arguments
parse_args() {
    VERBOSE=false
    CURRENT_SYSTEM_ONLY=false
    SYNTAX_ONLY=false
    BUILD_ONLY=false
    SECRETS_ONLY=false
    FIX_ISSUES=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --current-system)
                CURRENT_SYSTEM_ONLY=true
                shift
                ;;
            --syntax-only)
                SYNTAX_ONLY=true
                shift
                ;;
            --build-only)
                BUILD_ONLY=true
                shift
                ;;
            --secrets-only)
                SECRETS_ONLY=true
                shift
                ;;
            --fix)
                FIX_ISSUES=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_failure "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    export VERBOSE CURRENT_SYSTEM_ONLY SYNTAX_ONLY BUILD_ONLY SECRETS_ONLY FIX_ISSUES
}

# Main function
main() {
    parse_args "$@"
    
    log_info "Running quick flake checks..."
    echo "========================================"
    
    local start_time
    start_time=$(date +%s)
    
    if run_checks; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        log_success "Quick checks completed in ${duration}s"
        exit 0
    else
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        log_failure "Quick checks failed in ${duration}s"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"