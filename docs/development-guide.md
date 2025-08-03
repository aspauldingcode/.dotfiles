# 🏗️ Development Guide

This guide covers development workflows, testing, and contribution guidelines for our comprehensive Nix flake configuration.

## Table of Contents

- [Development Environment](#development-environment)
- [Development Workflows](#development-workflows)
- [Testing Framework](#testing-framework)
- [Code Quality](#code-quality)
- [Contributing](#contributing)
- [Debugging](#debugging)
- [Performance](#performance)
- [CI/CD](#cicd)

## Development Environment

### Prerequisites

Ensure you have the following installed:

```bash
# Nix with flakes enabled
curl -L https://nixos.org/nix/install | sh
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Git
nix-env -iA nixpkgs.git

# Age for secrets management
nix-env -iA nixpkgs.age

# SOPS for secrets encryption
nix-env -iA nixpkgs.sops
```

### Development Shells

Our flake provides several development shells for different purposes:

#### Default Development Shell

```bash
# Enter the default development shell
nix develop

# Or use direnv for automatic activation
echo "use flake" > .envrc
direnv allow
```

#### Specialized Development Shells

```bash
# Rust development
nix develop .#rust

# Python development
nix develop .#python

# Node.js development
nix develop .#nodejs

# Go development
nix develop .#go

# Documentation development
nix develop .#docs
```

### Development Shell Features

Each development shell includes:

- **Language-specific tools**: Compilers, interpreters, package managers
- **Development utilities**: Formatters, linters, debuggers
- **Testing tools**: Test runners, coverage tools
- **Documentation tools**: Generators, viewers
- **Git hooks**: Pre-commit, pre-push validation

## Development Workflows

### Quick Start Development

1. **Clone and Setup**:

   ```bash
   git clone <repository-url> ~/.dotfiles
   cd ~/.dotfiles
   nix develop
   ```

1. **Initialize Development Environment**:

   ```bash
   # Run initial setup
   ./scripts/flake-check.sh --init

   # Install Git hooks
   ./scripts/secrets-manager.sh install-hooks
   ```

1. **Validate Configuration**:

   ```bash
   # Quick validation
   ./scripts/flake-check.sh

   # Comprehensive testing
   ./scripts/test-framework.sh
   ```

### Making Changes

#### Configuration Changes

1. **Edit Configuration Files**:

   ```bash
   # Edit system configuration
   $EDITOR systems/darwin/NIXY.nix

   # Edit user configuration
   $EDITOR users/alex/home.nix

   # Edit module
   $EDITOR modules/darwin/homebrew.nix
   ```

1. **Validate Changes**:

   ```bash
   # Check syntax
   ./scripts/flake-check.sh --syntax-only

   # Test build
   ./scripts/flake-check.sh --build-only
   ```

1. **Test Locally**:

   ```bash
   # Test Darwin configuration
   darwin-rebuild check --flake .#NIXY

   # Test Home Manager configuration
   home-manager build --flake .#alex@NIXY
   ```

#### Adding New Systems

1. **Create System Configuration**:

   ```bash
   # Copy template
   cp systems/darwin/template.nix systems/darwin/NEWSYSTEM.nix

   # Edit configuration
   $EDITOR systems/darwin/NEWSYSTEM.nix
   ```

1. **Update Flake Outputs**:

   ```bash
   # Add to flake.nix
   $EDITOR flake.nix
   ```

1. **Create System Secrets**:

   ```bash
   # Create system-specific secrets
   ./scripts/secrets-manager.sh create-system NEWSYSTEM
   ```

1. **Test New System**:

   ```bash
   # Test build
   nix build .#darwinConfigurations.NEWSYSTEM.system
   ```

#### Adding New Users

1. **Create User Configuration**:

   ```bash
   # Copy template
   cp users/template.nix users/newuser.nix

   # Edit configuration
   $EDITOR users/newuser.nix
   ```

1. **Create User Secrets**:

   ```bash
   # Create user-specific secrets
   ./scripts/secrets-manager.sh create-user newuser
   ```

1. **Update System Configuration**:

   ```bash
   # Add user to system
   $EDITOR systems/darwin/SYSTEM.nix
   ```

### Secrets Development

#### Working with Secrets

1. **Create Development Secrets**:

   ```bash
   # Create development environment secrets
   ./scripts/secrets-manager.sh create development test-secrets
   ```

1. **Edit Secrets Safely**:

   ```bash
   # Edit with SOPS
   ./scripts/secrets-manager.sh edit development secrets.yaml
   ```

1. **Test Secret Integration**:

   ```bash
   # Validate secrets configuration
   ./scripts/secrets-manager.sh validate

   # Test decryption
   ./scripts/secrets-manager.sh decrypt development secrets.yaml
   ```

#### Secret Templates

Create reusable secret templates:

```yaml
# templates/api-secrets.yaml
api_keys:
  service_a: "PLACEHOLDER_SERVICE_A_KEY"
  service_b: "PLACEHOLDER_SERVICE_B_KEY"
  
database:
  username: "PLACEHOLDER_DB_USER"
  password: "PLACEHOLDER_DB_PASS"
```

## Testing Framework

### Quick Tests

```bash
# Run all quick tests
./scripts/flake-check.sh

# Run specific test categories
./scripts/flake-check.sh --syntax-only
./scripts/flake-check.sh --build-only
./scripts/flake-check.sh --secrets-only
```

### Comprehensive Testing

```bash
# Run full test suite
./scripts/test-framework.sh

# Run specific test suites
./scripts/test-framework.sh --suite syntax
./scripts/test-framework.sh --suite build
./scripts/test-framework.sh --suite secrets
./scripts/test-framework.sh --suite security
./scripts/test-framework.sh --suite performance
```

### Test Categories

#### Syntax Tests

- Nix syntax validation
- YAML syntax validation
- JSON schema validation
- Shell script validation

#### Build Tests

- Darwin configuration builds
- NixOS configuration builds
- Home Manager configuration builds
- Development shell builds

#### Secrets Tests

- SOPS configuration validation
- Age key validation
- Secret file encryption/decryption
- Secret integration tests

#### Security Tests

- Secret scanning
- Permission validation
- Vulnerability scanning
- Access control tests

#### Performance Tests

- Build time measurement
- Memory usage analysis
- Startup time testing
- Resource utilization

#### Integration Tests

- End-to-end system tests
- Multi-user scenarios
- Cross-platform compatibility
- Service integration

### Custom Tests

Create custom test files in `tests/`:

```bash
# tests/custom-module-test.nix
{ pkgs, ... }:
{
  name = "custom-module-test";
  
  testScript = ''
    # Test custom module functionality
    machine.succeed("test -f /etc/custom-config")
    machine.succeed("systemctl is-active custom-service")
  '';
}
```

## Code Quality

### Formatting

```bash
# Format all Nix files
nix fmt

# Format specific files
nix fmt systems/darwin/NIXY.nix

# Check formatting without changes
nix fmt --check
```

### Linting

```bash
# Lint Nix files
nix develop -c statix check .

# Lint shell scripts
nix develop -c shellcheck scripts/*.sh

# Lint YAML files
nix develop -c yamllint secrets/ .github/
```

### Code Analysis

```bash
# Dead code detection
nix develop -c deadnix .

# Dependency analysis
nix develop -c nix-tree --derivation .#darwinConfigurations.NIXY.system

# Security scanning
nix develop -c vulnix .#darwinConfigurations.NIXY.system
```

### Pre-commit Hooks

Install and configure pre-commit hooks:

```bash
# Install hooks
./scripts/secrets-manager.sh install-hooks

# Manual hook execution
.git/hooks/pre-commit

# Skip hooks (emergency only)
git commit --no-verify
```

## Contributing

### Contribution Workflow

1. **Fork and Clone**:

   ```bash
   git clone <your-fork-url>
   cd .dotfiles
   ```

1. **Create Feature Branch**:

   ```bash
   git checkout -b feature/new-feature
   ```

1. **Make Changes**:

   ```bash
   # Edit files
   $EDITOR file.nix

   # Test changes
   ./scripts/flake-check.sh
   ```

1. **Commit Changes**:

   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

1. **Push and Create PR**:

   ```bash
   git push origin feature/new-feature
   # Create pull request on GitHub
   ```

### Commit Message Format

Follow conventional commits:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Types:

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Maintenance tasks

Examples:

```
feat(darwin): add homebrew module
fix(secrets): resolve decryption issue
docs(readme): update installation guide
```

### Code Review Guidelines

#### For Contributors

- Write clear, descriptive commit messages
- Include tests for new functionality
- Update documentation as needed
- Ensure all tests pass
- Follow existing code style

#### For Reviewers

- Check functionality and correctness
- Verify test coverage
- Review security implications
- Ensure documentation is updated
- Test changes locally

### Module Development

#### Creating New Modules

1. **Module Structure**:

   ```nix
   # modules/category/module-name.nix
   { config, lib, pkgs, ... }:

   with lib;

   let
     cfg = config.modules.category.module-name;
   in
   {
     options.modules.category.module-name = {
       enable = mkEnableOption "module description";
       
       option1 = mkOption {
         type = types.str;
         default = "default-value";
         description = "Option description";
       };
     };
     
     config = mkIf cfg.enable {
       # Module implementation
     };
   }
   ```

1. **Module Documentation**:

   ```nix
   # Add to module
   meta = {
     maintainers = with lib.maintainers; [ your-name ];
     doc = ./module-name.md;
   };
   ```

1. **Module Tests**:

   ```nix
   # tests/module-name-test.nix
   import ./make-test-python.nix ({ pkgs, ... }: {
     name = "module-name-test";
     
     nodes.machine = { ... }: {
       imports = [ ../modules/category/module-name.nix ];
       modules.category.module-name.enable = true;
     };
     
     testScript = ''
       machine.wait_for_unit("module-service")
       machine.succeed("test-command")
     '';
   })
   ```

## Debugging

### Common Debugging Techniques

#### Build Debugging

```bash
# Verbose build output
nix build --verbose .#darwinConfigurations.NIXY.system

# Show build logs
nix log .#darwinConfigurations.NIXY.system

# Debug evaluation
nix eval --show-trace .#darwinConfigurations.NIXY.system
```

#### Configuration Debugging

```bash
# Check configuration syntax
nix-instantiate --parse file.nix

# Evaluate configuration
nix eval --file file.nix

# Show configuration tree
nix-tree .#darwinConfigurations.NIXY.system
```

#### Secrets Debugging

```bash
# Debug SOPS configuration
sops --config .sops.yaml --decrypt secrets/development/secrets.yaml

# Check age key
age-keygen -y ~/.config/sops/age/keys.txt

# Validate secrets
./scripts/secrets-manager.sh validate --verbose
```

### Debug Tools

#### Nix REPL

```bash
# Start Nix REPL
nix repl

# Load flake
:lf .

# Explore outputs
outputs.darwinConfigurations.NIXY.config
```

#### System Debugging

```bash
# Check system state
darwin-rebuild --flake .#NIXY --show-trace

# Debug Home Manager
home-manager build --flake .#alex@NIXY --show-trace

# Check service status
launchctl list | grep nix
```

## Performance

### Build Performance

#### Optimization Techniques

1. **Use Binary Caches**:

   ```nix
   # nix.conf
   substituters = https://cache.nixos.org https://nix-community.cachix.org
   trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
   ```

1. **Parallel Builds**:

   ```nix
   # nix.conf
   max-jobs = auto
   cores = 0
   ```

1. **Build Optimization**:

   ```bash
   # Use --fast for development
   darwin-rebuild switch --flake .#NIXY --fast

   # Skip unnecessary rebuilds
   darwin-rebuild switch --flake .#NIXY --option eval-cache true
   ```

#### Performance Monitoring

```bash
# Measure build time
time nix build .#darwinConfigurations.NIXY.system

# Profile memory usage
nix build --option trace-function-calls true .#darwinConfigurations.NIXY.system

# Analyze dependencies
nix-tree .#darwinConfigurations.NIXY.system
```

### Runtime Performance

#### System Optimization

```bash
# Check system performance
./scripts/system-manager.sh status NIXY

# Monitor resource usage
./scripts/system-manager.sh monitor NIXY

# Performance report
./scripts/test-framework.sh --suite performance
```

## CI/CD

### GitHub Actions

Our CI/CD pipeline includes:

#### Workflow Files

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: cachix/install-nix-action@v18
      - name: Run tests
        run: ./scripts/test-framework.sh
```

#### Build Matrix

Test across multiple platforms:

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest]
    nix-version: [2.13.3, 2.14.1]
```

#### Caching

```yaml
- uses: cachix/cachix-action@v12
  with:
    name: your-cache
    authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'
```

### Local CI Testing

```bash
# Run CI tests locally
act

# Test specific workflow
act -j test

# Test with secrets
act -s GITHUB_TOKEN=your-token
```

### Deployment Pipeline

#### Staging Deployment

```bash
# Deploy to staging
./scripts/system-manager.sh deploy staging NIXY

# Run staging tests
./scripts/test-framework.sh --environment staging
```

#### Production Deployment

```bash
# Deploy to production
./scripts/system-manager.sh deploy production NIXY

# Health check
./scripts/system-manager.sh health-check NIXY

# Rollback if needed
./scripts/system-manager.sh rollback NIXY
```

______________________________________________________________________

This development guide provides comprehensive coverage of development workflows, testing, and contribution guidelines. For specific issues, consult the debugging section or create an issue in the repository.
