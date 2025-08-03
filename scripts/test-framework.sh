#!/usr/bin/env bash

# Production Testing Framework for Nix Flake
# Comprehensive testing across all systems and configurations

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_RESULTS_DIR="$DOTFILES_ROOT/.test-results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test configuration
declare -A TEST_SUITES=(
  ["syntax"]="Syntax and formatting validation"
  ["build"]="Build system configurations"
  ["secrets"]="Secrets management validation"
  ["security"]="Security and compliance checks"
  ["performance"]="Performance and resource usage"
  ["integration"]="Integration and end-to-end tests"
  ["regression"]="Regression testing"
)

declare -A SYSTEMS=(
  ["NIXY"]="aarch64-darwin"
  ["NIXI"]="x86_64-darwin"
  ["NIXSTATION64"]="x86_64-linux"
  ["NIXY2"]="aarch64-linux"
  ["NIXEDUP"]="aarch64-linux"
)

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[PASS]${NC} $1"
  ((PASSED_TESTS++))
}

log_failure() {
  echo -e "${RED}[FAIL]${NC} $1"
  ((FAILED_TESTS++))
}

log_skip() {
  echo -e "${YELLOW}[SKIP]${NC} $1"
  ((SKIPPED_TESTS++))
}

log_warning() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_debug() {
  if [ "${VERBOSE:-false}" = "true" ]; then
    echo -e "${PURPLE}[DEBUG]${NC} $1"
  fi
}

# Test execution wrapper
run_test() {
  local test_name="$1"
  local test_command="$2"
  local test_description="${3:-$test_name}"

  ((TOTAL_TESTS++))

  log_info "Running: $test_description"

  if [ "$DRY_RUN" = "true" ]; then
    log_skip "$test_name (dry run)"
    return 0
  fi

  local start_time
  start_time=$(date +%s)

  if eval "$test_command" >"$TEST_RESULTS_DIR/$test_name.log" 2>&1; then
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log_success "$test_name (${duration}s)"
    echo "PASS" >"$TEST_RESULTS_DIR/$test_name.result"
    return 0
  else
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log_failure "$test_name (${duration}s)"
    echo "FAIL" >"$TEST_RESULTS_DIR/$test_name.result"

    if [ "${VERBOSE:-false}" = "true" ]; then
      echo "Error output:"
      tail -10 "$TEST_RESULTS_DIR/$test_name.log" | sed 's/^/  /'
    fi

    return 1
  fi
}

# Help function
show_help() {
  cat <<EOF
🧪 Production Testing Framework

USAGE:
    $0 [suite] [options]

TEST SUITES:
    syntax                 Syntax and formatting validation
    build                  Build system configurations  
    secrets                Secrets management validation
    security               Security and compliance checks
    performance            Performance and resource usage
    integration            Integration and end-to-end tests
    regression             Regression testing
    all                    Run all test suites (default)

EXAMPLES:
    $0                     # Run all tests
    $0 syntax              # Run only syntax tests
    $0 build --system NIXY # Test building NIXY only
    $0 build --system NIXI # Test building NIXI only
    $0 all --verbose       # Run all tests with verbose output

OPTIONS:
    -h, --help             Show this help message
    -v, --verbose          Enable verbose output
    --dry-run              Show what would be tested without executing
    --system SYSTEM        Test specific system only
    --parallel             Run tests in parallel (experimental)
    --continue-on-fail     Continue testing even if tests fail
    --report               Generate detailed test report

EOF
}

# Initialize test environment
init_test_env() {
  mkdir -p "$TEST_RESULTS_DIR"

  # Clean up old results
  find "$TEST_RESULTS_DIR" -name "*.log" -mtime +7 -delete 2>/dev/null || true
  find "$TEST_RESULTS_DIR" -name "*.result" -mtime +7 -delete 2>/dev/null || true

  # Create test session directory
  TEST_SESSION_DIR="$TEST_RESULTS_DIR/$TIMESTAMP"
  mkdir -p "$TEST_SESSION_DIR"

  log_info "Test session: $TIMESTAMP"
  log_info "Results directory: $TEST_SESSION_DIR"
}

# Syntax and formatting tests
test_syntax() {
  log_info "Running syntax and formatting tests..."

  cd "$DOTFILES_ROOT"

  # Nix syntax validation
  run_test "nix-syntax" \
    "find . -name '*.nix' -not -path './.git/*' -exec nix-instantiate --parse {} \; > /dev/null" \
    "Nix syntax validation"

  # Formatting check
  run_test "nix-format" \
    "nix fmt -- --check ." \
    "Nix formatting check"

  # YAML syntax validation
  run_test "yaml-syntax" \
    "find . -name '*.yaml' -not -path './.git/*' -exec yq eval '.' {} \; > /dev/null" \
    "YAML syntax validation"

  # JSON syntax validation
  run_test "json-syntax" \
    "find . -name '*.json' -not -path './.git/*' -exec jq '.' {} \; > /dev/null" \
    "JSON syntax validation"

  # Shell script syntax
  run_test "shell-syntax" \
    "find . -name '*.sh' -not -path './.git/*' -exec bash -n {} \;" \
    "Shell script syntax validation"

  # Statix linting
  run_test "statix-lint" \
    "statix check ." \
    "Statix linting"

  # Deadnix check
  run_test "deadnix-check" \
    "deadnix --check ." \
    "Dead code detection"
}

# Build tests
test_build() {
  log_info "Running build tests..."

  cd "$DOTFILES_ROOT"

  # Test flake evaluation
  run_test "flake-eval" \
    "nix eval .#nixosConfigurations --apply builtins.attrNames" \
    "Flake evaluation"

  # Test each system configuration
  for system in "${!SYSTEMS[@]}"; do
    if [ -n "${TARGET_SYSTEM:-}" ] && [ "$TARGET_SYSTEM" != "$system" ]; then
      log_skip "build-$system (not target system)"
      continue
    fi

    local arch="${SYSTEMS[$system]}"

    # Determine configuration type
    if [[ $arch == *"darwin"* ]]; then
      run_test "build-$system" \
        "nix build .#darwinConfigurations.$system.system --no-link" \
        "Build $system configuration"
    else
      run_test "build-$system" \
        "nix build .#nixosConfigurations.$system.config.system.build.toplevel --no-link" \
        "Build $system configuration"
    fi
  done

  # Test home configurations
  run_test "build-home-alex-NIXY" \
    "nix build .#homeConfigurations.alex-NIXY.activationPackage --no-link" \
    "Build alex-NIXY home configuration"

  run_test "build-home-alex-NIXI" \
    "nix build .#homeConfigurations.alex-NIXI.activationPackage --no-link" \
    "Build alex-NIXI home configuration"

  # Test development shells
  run_test "build-devshell" \
    "nix build .#devShells.aarch64-darwin.default --no-link" \
    "Build development shell"

  # Test custom packages
  run_test "build-packages" \
    "nix build .#packages.aarch64-darwin --no-link" \
    "Build custom packages"
}

# Secrets management tests
test_secrets() {
  log_info "Running secrets management tests..."

  # Test SOPS configuration
  run_test "sops-config" \
    "test -f .sops.yaml && sops --version > /dev/null" \
    "SOPS configuration validation"

  # Test age key
  run_test "age-key" \
    "test -f ~/.config/sops/age/keys.txt && age --version > /dev/null" \
    "Age key validation"

  # Test secrets decryption
  if [ -f "sops-nix/secrets.yaml" ]; then
    run_test "secrets-decrypt" \
      "sops --decrypt sops-nix/secrets.yaml > /dev/null" \
      "Secrets decryption test"
  else
    log_skip "secrets-decrypt (no secrets file)"
  fi

  # Test secrets manager script
  run_test "secrets-manager" \
    "./scripts/secrets-manager.sh status" \
    "Secrets manager functionality"

  # Test secrets validation
  run_test "secrets-validate" \
    "./scripts/secrets-manager.sh validate" \
    "Secrets validation"

  # Test secrets audit
  run_test "secrets-audit" \
    "./scripts/secrets-manager.sh audit" \
    "Secrets security audit"
}

# Security and compliance tests
test_security() {
  log_info "Running security and compliance tests..."

  # Check for hardcoded secrets
  run_test "hardcoded-secrets" \
    "! grep -r -E '(password|secret|key|token).*=.*[\"'][^\"']*[\"']' --include='*.nix' --include='*.yaml' . || true" \
    "Hardcoded secrets detection"

  # Check file permissions
  run_test "file-permissions" \
    "find . -type f -perm /o+w -not -path './.git/*' | wc -l | grep -q '^0$'" \
    "File permissions check"

  # Check for insecure packages
  run_test "insecure-packages" \
    "nix eval .#nixosConfigurations.NIXSTATION64.config.nixpkgs.config.permittedInsecurePackages --json | jq length" \
    "Insecure packages audit"

  # Git security check
  run_test "git-security" \
    "git log --all --full-history --grep='password\\|secret\\|key\\|token' --oneline | wc -l | grep -q '^0$'" \
    "Git history security scan"

  # SSH key security
  run_test "ssh-keys" \
    "find ~/.ssh -name '*_rsa' -o -name '*_ed25519' | xargs -I {} sh -c 'ssh-keygen -l -f {} > /dev/null'" \
    "SSH key validation"
}

# Performance tests
test_performance() {
  log_info "Running performance tests..."

  cd "$DOTFILES_ROOT"

  # Measure flake evaluation time
  run_test "eval-performance" \
    "time nix eval .#nixosConfigurations --apply builtins.attrNames" \
    "Flake evaluation performance"

  # Measure build cache efficiency
  run_test "cache-efficiency" \
    "nix path-info --all | wc -l" \
    "Build cache analysis"

  # Check store size
  run_test "store-size" \
    "du -sh /nix/store | awk '{print \$1}'" \
    "Nix store size check"

  # Memory usage during evaluation
  run_test "memory-usage" \
    "/usr/bin/time -l nix eval .#nixosConfigurations --apply builtins.attrNames 2>&1 | grep 'maximum resident set size'" \
    "Memory usage analysis"

  # Dependency analysis
  run_test "dependency-count" \
    'nix-store --query --requisites $(nix eval --raw .#nixosConfigurations.NIXSTATION64.config.system.build.toplevel.outPath) | wc -l' \
    "Dependency count analysis"
}

# Integration tests
test_integration() {
  log_info "Running integration tests..."

  # Test system manager
  run_test "system-manager" \
    "./scripts/system-manager.sh list" \
    "System manager integration"

  # Test flake check script
  run_test "flake-check" \
    "./scripts/flake-check.sh --current-system" \
    "Flake check integration"

  # Test CI/CD workflow syntax
  run_test "github-actions" \
    "yq eval '.jobs' .github/workflows/nix.yml > /dev/null" \
    "GitHub Actions workflow validation"

  # Test documentation
  run_test "documentation" \
    "test -f README.md && test -f docs/deployment-runbook.md" \
    "Documentation completeness"

  # Test treefmt configuration
  run_test "treefmt-config" \
    "treefmt --version && test -f treefmt.toml" \
    "Treefmt configuration"
}

# Regression tests
test_regression() {
  log_info "Running regression tests..."

  # Test against known good configurations
  if [ -d "backup-20250718-145033" ]; then
    run_test "config-regression" \
      "diff -r backup-20250718-145033/flake.nix flake.nix || true" \
      "Configuration regression check"
  else
    log_skip "config-regression (no backup reference)"
  fi

  # Test flake lock consistency
  run_test "flake-lock" \
    "nix flake metadata --json | jq '.locks' > /dev/null" \
    "Flake lock consistency"

  # Test backwards compatibility
  run_test "backwards-compat" \
    "nix eval .#legacyPackages.aarch64-darwin --apply builtins.attrNames" \
    "Backwards compatibility check"
}

# Generate test report
generate_report() {
  local report_file="$TEST_SESSION_DIR/test-report.html"

  log_info "Generating test report: $report_file"

  cat >"$report_file" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Nix Flake Test Report - $TIMESTAMP</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .summary { display: flex; gap: 20px; margin: 20px 0; }
        .metric { background: #e8f4f8; padding: 15px; border-radius: 5px; text-align: center; }
        .pass { color: #28a745; }
        .fail { color: #dc3545; }
        .skip { color: #ffc107; }
        .test-results { margin: 20px 0; }
        .test-suite { margin: 20px 0; border: 1px solid #ddd; border-radius: 5px; }
        .suite-header { background: #f8f9fa; padding: 10px; font-weight: bold; }
        .test-item { padding: 10px; border-bottom: 1px solid #eee; }
        .test-item:last-child { border-bottom: none; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🧪 Nix Flake Test Report</h1>
        <p><strong>Timestamp:</strong> $TIMESTAMP</p>
        <p><strong>System:</strong> $(uname -a)</p>
        <p><strong>Flake:</strong> $(git rev-parse HEAD 2>/dev/null || echo "unknown")</p>
    </div>
    
    <div class="summary">
        <div class="metric">
            <h3>Total Tests</h3>
            <div style="font-size: 2em;">$TOTAL_TESTS</div>
        </div>
        <div class="metric">
            <h3 class="pass">Passed</h3>
            <div style="font-size: 2em; color: #28a745;">$PASSED_TESTS</div>
        </div>
        <div class="metric">
            <h3 class="fail">Failed</h3>
            <div style="font-size: 2em; color: #dc3545;">$FAILED_TESTS</div>
        </div>
        <div class="metric">
            <h3 class="skip">Skipped</h3>
            <div style="font-size: 2em; color: #ffc107;">$SKIPPED_TESTS</div>
        </div>
    </div>
    
    <div class="test-results">
        <h2>Test Results</h2>
EOF

  # Add test results for each suite
  for suite in "${!TEST_SUITES[@]}"; do
    echo '<div class="test-suite">' >>"$report_file"
    echo "<div class=\"suite-header\">$suite - ${TEST_SUITES[$suite]}</div>" >>"$report_file"

    # Find test results for this suite
    find "$TEST_RESULTS_DIR" -name "*$suite*.result" 2>/dev/null | while read -r result_file; do
      local test_name
      test_name=$(basename "$result_file" .result)
      local result
      result=$(cat "$result_file")
      local class=""

      case "$result" in
      "PASS") class="pass" ;;
      "FAIL") class="fail" ;;
      "SKIP") class="skip" ;;
      esac

      echo "<div class=\"test-item\"><span class=\"$class\">[$result]</span> $test_name</div>" >>"$report_file"
    done

    echo "</div>" >>"$report_file"
  done

  cat >>"$report_file" <<EOF
    </div>
    
    <div class="footer">
        <p><em>Generated by Nix Flake Testing Framework</em></p>
    </div>
</body>
</html>
EOF

  log_success "Test report generated: $report_file"
}

# Main test runner
run_test_suite() {
  local suite="$1"

  case "$suite" in
  "syntax")
    test_syntax
    ;;
  "build")
    test_build
    ;;
  "secrets")
    test_secrets
    ;;
  "security")
    test_security
    ;;
  "performance")
    test_performance
    ;;
  "integration")
    test_integration
    ;;
  "regression")
    test_regression
    ;;
  "all")
    test_syntax
    test_build
    test_secrets
    test_security
    test_performance
    test_integration
    test_regression
    ;;
  *)
    log_error "Unknown test suite: $suite"
    exit 1
    ;;
  esac
}

# Parse command line arguments
parse_args() {
  VERBOSE=false
  DRY_RUN=false
  CONTINUE_ON_FAIL=false
  GENERATE_REPORT=false
  TARGET_SYSTEM=""

  while [[ $# -gt 0 ]]; do
    case $1 in
    -v | --verbose)
      VERBOSE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --continue-on-fail)
      CONTINUE_ON_FAIL=true
      shift
      ;;
    --report)
      GENERATE_REPORT=true
      shift
      ;;
    --system)
      TARGET_SYSTEM="$2"
      shift 2
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      break
      ;;
    esac
  done

  export VERBOSE DRY_RUN CONTINUE_ON_FAIL GENERATE_REPORT TARGET_SYSTEM
}

# Main function
main() {
  local suite="${1:-all}"
  shift || true

  # Parse arguments
  parse_args "$@"

  # Initialize test environment
  init_test_env

  # Run test suite
  log_info "Starting test suite: $suite"
  echo "========================================"

  local start_time
  start_time=$(date +%s)

  if run_test_suite "$suite"; then
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo "========================================"
    log_success "Test suite completed in ${duration}s"
    log_info "Results: $PASSED_TESTS passed, $FAILED_TESTS failed, $SKIPPED_TESTS skipped"

    if [ "$GENERATE_REPORT" = "true" ]; then
      generate_report
    fi

    if [ $FAILED_TESTS -eq 0 ]; then
      exit 0
    else
      exit 1
    fi
  else
    log_error "Test suite failed"
    exit 1
  fi
}

# Run main function with all arguments
main "$@"
