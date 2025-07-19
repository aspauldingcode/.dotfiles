#!/usr/bin/env bash

# Production System Configuration Management Script
# Manages multi-system, multi-user Nix configurations

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# System configurations
declare -A SYSTEMS=(
    ["NIXY"]="aarch64-darwin"
    ["NIXSTATION64"]="x86_64-linux"
    ["NIXY2"]="aarch64-linux"
    ["NIXEDUP"]="aarch64-linux"
)

declare -A SYSTEM_TYPES=(
    ["NIXY"]="darwin"
    ["NIXSTATION64"]="nixos"
    ["NIXY2"]="nixos"
    ["NIXEDUP"]="mobile-nixos"
)

declare -A USERS=(
    ["alex"]="primary"
    ["susu"]="secondary"
)

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

log_debug() {
    if [ "${VERBOSE:-false}" = "true" ]; then
        echo -e "${PURPLE}[DEBUG]${NC} $1"
    fi
}

# Help function
show_help() {
    cat << EOF
🖥️  Production System Configuration Management

USAGE:
    $0 <command> [options]

COMMANDS:
    list                    List all available configurations
    build <system>          Build system configuration
    deploy <system>         Deploy configuration to system
    test <system>           Test configuration without activation
    rollback <system>       Rollback to previous generation
    status <system>         Show system status and health
    update                  Update flake inputs
    check                   Run comprehensive checks
    bootstrap <system>      Bootstrap new system
    backup <system>         Backup system configuration
    restore <system>        Restore system from backup
    monitor                 Monitor all systems
    sync                    Sync configurations across systems

SYSTEMS:
    NIXY                    Apple Silicon macOS (aarch64-darwin)
    NIXSTATION64            x86_64 Linux Desktop (x86_64-linux)
    NIXY2                   ARM64 Linux VM (aarch64-linux)
    NIXEDUP                 Mobile NixOS OnePlus 6T (aarch64-linux)

USERS:
    alex                    Primary user
    susu                    Secondary user

EXAMPLES:
    $0 list
    $0 build NIXY
    $0 deploy NIXSTATION64
    $0 test NIXY2
    $0 rollback NIXY
    $0 status all
    $0 bootstrap NIXEDUP
    $0 monitor

OPTIONS:
    -h, --help             Show this help message
    -v, --verbose          Enable verbose output
    -e, --environment ENV  Environment (production|staging|development)
    -u, --user USER        Target user (alex|susu)
    --dry-run              Show what would be done without executing
    --force                Force operation even with warnings
    --remote               Execute on remote system via SSH

EOF
}

# Parse command line arguments
parse_args() {
    VERBOSE=false
    DRY_RUN=false
    FORCE=false
    REMOTE=false
    ENVIRONMENT="development"
    TARGET_USER="alex"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --remote)
                REMOTE=true
                shift
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -u|--user)
                TARGET_USER="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                break
                ;;
        esac
    done
    
    export VERBOSE DRY_RUN FORCE REMOTE ENVIRONMENT TARGET_USER
}

# Check if system is valid
validate_system() {
    local system="$1"
    
    if [[ ! "${SYSTEMS[$system]:-}" ]]; then
        log_error "Unknown system: $system"
        log_info "Available systems: ${!SYSTEMS[*]}"
        exit 1
    fi
}

# Check if user is valid
validate_user() {
    local user="$1"
    
    if [[ ! "${USERS[$user]:-}" ]]; then
        log_error "Unknown user: $user"
        log_info "Available users: ${!USERS[*]}"
        exit 1
    fi
}

# Get current system
get_current_system() {
    local hostname
    hostname=$(hostname -s)
    
    for system in "${!SYSTEMS[@]}"; do
        if [[ "$system" == "$hostname" ]]; then
            echo "$system"
            return 0
        fi
    done
    
    log_warning "Current system not recognized: $hostname"
    echo "unknown"
}

# List all configurations
list_configurations() {
    log_info "Available System Configurations:"
    echo "================================="
    
    for system in "${!SYSTEMS[@]}"; do
        local arch="${SYSTEMS[$system]}"
        local type="${SYSTEM_TYPES[$system]}"
        local status="🔴 Unknown"
        
        # Check if configuration exists
        if [ -d "$DOTFILES_ROOT/system/$system" ]; then
            status="🟢 Available"
        fi
        
        printf "%-15s %-20s %-15s %s\n" "$system" "$arch" "$type" "$status"
    done
    
    echo
    log_info "Available Users:"
    echo "================"
    
    for user in "${!USERS[@]}"; do
        local role="${USERS[$user]}"
        local status="🔴 Unknown"
        
        if [ -d "$DOTFILES_ROOT/users/$user" ]; then
            status="🟢 Available"
        fi
        
        printf "%-15s %-15s %s\n" "$user" "$role" "$status"
    done
}

# Build system configuration
build_system() {
    local system="$1"
    validate_system "$system"
    
    local arch="${SYSTEMS[$system]}"
    local type="${SYSTEM_TYPES[$system]}"
    
    log_info "Building configuration for $system ($arch, $type)..."
    
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY RUN] Would build: nix build .#${type}Configurations.$system.config.system.build.toplevel"
        return 0
    fi
    
    cd "$DOTFILES_ROOT"
    
    case "$type" in
        "darwin")
            nix build ".#darwinConfigurations.$system.system" --verbose
            ;;
        "nixos"|"mobile-nixos")
            nix build ".#nixosConfigurations.$system.config.system.build.toplevel" --verbose
            ;;
        *)
            log_error "Unknown system type: $type"
            exit 1
            ;;
    esac
    
    log_success "Build completed for $system"
}

# Deploy configuration to system
deploy_system() {
    local system="$1"
    validate_system "$system"
    
    local arch="${SYSTEMS[$system]}"
    local type="${SYSTEM_TYPES[$system]}"
    local current_system
    current_system=$(get_current_system)
    
    log_info "Deploying configuration for $system ($arch, $type)..."
    
    # Check if we're deploying to the current system
    if [[ "$system" == "$current_system" ]]; then
        deploy_local "$system" "$type"
    elif [[ "$REMOTE" == "true" ]]; then
        deploy_remote "$system" "$type"
    else
        log_error "Cannot deploy to $system from $current_system without --remote flag"
        exit 1
    fi
}

# Deploy to local system
deploy_local() {
    local system="$1"
    local type="$2"
    
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY RUN] Would deploy locally to $system"
        return 0
    fi
    
    cd "$DOTFILES_ROOT"
    
    case "$type" in
        "darwin")
            sudo darwin-rebuild switch --flake ".#$system"
            ;;
        "nixos")
            sudo nixos-rebuild switch --flake ".#$system"
            ;;
        "mobile-nixos")
            log_warning "Mobile NixOS deployment requires special procedures"
            log_info "Please refer to the deployment runbook for mobile deployment"
            ;;
        *)
            log_error "Unknown system type: $type"
            exit 1
            ;;
    esac
    
    log_success "Deployment completed for $system"
}

# Deploy to remote system
deploy_remote() {
    local system="$1"
    local type="$2"
    
    log_info "Remote deployment not yet implemented for $system"
    log_info "Please use manual deployment procedures from the runbook"
}

# Test configuration
test_system() {
    local system="$1"
    validate_system "$system"
    
    local type="${SYSTEM_TYPES[$system]}"
    
    log_info "Testing configuration for $system..."
    
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY RUN] Would test configuration for $system"
        return 0
    fi
    
    cd "$DOTFILES_ROOT"
    
    case "$type" in
        "darwin")
            darwin-rebuild check --flake ".#$system"
            ;;
        "nixos")
            nixos-rebuild test --flake ".#$system"
            ;;
        *)
            log_warning "Test mode not available for $type"
            ;;
    esac
    
    log_success "Test completed for $system"
}

# Rollback system
rollback_system() {
    local system="$1"
    validate_system "$system"
    
    local type="${SYSTEM_TYPES[$system]}"
    
    log_warning "Rolling back $system to previous generation..."
    
    if [ "$FORCE" != "true" ]; then
        read -p "Are you sure you want to rollback $system? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Rollback cancelled"
            return 0
        fi
    fi
    
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY RUN] Would rollback $system"
        return 0
    fi
    
    case "$type" in
        "darwin")
            sudo nix-env --rollback --profile /nix/var/nix/profiles/system
            sudo /nix/var/nix/profiles/system/activate
            ;;
        "nixos")
            sudo nixos-rebuild switch --rollback
            ;;
        *)
            log_error "Rollback not supported for $type"
            exit 1
            ;;
    esac
    
    log_success "Rollback completed for $system"
}

# Show system status
show_status() {
    local system="${1:-all}"
    
    if [[ "$system" == "all" ]]; then
        log_info "System Status Overview"
        echo "======================"
        
        for sys in "${!SYSTEMS[@]}"; do
            show_system_status "$sys"
            echo
        done
    else
        validate_system "$system"
        show_system_status "$system"
    fi
}

# Show individual system status
show_system_status() {
    local system="$1"
    local arch="${SYSTEMS[$system]}"
    local type="${SYSTEM_TYPES[$system]}"
    
    echo "🖥️  $system ($arch, $type)"
    echo "   Configuration: $([ -d "$DOTFILES_ROOT/system/$system" ] && echo "✅ Present" || echo "❌ Missing")"
    
    # Check if this is the current system
    local current_system
    current_system=$(get_current_system)
    if [[ "$system" == "$current_system" ]]; then
        echo "   Status: 🟢 Current System"
        
        # Show generation info
        case "$type" in
            "darwin")
                if command -v darwin-version &> /dev/null; then
                    echo "   Version: $(darwin-version)"
                fi
                ;;
            "nixos")
                if command -v nixos-version &> /dev/null; then
                    echo "   Version: $(nixos-version)"
                fi
                ;;
        esac
        
        # Show system health
        echo "   Health:"
        echo "     Disk Usage: $(df -h /nix | tail -1 | awk '{print $5}') of /nix"
        echo "     Memory: $(free -h 2>/dev/null | grep Mem | awk '{print $3"/"$2}' || echo "N/A")"
        echo "     Uptime: $(uptime | awk '{print $3,$4}' | sed 's/,//')"
    else
        echo "   Status: 🔵 Remote System"
    fi
}

# Update flake inputs
update_flake() {
    log_info "Updating flake inputs..."
    
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY RUN] Would update flake inputs"
        return 0
    fi
    
    cd "$DOTFILES_ROOT"
    nix flake update
    
    log_success "Flake inputs updated"
    log_info "Consider testing configurations after update"
}

# Run comprehensive checks
run_checks() {
    log_info "Running comprehensive system checks..."
    
    cd "$DOTFILES_ROOT"
    
    # Run flake check
    log_info "Running flake check..."
    if ! ./scripts/flake-check.sh --current-system; then
        log_error "Flake check failed"
        return 1
    fi
    
    # Run secrets validation
    log_info "Validating secrets..."
    if ! ./scripts/secrets-manager.sh validate; then
        log_error "Secrets validation failed"
        return 1
    fi
    
    # Check git status
    log_info "Checking git status..."
    if ! git diff --quiet; then
        log_warning "Uncommitted changes detected"
    fi
    
    log_success "All checks passed"
}

# Bootstrap new system
bootstrap_system() {
    local system="$1"
    validate_system "$system"
    
    log_info "Bootstrapping $system..."
    log_warning "Bootstrap functionality is not yet implemented"
    log_info "Please refer to the deployment runbook for manual bootstrap procedures"
}

# Monitor all systems
monitor_systems() {
    log_info "System Monitoring Dashboard"
    echo "==========================="
    
    while true; do
        clear
        echo "🖥️  Multi-System Status Dashboard - $(date)"
        echo "=============================================="
        
        for system in "${!SYSTEMS[@]}"; do
            show_system_status "$system"
            echo
        done
        
        echo "Press Ctrl+C to exit monitoring..."
        sleep 30
    done
}

# Main function
main() {
    local command="${1:-}"
    shift || true
    
    # Parse arguments
    parse_args "$@"
    
    case "$command" in
        "list")
            list_configurations
            ;;
        "build")
            build_system "${1:-}"
            ;;
        "deploy")
            deploy_system "${1:-}"
            ;;
        "test")
            test_system "${1:-}"
            ;;
        "rollback")
            rollback_system "${1:-}"
            ;;
        "status")
            show_status "${1:-all}"
            ;;
        "update")
            update_flake
            ;;
        "check")
            run_checks
            ;;
        "bootstrap")
            bootstrap_system "${1:-}"
            ;;
        "monitor")
            monitor_systems
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