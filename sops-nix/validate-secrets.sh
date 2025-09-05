#!/usr/bin/env bash

# Validation script for sops-nix secrets management
# This script validates the secrets setup and configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_DIR="${HOME}/.dotfiles"
SECRETS_DIR="${DOTFILES_DIR}/secrets"
SOPS_DIR="${DOTFILES_DIR}/sops-nix"

# Helper functions
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

check_dependencies() {
  log_info "Checking dependencies..."

  local missing_deps=()
  local warnings=()

  if ! command -v sops &>/dev/null; then
    missing_deps+=("sops")
  fi

  if ! command -v age &>/dev/null; then
    missing_deps+=("age")
  fi

  if ! command -v nix &>/dev/null; then
    warnings+=("nix (required for testing configurations)")
  fi

  if [ ${#missing_deps[@]} -ne 0 ]; then
    log_error "Missing critical dependencies: ${missing_deps[*]}"
    return 1
  fi

  if [ ${#warnings[@]} -ne 0 ]; then
    log_warning "Missing optional dependencies: ${warnings[*]}"
  fi

  log_success "All critical dependencies found"
  return 0
}

check_directory_structure() {
  log_info "Checking directory structure..."

  local required_dirs=(
    "$SECRETS_DIR"
    "$SECRETS_DIR/development"
    "$SECRETS_DIR/production"
    "$SECRETS_DIR/staging"
    "$SECRETS_DIR/systems"
    "$SECRETS_DIR/users"
    "$SOPS_DIR"
  )

  local missing_dirs=()

  for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
      missing_dirs+=("$dir")
    fi
  done

  if [ ${#missing_dirs[@]} -ne 0 ]; then
    log_error "Missing directories:"
    for dir in "${missing_dirs[@]}"; do
      echo "  - $dir"
    done
    return 1
  fi

  log_success "Directory structure is correct"
  return 0
}

check_sops_configuration() {
  log_info "Checking .sops.yaml configuration..."

  local sops_yaml="${DOTFILES_DIR}/.sops.yaml"

  if [ ! -f "$sops_yaml" ]; then
    log_error ".sops.yaml not found at $sops_yaml"
    return 1
  fi

  # Check if .sops.yaml has required sections
  local required_sections=("keys" "creation_rules")
  local missing_sections=()

  for section in "${required_sections[@]}"; do
    if ! grep -q "^$section:" "$sops_yaml"; then
      missing_sections+=("$section")
    fi
  done

  if [ ${#missing_sections[@]} -ne 0 ]; then
    log_error "Missing sections in .sops.yaml: ${missing_sections[*]}"
    return 1
  fi

  log_success ".sops.yaml configuration found and has required sections"
  return 0
}

check_age_keys() {
  log_info "Checking age key configuration..."

  local age_dir="${HOME}/.config/sops/age"
  local age_key_file="${age_dir}/keys.txt"

  if [ ! -f "$age_key_file" ]; then
    log_error "Age key file not found at $age_key_file"
    log_info "Run: age-keygen -o $age_key_file"
    return 1
  fi

  # Check permissions
  local perms
  perms=$(stat -f "%A" "$age_key_file" 2>/dev/null || stat -c "%a" "$age_key_file" 2>/dev/null)
  if [ "$perms" != "600" ]; then
    log_warning "Age key file permissions are $perms, should be 600"
    log_info "Run: chmod 600 $age_key_file"
  fi

  # Try to extract public key
  if age-keygen -y "$age_key_file" >/dev/null 2>&1; then
    local public_key
    public_key=$(age-keygen -y "$age_key_file")
    log_success "Age key is valid. Public key: $public_key"
  else
    log_error "Age key file is invalid or corrupted"
    return 1
  fi

  return 0
}

check_secret_files() {
  log_info "Checking secret files..."

  local environments=("development" "production" "staging")
  local special_files=("users/alex.yaml" "systems/NIXY.yaml")

  local issues=()

  # Check environment files
  for env in "${environments[@]}"; do
    local file="${SECRETS_DIR}/${env}/secrets.yaml"
    if [ ! -f "$file" ]; then
      issues+=("Missing: $file")
      continue
    fi

    # Try to decrypt
    if sops --decrypt "$file" >/dev/null 2>&1; then
      log_success "✓ $env/secrets.yaml - encrypted and decryptable"

      # Check for CHANGE_ME placeholders
      local placeholders
      placeholders=$(sops --decrypt "$file" | grep -c "CHANGE_ME" || true)
      if [ "$placeholders" -gt 0 ]; then
        log_warning "⚠ $env/secrets.yaml has $placeholders CHANGE_ME placeholders"
      fi
    else
      log_error "✗ $env/secrets.yaml - cannot decrypt (check keys)"
      issues+=("Cannot decrypt: $file")
    fi
  done

  # Check special files
  for file in "${special_files[@]}"; do
    local full_path="${SECRETS_DIR}/${file}"
    if [ -f "$full_path" ]; then
      if sops --decrypt "$full_path" >/dev/null 2>&1; then
        log_success "✓ $file - encrypted and decryptable"
      else
        log_error "✗ $file - cannot decrypt"
        issues+=("Cannot decrypt: $full_path")
      fi
    else
      log_warning "Optional file not found: $file"
    fi
  done

  if [ ${#issues[@]} -ne 0 ]; then
    log_error "Secret file issues found:"
    for issue in "${issues[@]}"; do
      echo "  - $issue"
    done
    return 1
  fi

  return 0
}

check_sops_config_nix() {
  log_info "Checking sopsConfig.nix..."

  local sops_config="${SOPS_DIR}/sopsConfig.nix"

  if [ ! -f "$sops_config" ]; then
    log_error "sopsConfig.nix not found at $sops_config"
    return 1
  fi

  # Basic syntax check
  if command -v nix &>/dev/null; then
    if nix-instantiate --parse "$sops_config" >/dev/null 2>&1; then
      log_success "sopsConfig.nix syntax is valid"
    else
      log_error "sopsConfig.nix has syntax errors"
      return 1
    fi
  else
    log_warning "Cannot validate sopsConfig.nix syntax (nix not available)"
  fi

  # Check for required functions
  local required_exports=("systemSopsConfig" "hmSopsConfig" "getSecretPath")
  local missing_exports=()

  for export in "${required_exports[@]}"; do
    if ! grep -q "$export" "$sops_config"; then
      missing_exports+=("$export")
    fi
  done

  if [ ${#missing_exports[@]} -ne 0 ]; then
    log_error "Missing exports in sopsConfig.nix: ${missing_exports[*]}"
    return 1
  fi

  log_success "sopsConfig.nix appears to be correctly configured"
  return 0
}

test_configuration() {
  log_info "Testing configuration with different environments..."

  if ! command -v nix &>/dev/null; then
    log_warning "Skipping configuration tests (nix not available)"
    return 0
  fi

  local test_file="/tmp/sops-test-$$.nix"

  # Create a test configuration
  cat >"$test_file" <<EOF
let
  nixpkgs = import <nixpkgs> {};
  sopsConfig = import ${SOPS_DIR}/sopsConfig.nix {
    inherit nixpkgs;
    user = "alex";
    environment = "development";
    hostname = "test-host";
  };
in {
  inherit (sopsConfig) environmentInfo secretUtils;
  
  # Test utility functions
  hasAnthropicKey = sopsConfig.secretUtils.hasSecret "anthropic_api_key";
  secretCount = sopsConfig.environmentInfo.secretCount;
  isValidEnv = sopsConfig.secretUtils.validateEnvironment "development";
}
EOF

  if nix-instantiate --eval "$test_file" >/dev/null 2>&1; then
    log_success "Configuration test passed"

    # Get some info
    local result
    result=$(nix-instantiate --eval --json "$test_file" 2>/dev/null || echo "{}")
    if [ "$result" != "{}" ]; then
      log_info "Configuration details:"
      echo "$result" | jq -r 'to_entries[] | "  \(.key): \(.value)"' 2>/dev/null || echo "  (details not available)"
    fi
  else
    log_error "Configuration test failed"
    rm -f "$test_file"
    return 1
  fi

  rm -f "$test_file"
  return 0
}

check_security() {
  log_info "Checking security configuration..."

  local issues=()

  # Check file permissions
  find "$SECRETS_DIR" -name "*.yaml" -type f | while read -r file; do
    local perms
    perms=$(stat -f "%A" "$file" 2>/dev/null || stat -c "%a" "$file" 2>/dev/null)
    if [ "$perms" != "644" ] && [ "$perms" != "600" ]; then
      echo "WARNING: $file has permissions $perms"
    fi
  done

  # Check for unencrypted secrets
  local unencrypted=()
  find "$SECRETS_DIR" -name "*.yaml" -type f | while read -r file; do
    if ! file "$file" | grep -q "data"; then
      # Might be unencrypted, check content
      if grep -q "CHANGE_ME\|password.*:\|key.*:\|token.*:" "$file" 2>/dev/null; then
        echo "WARNING: $file might contain unencrypted secrets"
      fi
    fi
  done

  # Check .sops.yaml for security issues
  local sops_yaml="${DOTFILES_DIR}/.sops.yaml"
  if [ -f "$sops_yaml" ]; then
    if grep -q "pgp:" "$sops_yaml"; then
      log_info "PGP keys found in .sops.yaml"
    fi
    if grep -q "age:" "$sops_yaml"; then
      log_info "Age keys found in .sops.yaml"
    fi
  fi

  log_success "Security check completed"
  return 0
}

generate_report() {
  log_info "Generating validation report..."

  local report_file="${DOTFILES_DIR}/secrets-validation-report.txt"

  cat >"$report_file" <<EOF
# SOPS-NIX Secrets Management Validation Report
Generated on: $(date)

## Directory Structure
$(find "$SECRETS_DIR" -type f -name "*.yaml" | sort)

## Secret Files Status
EOF

  # Add secret file details
  local environments=("development" "production" "staging")
  for env in "${environments[@]}"; do
    local file="${SECRETS_DIR}/${env}/secrets.yaml"
    if [ -f "$file" ]; then
      echo "### $env/secrets.yaml" >>"$report_file"
      if sops --decrypt "$file" >/dev/null 2>&1; then
        echo "- Status: ✓ Encrypted and decryptable" >>"$report_file"
        local secrets_count
        secrets_count=$(sops --decrypt "$file" | grep -c "^[a-zA-Z_].*:" || echo "0")
        echo "- Secrets count: $secrets_count" >>"$report_file"
        local placeholders
        placeholders=$(sops --decrypt "$file" | grep -c "CHANGE_ME" || echo "0")
        echo "- CHANGE_ME placeholders: $placeholders" >>"$report_file"
      else
        echo "- Status: ✗ Cannot decrypt" >>"$report_file"
      fi
      echo "" >>"$report_file"
    fi
  done

  # Add age key info
  local age_key_file="${HOME}/.config/sops/age/keys.txt"
  if [ -f "$age_key_file" ]; then
    echo "## Age Key Information" >>"$report_file"
    echo "- Key file: $age_key_file" >>"$report_file"
    if age-keygen -y "$age_key_file" >/dev/null 2>&1; then
      local public_key
      public_key=$(age-keygen -y "$age_key_file")
      echo "- Public key: $public_key" >>"$report_file"
    fi
    echo "" >>"$report_file"
  fi

  log_success "Validation report saved to: $report_file"
}

print_summary() {
  echo ""
  log_info "=== VALIDATION SUMMARY ==="

  local total_checks=7
  local passed_checks=0

  echo "Dependency Check: $(check_dependencies && echo "✓ PASS" && ((passed_checks++)) || echo "✗ FAIL")"
  echo "Directory Structure: $(check_directory_structure && echo "✓ PASS" && ((passed_checks++)) || echo "✗ FAIL")"
  echo "SOPS Configuration: $(check_sops_configuration && echo "✓ PASS" && ((passed_checks++)) || echo "✗ FAIL")"
  echo "Age Keys: $(check_age_keys && echo "✓ PASS" && ((passed_checks++)) || echo "✗ FAIL")"
  echo "Secret Files: $(check_secret_files && echo "✓ PASS" && ((passed_checks++)) || echo "✗ FAIL")"
  echo "sopsConfig.nix: $(check_sops_config_nix && echo "✓ PASS" && ((passed_checks++)) || echo "✗ FAIL")"
  echo "Configuration Test: $(test_configuration && echo "✓ PASS" && ((passed_checks++)) || echo "✗ FAIL")"

  echo ""
  echo "Overall: $passed_checks/$total_checks checks passed"

  if [ $passed_checks -eq $total_checks ]; then
    log_success "🎉 All checks passed! Your sops-nix setup is ready for production."
  elif [ $passed_checks -gt $((total_checks / 2)) ]; then
    log_warning "⚠️ Most checks passed, but some issues need attention."
  else
    log_error "❌ Multiple issues found. Please review and fix before using in production."
  fi
}

main() {
  log_info "Starting sops-nix validation..."
  echo ""

  # Run all checks (don't exit on failure, collect all issues)
  set +e

  check_dependencies
  check_directory_structure
  check_sops_configuration
  check_age_keys
  check_secret_files
  check_sops_config_nix
  test_configuration
  check_security

  generate_report
  print_summary

  echo ""
  log_info "For detailed information, see the documentation at:"
  log_info "  ${SECRETS_DIR}/README.md"
  log_info "For migration help, run:"
  log_info "  ${DOTFILES_DIR}/migrate-secrets.sh"
}

# Run main function
main "$@"
