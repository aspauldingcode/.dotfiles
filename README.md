# Dotfiles - Standardized Nix Configuration

A comprehensive, modular Nix configuration using `flake-parts` for managing NixOS, Darwin, and Home Manager configurations.

## 🏗️ Structure

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
│   ├── templates.nix       # Flake templates
│   ├── ci.nix              # CI/CD scripts
│   ├── formatter.nix       # Code formatting
│   └── checks.nix          # Flake checks
├── modules/                 # Reusable modules
│   ├── nixos/              # NixOS modules
│   ├── darwin/             # Darwin modules
│   └── home-manager/       # Home Manager modules
├── hosts/                   # System configurations
│   ├── nixos/              # NixOS hosts
│   │   ├── NIXSTATION64/
│   │   ├── NIXY2/
│   │   └── NIXEDUP/
│   ├── darwin/             # Darwin hosts
│   │   └── NIXY/
│   └── extraConfig/        # Additional configurations
├── profiles/                # Reusable configuration profiles
│   ├── desktop/            # Desktop environment
│   ├── server/             # Server configuration
│   ├── mobile/             # Mobile optimizations
│   └── development/        # Development tools
├── lib/                     # Helper functions
├── overlays/               # Package overlays
├── shared/                 # Shared configurations
├── sops-nix/               # SOPS secrets
└── docs/                   # Documentation
```

## 🚀 Quick Start

### Building Systems

```bash
# NixOS systems
nix build .#nixosConfigurations.NIXSTATION64.config.system.build.toplevel
nix build .#nixosConfigurations.NIXY2.config.system.build.toplevel
nix build .#nixosConfigurations.NIXEDUP.config.system.build.toplevel

# Darwin systems
nix build .#darwinConfigurations.NIXY.system

# Home Manager configurations
nix build .#homeConfigurations.alex.activationPackage
```

### Deploying Systems

```bash
# NixOS
sudo nixos-rebuild switch --flake .#NIXSTATION64
sudo nixos-rebuild switch --flake .#NIXY2
sudo nixos-rebuild switch --flake .#NIXEDUP

# Darwin
darwin-rebuild switch --flake .#NIXY

# Home Manager
home-manager switch --flake .#alex
```

### Development

```bash
# Enter development shell
nix develop

# Format code
nix fmt

# Check flake
nix flake check

# Run CI checks
nix run .#ci-check

# Serve documentation
nix run .#docs-serve
```

## 📦 Available Apps

- `default` - System information
- `secrets-manager` - Manage SOPS secrets
- `system-manager` - System management utilities
- `flake-check` - Comprehensive flake validation
- `ci-check` - CI/CD checks
- `ci-deploy` - Automated deployment
- `docs-serve` - Documentation server

## 🔧 Configuration

### Adding a New Host

1. Create host configuration in `hosts/{nixos,darwin}/hostname/`
2. Add to appropriate configuration file in `parts/`
3. Update flake inputs if needed

### Adding a New Module

1. Create module in `modules/{nixos,darwin,home-manager}/`
2. Import in the appropriate `default.nix`
3. Use in host configurations

### Adding a New Profile

1. Create profile in `profiles/profile-name/`
2. Import in `profiles/default.nix`
3. Use in host configurations

## 🔐 Secrets Management

This configuration uses SOPS for secrets management:

```bash
# Edit secrets
sops secrets/secrets.yaml

# Rekey secrets
sops updatekeys secrets/secrets.yaml
```

## 📚 Documentation

- [Contributing Guidelines](docs/CONTRIBUTING.md)
- [Development Setup](docs/DEVELOPMENT.md)
- [Module Documentation](docs/modules/)
- [Host Configuration Guide](docs/hosts/)

## 🧪 Testing

```bash
# Run all checks
nix flake check

# Test specific system
nix build .#nixosConfigurations.NIXSTATION64.config.system.build.toplevel --dry-run

# Format check
nix fmt --check
```

## 📄 License

This configuration is available under the MIT License. See [LICENSE](LICENSE) for details.

## 🤝 Contributing

Please read [CONTRIBUTING.md](docs/CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.
