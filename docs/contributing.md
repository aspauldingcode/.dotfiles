# 📋 Contributing Guidelines

Welcome to our Nix flake configuration project! This document outlines how to contribute effectively to our codebase.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Standards](#code-standards)
- [Testing Requirements](#testing-requirements)
- [Documentation Guidelines](#documentation-guidelines)
- [Pull Request Process](#pull-request-process)
- [Issue Reporting](#issue-reporting)
- [Security Considerations](#security-considerations)
- [Community Guidelines](#community-guidelines)

## Getting Started

### Prerequisites

Before contributing, ensure you have:

1. **Nix with Flakes**:

   ```bash
   curl -L https://nixos.org/nix/install | sh
   echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
   ```

1. **Git Configuration**:

   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

1. **Development Tools**:

   ```bash
   # Enter development shell
   nix develop

   # Install pre-commit hooks
   ./scripts/secrets-manager.sh install-hooks
   ```

### Fork and Clone

1. **Fork the Repository**:

   - Click "Fork" on the GitHub repository page
   - Clone your fork locally:

   ```bash
   git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

1. **Add Upstream Remote**:

   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/dotfiles.git
   ```

1. **Verify Setup**:

   ```bash
   ./scripts/flake-check.sh
   ```

## Development Workflow

### Branch Strategy

We use a feature branch workflow:

```
main (production-ready)
├── develop (integration branch)
├── feature/new-module
├── fix/bug-description
├── docs/update-readme
└── refactor/cleanup-modules
```

### Creating a Feature Branch

```bash
# Update your fork
git checkout main
git pull upstream main
git push origin main

# Create feature branch
git checkout -b feature/descriptive-name

# Make your changes
# ... edit files ...

# Test changes
./scripts/flake-check.sh
./scripts/test-framework.sh

# Commit changes
git add .
git commit -m "feat: add new feature"

# Push to your fork
git push origin feature/descriptive-name
```

### Commit Message Format

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

#### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD changes
- `perf`: Performance improvements
- `security`: Security improvements

#### Examples

```bash
# Feature addition
git commit -m "feat(darwin): add homebrew module for package management"

# Bug fix
git commit -m "fix(secrets): resolve SOPS decryption issue with age keys"

# Documentation
git commit -m "docs(readme): update installation instructions for macOS"

# Breaking change
git commit -m "feat(modules)!: restructure module system

BREAKING CHANGE: Module imports now require explicit path specification"
```

### Code Review Process

1. **Self-Review**:

   - Run all tests: `./scripts/test-framework.sh`
   - Check formatting: `nix fmt`
   - Validate syntax: `./scripts/flake-check.sh --syntax-only`
   - Review your own changes

1. **Create Pull Request**:

   - Use descriptive title and description
   - Link related issues
   - Add screenshots for UI changes
   - Request specific reviewers if needed

1. **Address Feedback**:

   - Respond to review comments
   - Make requested changes
   - Push updates to the same branch

## Code Standards

### Nix Code Style

#### Formatting

```nix
# Use nixpkgs-fmt (automatic with `nix fmt`)
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.example;
in
{
  options.modules.example = {
    enable = mkEnableOption "example module";
    
    package = mkOption {
      type = types.package;
      default = pkgs.example;
      description = "Package to use for example";
    };
  };
  
  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
```

#### Best Practices

1. **Use `with lib` sparingly**:

   ```nix
   # Good
   { lib, ... }:
   {
     options.example = lib.mkOption { ... };
   }

   # Avoid
   { lib, ... }:
   with lib;
   {
     options.example = mkOption { ... };
   }
   ```

1. **Prefer explicit imports**:

   ```nix
   # Good
   { config, lib, pkgs, ... }:

   # Avoid
   { ... }@args:
   ```

1. **Use descriptive variable names**:

   ```nix
   # Good
   let
     homeDirectory = config.users.users.${username}.home;
     configFile = "${homeDirectory}/.config/app/config.json";
   in

   # Avoid
   let
     hd = config.users.users.${username}.home;
     cf = "${hd}/.config/app/config.json";
   in
   ```

### Module Structure

```nix
# modules/category/module-name.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.category.module-name;
  
  # Helper functions
  mkConfigFile = content: pkgs.writeText "config.json" (builtins.toJSON content);
in
{
  # Module metadata
  meta = {
    maintainers = with maintainers; [ your-name ];
    doc = ./module-name.md;
  };
  
  # Options definition
  options.modules.category.module-name = {
    enable = mkEnableOption "module description";
    
    package = mkOption {
      type = types.package;
      default = pkgs.module-name;
      description = "Package to use";
    };
    
    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Configuration settings";
    };
  };
  
  # Implementation
  config = mkIf cfg.enable {
    # Package installation
    environment.systemPackages = [ cfg.package ];
    
    # Configuration files
    environment.etc."module-name/config.json".source = mkConfigFile cfg.settings;
    
    # Services
    systemd.services.module-name = {
      description = "Module Name Service";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/module-name";
        Restart = "always";
      };
    };
  };
}
```

### Shell Script Standards

```bash
#!/usr/bin/env bash

# Strict error handling
set -euo pipefail

# Script metadata
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Global variables
declare -r DEFAULT_ENVIRONMENT="development"
declare -a SYSTEMS=("NIXY" "NIXSTATION64" "NIXY2")

# Functions
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] COMMAND [ARGS...]

DESCRIPTION
    Brief description of what the script does.

OPTIONS
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -e, --environment   Set environment (default: $DEFAULT_ENVIRONMENT)

COMMANDS
    command1            Description of command1
    command2            Description of command2

EXAMPLES
    $SCRIPT_NAME --verbose command1 arg1
    $SCRIPT_NAME --environment production command2

EOF
}

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

error() {
    log "ERROR: $*"
    exit 1
}

main() {
    local environment="$DEFAULT_ENVIRONMENT"
    local verbose=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -e|--environment)
                environment="$2"
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Validate arguments
    [[ $# -eq 0 ]] && { usage; exit 1; }
    
    local command="$1"
    shift
    
    # Execute command
    case "$command" in
        command1)
            command1_function "$@"
            ;;
        command2)
            command2_function "$@"
            ;;
        *)
            error "Unknown command: $command"
            ;;
    esac
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## Testing Requirements

### Test Categories

1. **Syntax Tests**: Validate Nix and shell syntax
1. **Build Tests**: Ensure configurations build successfully
1. **Integration Tests**: Test module interactions
1. **Security Tests**: Validate security configurations
1. **Performance Tests**: Check build and runtime performance

### Running Tests

```bash
# Quick tests (required before commit)
./scripts/flake-check.sh

# Comprehensive tests (required before PR)
./scripts/test-framework.sh

# Specific test suites
./scripts/test-framework.sh --suite syntax
./scripts/test-framework.sh --suite build
./scripts/test-framework.sh --suite security
```

### Writing Tests

#### Module Tests

```nix
# tests/modules/example-test.nix
import ../make-test-python.nix ({ pkgs, ... }: {
  name = "example-module-test";
  
  nodes.machine = { ... }: {
    imports = [ ../../modules/example.nix ];
    modules.example.enable = true;
  };
  
  testScript = ''
    machine.wait_for_unit("example.service")
    machine.succeed("systemctl is-active example.service")
    machine.succeed("test -f /etc/example/config.json")
  '';
})
```

#### Shell Script Tests

```bash
# tests/scripts/test-example.sh
#!/usr/bin/env bash

set -euo pipefail

# Test setup
readonly TEST_DIR="$(mktemp -d)"
readonly SCRIPT_PATH="$PROJECT_ROOT/scripts/example.sh"

cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Test cases
test_help_option() {
    "$SCRIPT_PATH" --help > /dev/null
    echo "✓ Help option works"
}

test_invalid_command() {
    if "$SCRIPT_PATH" invalid-command 2>/dev/null; then
        echo "✗ Should fail on invalid command"
        return 1
    fi
    echo "✓ Invalid command handling works"
}

# Run tests
main() {
    echo "Running tests for example.sh..."
    test_help_option
    test_invalid_command
    echo "All tests passed!"
}

main "$@"
```

## Documentation Guidelines

### Documentation Structure

```
docs/
├── README.md                 # Main documentation
├── secrets-guide.md          # Secrets management
├── development-guide.md      # Development workflows
├── troubleshooting.md        # Common issues
├── deployment-guide.md       # Deployment procedures
├── contributing.md           # This file
└── modules/                  # Module-specific docs
    ├── darwin/
    ├── nixos/
    └── home-manager/
```

### Writing Guidelines

1. **Use Clear Headings**: Structure with H1-H6 headers
1. **Include Code Examples**: Show practical usage
1. **Add Table of Contents**: For longer documents
1. **Use Consistent Formatting**: Follow existing style
1. **Include Screenshots**: For UI-related changes

### Module Documentation

Each module should include:

````markdown
# Module Name

Brief description of what the module does.

## Options

### `modules.category.module-name.enable`
- **Type**: `boolean`
- **Default**: `false`
- **Description**: Enable the module

### `modules.category.module-name.package`
- **Type**: `package`
- **Default**: `pkgs.module-name`
- **Description**: Package to use

## Examples

```nix
{
  modules.category.module-name = {
    enable = true;
    package = pkgs.custom-package;
  };
}
````

## Troubleshooting

Common issues and solutions.

````

## Pull Request Process

### Before Creating a PR

1. **Update your branch**:
   ```bash
   git checkout main
   git pull upstream main
   git checkout your-feature-branch
   git rebase main
````

2. **Run tests**:

   ```bash
   ./scripts/test-framework.sh
   ```

1. **Update documentation**:

   - Update relevant docs
   - Add changelog entry if needed

### PR Template

```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tests pass locally
- [ ] Added tests for new functionality
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No secrets in code
```

### Review Process

1. **Automated Checks**: CI/CD pipeline runs tests
1. **Code Review**: Maintainers review changes
1. **Approval**: At least one approval required
1. **Merge**: Squash and merge to main

## Issue Reporting

### Bug Reports

Use the bug report template:

```markdown
## Bug Description
Clear description of the bug.

## Steps to Reproduce
1. Step one
2. Step two
3. Step three

## Expected Behavior
What should happen.

## Actual Behavior
What actually happens.

## Environment
- OS: [macOS/NixOS/Linux]
- Nix version: [output of `nix --version`]
- System: [NIXY/NIXSTATION64/etc.]

## Additional Context
Any other relevant information.
```

### Feature Requests

Use the feature request template:

```markdown
## Feature Description
Clear description of the proposed feature.

## Use Case
Why is this feature needed?

## Proposed Solution
How should this be implemented?

## Alternatives Considered
Other approaches considered.

## Additional Context
Any other relevant information.
```

## Security Considerations

### Security Guidelines

1. **Never commit secrets**: Use SOPS for all sensitive data
1. **Review dependencies**: Check for known vulnerabilities
1. **Use secure defaults**: Enable security features by default
1. **Validate inputs**: Sanitize user inputs in scripts
1. **Follow principle of least privilege**: Minimal permissions

### Security Review Process

1. **Automated scanning**: Security tests run on all PRs
1. **Manual review**: Security-sensitive changes get extra review
1. **Dependency updates**: Regular updates for security patches

### Reporting Security Issues

For security vulnerabilities:

1. **Do not create public issues**
1. **Email security@company.com** with details
1. **Include proof of concept** if applicable
1. **Allow time for fix** before disclosure

## Community Guidelines

### Code of Conduct

We follow the [Contributor Covenant](https://www.contributor-covenant.org/):

1. **Be respectful**: Treat everyone with respect
1. **Be inclusive**: Welcome diverse perspectives
1. **Be constructive**: Provide helpful feedback
1. **Be patient**: Help newcomers learn

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas
- **Pull Requests**: Code review and discussion
- **Email**: security@company.com for security issues

### Recognition

Contributors are recognized through:

- **Commit attribution**: Your commits show your contributions
- **Changelog mentions**: Significant contributions noted
- **Maintainer status**: Active contributors may become maintainers

______________________________________________________________________

Thank you for contributing to our Nix flake configuration! Your contributions help make this project better for everyone.
