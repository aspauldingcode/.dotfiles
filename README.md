# 🏠 Alex's Universal Dotfiles

A comprehensive, production-ready Nix configuration using `flake-parts` for managing NixOS, Darwin, and Home Manager configurations across multiple architectures and environments.

## ✨ Features

- 🔧 **Multi-Platform Support**: macOS (Darwin), NixOS (x86_64 & aarch64), Mobile NixOS
- 🏗️ **Modular Architecture**: Clean separation using flake-parts
- 🔐 **Production-Ready Secrets**: SOPS-nix with age encryption
- 🚀 **Automated CI/CD**: GitHub Actions with comprehensive checks
- 📱 **Mobile Support**: OnePlus 6T with Mobile NixOS
- 🎯 **Environment Separation**: Production, staging, development configurations
- 🛠️ **Developer Experience**: Rich development shells and tools

<!-- BEGIN CODE STATS -->
## How much code?

👨‍💻 Code Statistics:

_Total LOC (including blanks, comments): **47296**_

<details>
<summary>🔍 Click to expand code stats.</summary>

| Language   | Files | Lines | Code  | Comments | Blanks |
|------------|-------|-------|-------|----------|--------|
| CSS | 6 | 3734 | 2832 | 220 | 682 |
| JSON | 1 | 402 | 402 | 0 | 0 |
| Lua | 1 | 225 | 138 | 50 | 37 |
| Markdown | 14 | 3872 | 0 | 2562 | 1310 |
| Nix | 233 | 32845 | 27346 | 3224 | 2275 |
| Python | 5 | 1617 | 1407 | 61 | 149 |
| Shell | 18 | 4060 | 2988 | 390 | 682 |
| Plain Text | 1 | 1 | 0 | 1 | 0 |
| TOML | 1 | 56 | 47 | 5 | 4 |
| Vim script | 0 | 0 |  |  |  |
| YAML | 9 | 484 | 304 | 160 | 20 |
| **Total**  | 289 | 47296 | 35464 | 6673 | 5159 |

</details>

Last updated: Mon Aug 18 16:37:04 PDT 2025
<!-- END CODE STATS -->

## 🖥️ Supported Systems

| System | Architecture | Hostname | Status |
|--------|-------------|----------|---------|
| macOS | aarch64-darwin | NIXY | ✅ Active |
| macOS | x86_64-darwin | NIXI | ✅ Active |
| NixOS Desktop | x86_64-linux | NIXSTATION64 | ✅ Active |
| NixOS ARM | aarch64-linux | NIXY2 | ✅ Active |
| Mobile NixOS | aarch64-linux | NIXEDUP (OnePlus 6T) | 🧪 Experimental |

## 🏗️ Repository Structure

This repository follows a standardized `flake-parts` structure for better organization and maintainability:

```
.
├── flake.nix                 # Main flake entry point
├── flake.lock               # Flake lock file
├── parts/                   # Flake-parts modules
│   ├── lib.nix             # Library functions
│   ├── overlays.nix        # Nixpkgs overlays
│   ├── sops.nix            # SOPS secrets management
│   ├── common.nix          # Common configurations
│   ├── nixos-configurations.nix
│   ├── darwin-configurations.nix
│   ├── home-configurations.nix
│   ├── packages.nix        # Custom packages
│   ├── apps.nix            # Flake applications
│   ├── devshells.nix       # Development shells
│   ├── docs.nix            # Documentation
│   ├── ci.nix              # CI/CD scripts
│   ├── formatter.nix       # Code formatting
│   └── checks.nix          # Flake checks
├── modules/                 # Reusable modules
│   ├── nixos/              # NixOS modules
│   ├── darwin/             # Darwin modules
│   └── home-manager/       # Home Manager modules
├── hosts/                   # System configurations
│   ├── nixos/              # NixOS hosts
│   │   ├── NIXSTATION64/   # Desktop workstation
│   │   ├── NIXY2/          # ARM development board
│   │   └── NIXEDUP/        # OnePlus 6T mobile
│   ├── darwin/             # Darwin hosts
│   │   └── NIXY/           # MacBook Pro M1
│   └── extraConfig/        # SSH keys and additional configs
├── profiles/                # Reusable configuration profiles
│   ├── desktop/            # Desktop environment
│   ├── server/             # Server configuration
│   ├── mobile/             # Mobile optimizations
│   └── development/        # Development tools
├── users/                   # User-specific configurations
│   ├── alex/               # Primary user
│   └── susu/               # Secondary user
├── secrets/                 # SOPS-encrypted secrets
│   ├── production/         # Production environment
│   ├── staging/            # Staging environment
│   ├── development/        # Development environment
│   ├── systems/            # System-specific secrets
│   └── users/              # User-specific secrets
├── scripts/                 # Management scripts
├── docs/                   # Comprehensive documentation
├── lib/                    # Helper functions
├── overlays/               # Package overlays
├── shared/                 # Shared configurations
└── tools/                  # Utility tools
```

## 🚀 Quick Start

### Prerequisites

```bash
# Install Nix with flakes support
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Clone the repository
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### Building Systems

```bash
# NixOS systems
nix build .#nixosConfigurations.NIXSTATION64.config.system.build.toplevel
nix build .#nixosConfigurations.NIXY2.config.system.build.toplevel
nix build .#nixosConfigurations.NIXEDUP.config.system.build.toplevel

# Darwin systems
nix build .#darwinConfigurations.NIXY.system
nix build .#darwinConfigurations.NIXI.system

# Home Manager configurations
nix build .#homeConfigurations.alex.activationPackage
```

### Deploying Systems

```bash
# NixOS (run on target system)
sudo nixos-rebuild switch --flake .#NIXSTATION64
sudo nixos-rebuild switch --flake .#NIXY2
sudo nixos-rebuild switch --flake .#NIXEDUP

# Darwin (run on macOS)
darwin-rebuild switch --flake .#NIXY
darwin-rebuild switch --flake .#NIXI

# Home Manager (run as user)
home-manager switch --flake .#alex

# Automated deployment (detects current system)
nix run .#ci-deploy
```

### Development Workflow

```bash
# Enter development shell with all tools
nix develop

# Format code
nix fmt

# Check flake validity
nix flake check

# Run comprehensive CI checks
nix run .#ci-check

# Serve documentation locally
nix run .#docs-serve
```

## 📦 Available Applications

Run applications with `nix run .#<app-name>`:

| Application | Description |
|-------------|-------------|
| `default` | System information and flake overview |
| `system-info` | Detailed system information |
| `secrets-manager` | Interactive SOPS secrets management |
| `mobile-installer` | Mobile NixOS installer for OnePlus 6T |
| `update-readme` | Update README.md with current code statistics |
| `ci-check` | Comprehensive CI/CD checks |
| `ci-deploy` | Automated system deployment |
| `docs-serve` | Local documentation server |

### Examples

```bash
# Get system information
nix run .#default

# Manage secrets interactively
nix run .#secrets-manager

# Update code statistics in README
nix run .#update-readme

# Run all CI checks
nix run .#ci-check

# Deploy current system
nix run .#ci-deploy
```

## 🔧 Configuration Management

### Adding a New Host

1. **Create host directory**:

   ```bash
   mkdir -p hosts/{nixos,darwin}/hostname
   ```

1. **Create configuration**:

   ```nix
   # hosts/nixos/hostname/default.nix
   { config, lib, pkgs, ... }: {
     imports = [
       ./hardware-configuration.nix
       ../../../profiles/desktop
     ];
     
     networking.hostName = "hostname";
     # Additional configuration...
   }
   ```

1. **Add to flake configuration**:

   ```nix
   # parts/nixos-configurations.nix
   hostname = inputs.nixpkgs.lib.nixosSystem {
     # Configuration...
   };
   ```

### Adding a New Module

1. **Create module**:

   ```bash
   mkdir -p modules/{nixos,darwin,home-manager}/module-name
   ```

1. **Implement module**:

   ```nix
   # modules/nixos/module-name/default.nix
   { config, lib, pkgs, ... }: {
     options = {
       # Module options...
     };
     
     config = {
       # Module implementation...
     };
   }
   ```

1. **Import in default.nix**:

   ```nix
   # modules/nixos/default.nix
   {
     imports = [
       ./module-name
       # Other modules...
     ];
   }
   ```

### Adding a New Profile

1. **Create profile directory**:

   ```bash
   mkdir -p profiles/profile-name
   ```

1. **Define profile**:

   ```nix
   # profiles/profile-name/default.nix
   { config, lib, pkgs, ... }: {
     imports = [
       # Required modules...
     ];
     
     # Profile configuration...
   }
   ```

1. **Import in profiles**:

   ```nix
   # profiles/default.nix
   {
     profile-name = import ./profile-name;
   }
   ```

## 🔐 Secrets Management

This configuration uses **SOPS-nix** with **age encryption** for production-ready secrets management:

### Quick Commands

```bash
# Edit secrets (environment-specific)
sops secrets/production/secrets.yaml
sops secrets/development/secrets.yaml
sops secrets/users/alex.yaml

# Rekey secrets after adding new recipients
sops updatekeys secrets/production/secrets.yaml

# Interactive secrets management
nix run .#secrets-manager

# Validate all secrets
./scripts/secrets-manager.sh validate

# Audit secret access
./scripts/secrets-manager.sh audit
```

### Environment Structure

- **Production**: `secrets/production/` - Live environment secrets
- **Staging**: `secrets/staging/` - Pre-production testing
- **Development**: `secrets/development/` - Local development
- **Users**: `secrets/users/` - Personal API keys and configs
- **Systems**: `secrets/systems/` - Host-specific secrets

### Documentation

- 📖 [SOPS-nix Implementation Guide](docs/sops-nix-implementation.md) - Complete production deployment guide
- 🔧 [Secrets Management Guide](docs/secrets-guide.md) - Comprehensive secrets documentation

## 📚 Documentation

### Core Documentation

- 🚀 [Development Guide](docs/development-guide.md) - Development setup and workflows
- 🤝 [Contributing Guidelines](docs/contributing.md) - How to contribute to this project
- 🚢 [Deployment Guide](docs/deployment-guide.md) - Production deployment procedures
- 📋 [Deployment Runbook](docs/deployment-runbook.md) - Step-by-step deployment instructions
- 🔍 [Troubleshooting Guide](docs/troubleshooting.md) - Common issues and solutions
- 📊 [Project Status](docs/project-status.md) - Current project status and roadmap

### Quick Links

- [Module Documentation](docs/modules/) - Detailed module documentation
- [Host Configuration Examples](docs/hosts/) - Host-specific configuration guides
- [API Documentation](docs/api/) - Internal API documentation

## 🧪 Testing & Quality Assurance

### Automated Testing

```bash
# Run all checks (recommended before commits)
nix flake check

# Test specific system builds (dry-run)
nix build .#nixosConfigurations.NIXSTATION64.config.system.build.toplevel --dry-run
nix build .#darwinConfigurations.NIXY.system --dry-run

# Format check
nix fmt --check

# Comprehensive CI checks
nix run .#ci-check
```

### Manual Testing

```bash
# Test secrets decryption
./scripts/secrets-manager.sh validate

# Test system deployment (dry-run)
sudo nixos-rebuild dry-run --flake .#NIXSTATION64

# Test Home Manager configuration
home-manager build --flake .#alex
```

### Continuous Integration

- ✅ **Flake validation**: Ensures flake.nix is valid
- ✅ **Format checking**: Code formatting with treefmt
- ✅ **Build testing**: All system configurations build successfully
- ✅ **Secrets validation**: All secrets can be decrypted
- ✅ **Documentation**: Links and references are valid

## 🚀 Deployment

### Automated Deployment

```bash
# Deploy current system automatically
nix run .#ci-deploy
```

### Manual Deployment

```bash
# NixOS systems
sudo nixos-rebuild switch --flake .#NIXSTATION64

# Darwin systems
darwin-rebuild switch --flake .#NIXY

# Home Manager
home-manager switch --flake .#alex
```

### Remote Deployment

```bash
# Deploy to remote NixOS system
nixos-rebuild switch --flake .#NIXSTATION64 --target-host user@hostname

# Deploy using deploy-rs (if configured)
deploy .#NIXSTATION64
```

## 🛠️ Development

### Development Shell

```bash
# Enter development environment
nix develop

# Available tools in dev shell:
# - nix, nixpkgs-fmt, treefmt
# - sops, age, ssh-to-age
# - git, gh, pre-commit
# - mdbook (for documentation)
```

### Code Formatting

```bash
# Format all code
nix fmt

# Check formatting
nix fmt --check
```

### Pre-commit Hooks

```bash
# Install pre-commit hooks
pre-commit install

# Run hooks manually
pre-commit run --all-files
```

## 📱 Mobile NixOS (Experimental)

This configuration includes experimental support for Mobile NixOS on OnePlus 6T:

```bash
# Build mobile image
nix build .#nixosConfigurations.NIXEDUP.config.system.build.android-bootimg

# Install mobile helper
nix run .#mobile-installer

# Flash to device (requires unlocked bootloader)
fastboot flash boot result/boot.img
fastboot reboot
```

**Note**: Mobile NixOS support is experimental and may require additional setup.

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](docs/contributing.md) for details on:

- Code style and formatting
- Commit message conventions
- Pull request process
- Testing requirements
- Documentation standards

### Quick Contribution Workflow

1. **Fork and clone** the repository
1. **Create a feature branch**: `git checkout -b feature/amazing-feature`
1. **Make changes** and test thoroughly
1. **Format code**: `nix fmt`
1. **Run checks**: `nix flake check`
1. **Commit changes**: Follow conventional commit format
1. **Push and create** a pull request

## 📄 License

This configuration is available under the **MIT License**. See [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- [NixOS](https://nixos.org/) - The purely functional Linux distribution
- [nix-darwin](https://github.com/LnL7/nix-darwin) - Nix modules for macOS
- [Home Manager](https://github.com/nix-community/home-manager) - User environment management
- [flake-parts](https://github.com/hercules-ci/flake-parts) - Modular flake framework
- [SOPS](https://github.com/mozilla/sops) - Secrets management
- [Mobile NixOS](https://mobile.nixos.org/) - NixOS for mobile devices

______________________________________________________________________

**Made with ❤️ and Nix** | [Report Issues](https://github.com/yourusername/dotfiles/issues) | [Discussions](https://github.com/yourusername/dotfiles/discussions)
