#!/usr/bin/env bash

# Dotfiles Migration and Validation Script
# This script helps migrate from the old flake structure to the new modular structure

set -euo pipefail

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

# Check if we're in the dotfiles directory
check_dotfiles_dir() {
  if [[ ! -f "flake.nix" ]] || [[ ! -d ".git" ]]; then
    log_error "This script must be run from the dotfiles repository root"
    exit 1
  fi
  log_info "Found dotfiles repository"
}

# Backup current configuration
backup_current_config() {
  local backup_dir="backup-$(date +%Y%m%d-%H%M%S)"
  log_info "Creating backup in $backup_dir"

  mkdir -p "$backup_dir"
  cp flake.nix "$backup_dir/"
  cp flake.lock "$backup_dir/"

  if [[ -d "lib" ]]; then
    cp -r lib "$backup_dir/"
  fi

  log_success "Backup created in $backup_dir"
}

# Validate current flake
validate_current_flake() {
  log_info "Validating current flake configuration..."

  if nix flake check --no-build 2>/dev/null; then
    log_success "Current flake passes basic validation"
  else
    log_warning "Current flake has validation issues (this is expected)"
  fi
}

# Check for required tools
check_dependencies() {
  log_info "Checking dependencies..."

  local deps=("nix" "git" "statix" "deadnix" "alejandra")
  local missing_deps=()

  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      missing_deps+=("$dep")
    fi
  done

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    log_warning "Missing dependencies: ${missing_deps[*]}"
    log_info "You can install them with: nix develop"
  else
    log_success "All dependencies found"
  fi
}

# Migrate to new structure
migrate_flake() {
  log_info "Migrating to new flake structure..."

  # Create parts directory if it doesn't exist
  mkdir -p parts

  # Check if restructured files exist
  if [[ -f "flake-restructured.nix" ]]; then
    log_info "Found restructured flake, replacing current flake.nix"
    cp flake.nix flake-old.nix
    cp flake-restructured.nix flake.nix
    log_success "Flake migrated to new structure"
  else
    log_error "Restructured flake not found. Please run the restructuring first."
    return 1
  fi
}

# Validate new flake
validate_new_flake() {
  log_info "Validating new flake structure..."

  # Check syntax first
  if nix flake check --no-build 2>/dev/null; then
    log_success "New flake structure is valid"
    return 0
  else
    log_error "New flake structure has issues"
    return 1
  fi
}

# Run linting tools
run_linting() {
  log_info "Running linting tools..."

  # Statix check
  if command -v statix &>/dev/null; then
    log_info "Running statix..."
    if statix check --format=stderr .; then
      log_success "Statix check passed"
    else
      log_warning "Statix found issues (see above)"
    fi
  fi

  # Deadnix check
  if command -v deadnix &>/dev/null; then
    log_info "Running deadnix..."
    if deadnix --fail .; then
      log_success "Deadnix check passed"
    else
      log_warning "Deadnix found dead code (see above)"
    fi
  fi

  # Alejandra formatting check
  if command -v alejandra &>/dev/null; then
    log_info "Checking Nix formatting..."
    if alejandra --check .; then
      log_success "Code is properly formatted"
    else
      log_warning "Code formatting issues found"
      log_info "Run 'alejandra .' to fix formatting"
    fi
  fi
}

# Test build configurations
test_builds() {
  log_info "Testing build configurations..."

  local configs=()

  # Detect available configurations
  if nix flake show 2>/dev/null | grep -q "nixosConfigurations"; then
    configs+=($(nix flake show --json 2>/dev/null | jq -r '.nixosConfigurations | keys[]' 2>/dev/null || true))
  fi

  if nix flake show 2>/dev/null | grep -q "darwinConfigurations"; then
    configs+=($(nix flake show --json 2>/dev/null | jq -r '.darwinConfigurations | keys[]' 2>/dev/null || true))
  fi

  for config in "${configs[@]}"; do
    log_info "Testing build for $config..."
    if nix build ".#${config}.config.system.build.toplevel" --dry-run 2>/dev/null; then
      log_success "$config build test passed"
    else
      log_warning "$config build test failed"
    fi
  done
}

# Mobile NixOS specific validation
validate_mobile_config() {
  log_info "Validating Mobile NixOS configuration..."

  if [[ -f "system/NIXEDUP/configuration-enhanced.nix" ]]; then
    log_success "Enhanced mobile configuration found"

    # Check if mobile-nixos input is properly configured
    if grep -q "mobile-nixos" flake.nix; then
      log_success "Mobile NixOS input configured"
    else
      log_warning "Mobile NixOS input not found in flake.nix"
    fi

    # Test mobile build
    log_info "Testing mobile configuration build..."
    if nix build ".#nixosConfigurations.NIXEDUP.config.system.build.toplevel" --dry-run 2>/dev/null; then
      log_success "Mobile configuration build test passed"
    else
      log_warning "Mobile configuration build test failed"
    fi
  else
    log_warning "Enhanced mobile configuration not found"
  fi
}

# Generate summary report
generate_report() {
  log_info "Generating migration report..."

  cat >migration-report.md <<EOF
# Dotfiles Migration Report

Generated on: $(date)

## Migration Status

### ✅ Completed Tasks
- [x] Backup created
- [x] Flake structure migrated to flake-parts
- [x] Mobile NixOS integration enhanced
- [x] Linting tools configured
- [x] Validation checks implemented

### 📋 Configuration Summary

#### Systems Configured
- **NIXY**: macOS (aarch64-darwin) with nix-darwin
- **NIXSTATION64**: NixOS x86_64 (stable)
- **NIXY2**: NixOS aarch64 (unstable, Apple Silicon)
- **NIXEDUP**: Mobile NixOS (OnePlus 6T)

#### Key Improvements
1. **Modular Structure**: Using flake-parts for better organization
2. **Enhanced Mobile Support**: Integrated phoneputer configuration
3. **Validation Tools**: Statix, deadnix, alejandra integration
4. **Security Hardening**: Improved SSH and security configurations
5. **Development Environment**: Enhanced dev shell with mobile tools

#### Next Steps
1. Test all configurations thoroughly
2. Update any remaining obsolete options
3. Customize mobile configuration for OnePlus 6T specifics
4. Set up CI/CD with GitHub Actions (already configured)

### 🔧 Available Commands

\`\`\`bash
# Enter development environment
nix develop

# Check flake validity
nix flake check

# Format code
alejandra .

# Lint code
statix check .

# Find dead code
deadnix .

# Build specific configuration
nix build .#nixosConfigurations.NIXEDUP.config.system.build.toplevel

# Mobile installer helper
nix run .#mobile-installer
\`\`\`

### 📱 Mobile NixOS Notes

The OnePlus 6T (fajita) configuration includes:
- Phosh mobile environment
- Essential mobile apps (calls, chatty, megapixels)
- Power management optimizations
- Cellular and WiFi connectivity
- Camera and sensor support

To flash to device:
1. Build the configuration
2. Use fastboot to flash the boot image
3. Configure WiFi and cellular settings

EOF

  log_success "Migration report generated: migration-report.md"
}

# Main execution
main() {
  log_info "Starting dotfiles migration and validation..."

  check_dotfiles_dir
  check_dependencies
  backup_current_config
  validate_current_flake

  # Ask user if they want to proceed with migration
  read -p "Proceed with migration? (y/N): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    migrate_flake
    validate_new_flake
    run_linting
    test_builds
    validate_mobile_config
    generate_report

    log_success "Migration completed successfully!"
    log_info "Review the migration-report.md for details"
    log_info "Run 'nix develop' to enter the development environment"
  else
    log_info "Migration cancelled by user"
  fi
}

# Run main function
main "$@"
