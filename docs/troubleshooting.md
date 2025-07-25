# 🔧 Troubleshooting Guide

This guide covers common issues and their solutions when working with our Nix flake configuration.

## Table of Contents

- [Common Issues](#common-issues)
- [Build Problems](#build-problems)
- [Secrets Issues](#secrets-issues)
- [System-Specific Problems](#system-specific-problems)
- [Performance Issues](#performance-issues)
- [Recovery Procedures](#recovery-procedures)
- [Diagnostic Tools](#diagnostic-tools)
- [Getting Help](#getting-help)

## Common Issues

### Nix Flake Evaluation Errors

#### Error: "flake.nix not found"
```bash
# Solution: Ensure you're in the correct directory
cd ~/.dotfiles
pwd  # Should show /Users/alex/.dotfiles

# Or specify the flake path explicitly
nix build ~/.dotfiles#darwinConfigurations.NIXY.system  # Apple Silicon
nix build ~/.dotfiles#darwinConfigurations.NIXI.system  # Intel
```

#### Error: "experimental feature 'flakes' is disabled"
```bash
# Solution: Enable flakes in Nix configuration
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Or use temporary flag
nix --experimental-features "nix-command flakes" build .#darwinConfigurations.NIXY.system  # Apple Silicon
nix --experimental-features "nix-command flakes" build .#darwinConfigurations.NIXI.system  # Intel
```

#### Error: "attribute 'darwinConfigurations' missing"
```bash
# Check flake outputs
nix flake show

# Validate flake syntax
nix flake check

# Debug evaluation
nix eval --show-trace .#darwinConfigurations
```

### Git and Version Control Issues

#### Error: "fatal: not a git repository"
```bash
# Initialize git repository
git init
git remote add origin <repository-url>
git fetch
git checkout main
```

#### Error: "Your branch is behind 'origin/main'"
```bash
# Update local repository
git fetch origin
git rebase origin/main

# Or merge changes
git pull origin main
```

#### Error: "merge conflict in flake.lock"
```bash
# Update flake inputs
nix flake update

# Commit the updated lock file
git add flake.lock
git commit -m "chore: update flake inputs"
```

### Permission Issues

#### Error: "Permission denied" when accessing secrets
```bash
# Fix age key permissions
chmod 600 ~/.config/sops/age/keys.txt

# Fix secrets directory permissions
find ~/.dotfiles/secrets -type f -exec chmod 644 {} \;
find ~/.dotfiles/secrets -type d -exec chmod 755 {} \;
```

#### Error: "Operation not permitted" on macOS
```bash
# Grant Full Disk Access to Terminal
# System Preferences > Security & Privacy > Privacy > Full Disk Access
# Add Terminal.app or your terminal emulator

# Or use sudo for system operations
sudo darwin-rebuild switch --flake .#NIXY  # Apple Silicon
sudo darwin-rebuild switch --flake .#NIXI  # Intel
```

## Build Problems

### Darwin Configuration Build Failures

#### Error: "builder for '/nix/store/...' failed"
```bash
# Check build logs
nix log .#darwinConfigurations.NIXY.system

# Build with verbose output
nix build --verbose .#darwinConfigurations.NIXY.system

# Try building without cache
nix build --no-substitute .#darwinConfigurations.NIXY.system
```

#### Error: "infinite recursion encountered"
```bash
# Check for circular imports
nix eval --show-trace .#darwinConfigurations.NIXY.config

# Validate module structure
./scripts/flake-check.sh --syntax-only

# Debug specific module
nix eval --show-trace .#darwinConfigurations.NIXY.config.modules.darwin.homebrew
```

#### Error: "package 'xyz' not found"
```bash
# Search for package
nix search nixpkgs xyz

# Check if package exists in current nixpkgs
nix eval nixpkgs#xyz --no-eval-cache

# Update nixpkgs input
nix flake update nixpkgs
```

### Home Manager Build Failures

#### Error: "collision between files"
```bash
# Check conflicting files
home-manager build --flake .#alex@NIXY 2>&1 | grep collision

# Use lib.mkForce to override
programs.git.extraConfig = lib.mkForce {
  # configuration
};

# Or disable conflicting options
programs.git.enable = false;
```

#### Error: "home-manager not found"
```bash
# Install home-manager
nix profile install nixpkgs#home-manager

# Or use flake directly
nix run home-manager/master -- switch --flake .#alex@NIXY
```

### Development Shell Issues

#### Error: "shell hook failed"
```bash
# Check shell hook syntax
nix develop --command bash -c 'echo "Shell loaded successfully"'

# Debug shell environment
nix develop --command env | grep -E "(PATH|NIX_)"

# Use minimal shell for debugging
nix develop .#minimal
```

#### Error: "command not found in development shell"
```bash
# Check available packages
nix develop --command which <command>

# List all available commands
nix develop --command bash -c 'compgen -c | sort | uniq'

# Add missing package to devShell
devShells.default = pkgs.mkShell {
  packages = with pkgs; [
    # existing packages
    missing-package
  ];
};
```

## Secrets Issues

### SOPS Decryption Failures

#### Error: "no key could decrypt the data"
```bash
# Check age key exists
test -f ~/.config/sops/age/keys.txt && echo "Key found" || echo "Key missing"

# Verify key format
age-keygen -y ~/.config/sops/age/keys.txt

# Check SOPS configuration
cat .sops.yaml

# Test decryption manually
sops --decrypt secrets/development/secrets.yaml
```

#### Error: "age key not found"
```bash
# Generate new age key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# Get public key for .sops.yaml
age-keygen -y ~/.config/sops/age/keys.txt

# Update .sops.yaml with new public key
./scripts/secrets-manager.sh add-recipient $(age-keygen -y ~/.config/sops/age/keys.txt)
```

#### Error: "failed to decrypt sops data key"
```bash
# Check if you're listed as recipient
sops --decrypt --extract '["sops"]["age"]' secrets/development/secrets.yaml

# Re-encrypt with current key
./scripts/secrets-manager.sh re-encrypt secrets/development/secrets.yaml

# Validate all secrets
./scripts/secrets-manager.sh validate
```

### Secrets Integration Issues

#### Error: "sops secret not found"
```bash
# Check secret exists in file
sops --decrypt secrets/development/secrets.yaml | grep secret-name

# Verify secret path in Nix configuration
nix eval .#darwinConfigurations.NIXY.config.sops.secrets

# Test secret access
sudo cat /run/secrets/secret-name
```

#### Error: "secret file permissions incorrect"
```bash
# Check current permissions
ls -la /run/secrets/

# Fix in Nix configuration
sops.secrets.secret-name = {
  mode = "0400";
  owner = "alex";
  group = "staff";
};
```

## System-Specific Problems

### macOS (Darwin) Issues

#### Error: "xcode-select: command line tools not installed"
```bash
# Install Xcode command line tools
xcode-select --install

# Or install full Xcode from App Store
# Then accept license
sudo xcodebuild -license accept
```

#### Error: "System Integrity Protection (SIP) blocking operation"
```bash
# Check SIP status
csrutil status

# Some operations require SIP to be disabled
# Boot into Recovery Mode (Cmd+R) and run:
# csrutil disable

# Re-enable after operation:
# csrutil enable
```

#### Error: "Homebrew not found"
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add to PATH
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### NixOS Issues

#### Error: "systemd service failed to start"
```bash
# Check service status
systemctl status service-name

# View service logs
journalctl -u service-name -f

# Restart service
sudo systemctl restart service-name
```

#### Error: "boot loader installation failed"
```bash
# Check boot loader configuration
sudo nixos-rebuild switch --show-trace

# Manually install boot loader
sudo /run/current-system/bin/switch-to-configuration boot

# Check EFI variables (UEFI systems)
efibootmgr -v
```

### Multi-User Issues

#### Error: "user not found in configuration"
```bash
# Check user definition
nix eval .#darwinConfigurations.NIXY.config.users.users.alex

# Verify user is imported
grep -r "alex" users/

# Add user to system configuration
users.users.alex = {
  name = "alex";
  home = "/Users/alex";
};
```

#### Error: "home directory permissions incorrect"
```bash
# Fix home directory ownership
sudo chown -R alex:staff /Users/alex

# Fix specific directories
sudo chown -R alex:staff ~/.config
sudo chown -R alex:staff ~/.local
```

## Performance Issues

### Slow Build Times

#### Diagnosis
```bash
# Measure build time
time nix build .#darwinConfigurations.NIXY.system

# Profile build
nix build --option trace-function-calls true .#darwinConfigurations.NIXY.system

# Check cache usage
nix build --option log-lines 100 .#darwinConfigurations.NIXY.system
```

#### Solutions
```bash
# Use binary cache
nix.settings.substituters = [
  "https://cache.nixos.org"
  "https://nix-community.cachix.org"
];

# Increase parallel builds
nix.settings.max-jobs = 8;
nix.settings.cores = 4;

# Use faster evaluation
nix build --option eval-cache true .#darwinConfigurations.NIXY.system
```

### High Memory Usage

#### Diagnosis
```bash
# Monitor memory during build
nix build .#darwinConfigurations.NIXY.system &
top -p $!

# Check Nix daemon memory
ps aux | grep nix-daemon
```

#### Solutions
```bash
# Limit memory usage
nix.settings.max-silent-time = 3600;
nix.settings.timeout = 7200;

# Restart Nix daemon
sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist
sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist
```

### Disk Space Issues

#### Diagnosis
```bash
# Check Nix store size
du -sh /nix/store

# List largest store paths
nix path-info --all --size | sort -nk2 | tail -20

# Check garbage collection eligibility
nix-store --gc --print-roots | wc -l
```

#### Solutions
```bash
# Run garbage collection
nix-collect-garbage -d

# Remove old generations
nix-collect-garbage --delete-older-than 7d

# Optimize store
nix-store --optimize
```

## Recovery Procedures

### System Recovery

#### Rollback to Previous Generation
```bash
# List available generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo /nix/var/nix/profiles/system-<number>-link/bin/switch-to-configuration switch

# Or use darwin-rebuild
darwin-rebuild --rollback
```

#### Boot from Recovery
```bash
# macOS Recovery Mode
# Hold Cmd+R during boot

# Boot from USB (NixOS)
# Create bootable USB with NixOS ISO
# Boot from USB and mount existing system
```

### Configuration Recovery

#### Restore from Git
```bash
# Reset to last known good state
git log --oneline -10
git reset --hard <commit-hash>

# Or create recovery branch
git checkout -b recovery-$(date +%Y%m%d)
git reset --hard <good-commit>
```

#### Backup and Restore
```bash
# Create configuration backup
tar -czf dotfiles-backup-$(date +%Y%m%d).tar.gz ~/.dotfiles

# Restore from backup
cd ~
tar -xzf dotfiles-backup-<date>.tar.gz
```

### Secrets Recovery

#### Restore Age Keys
```bash
# From backup
cp /path/to/backup/keys.txt ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# Generate new keys (if backup unavailable)
age-keygen -o ~/.config/sops/age/keys.txt
# Note: Will need to re-encrypt all secrets
```

#### Re-encrypt Secrets
```bash
# Update .sops.yaml with new key
age-keygen -y ~/.config/sops/age/keys.txt

# Re-encrypt all secrets
./scripts/secrets-manager.sh re-encrypt-all
```

## Diagnostic Tools

### System Information
```bash
# System details
./scripts/system-manager.sh status NIXY

# Nix version and configuration
nix --version
nix show-config

# Darwin version (macOS)
sw_vers

# Hardware information
system_profiler SPHardwareDataType
```

### Configuration Validation
```bash
# Quick validation
./scripts/flake-check.sh

# Comprehensive testing
./scripts/test-framework.sh

# Specific component testing
./scripts/flake-check.sh --build-only
./scripts/flake-check.sh --secrets-only
```

### Log Analysis
```bash
# System logs (macOS)
log show --predicate 'process == "nix-daemon"' --last 1h

# Build logs
nix log .#darwinConfigurations.NIXY.system

# Home Manager logs
journalctl --user -u home-manager-alex.service
```

### Network Diagnostics
```bash
# Test binary cache connectivity
curl -I https://cache.nixos.org

# Check DNS resolution
nslookup cache.nixos.org

# Test download speed
nix-prefetch-url https://cache.nixos.org/nix-cache-info
```

## Getting Help

### Self-Help Resources

1. **Check Documentation**:
   - Read relevant sections in `docs/`
   - Check module documentation
   - Review example configurations

2. **Search Issues**:
   - Search GitHub issues in repository
   - Check NixOS/nixpkgs issues
   - Look for similar problems online

3. **Use Diagnostic Tools**:
   ```bash
   # Run comprehensive diagnostics
   ./scripts/test-framework.sh --verbose
   
   # Generate debug report
   ./scripts/system-manager.sh debug-report NIXY
   ```

### Community Support

1. **NixOS Community**:
   - NixOS Discourse: https://discourse.nixos.org
   - NixOS Reddit: https://reddit.com/r/NixOS
   - Matrix/IRC channels

2. **GitHub Issues**:
   - Create detailed issue reports
   - Include system information
   - Provide reproduction steps

3. **Documentation Contributions**:
   - Improve documentation
   - Add troubleshooting entries
   - Share solutions

### Creating Bug Reports

Include the following information:

```bash
# System information
uname -a
nix --version
darwin-rebuild --version  # macOS
home-manager --version

# Configuration details
nix flake show
./scripts/flake-check.sh --verbose

# Error logs
nix log .#darwinConfigurations.NIXY.system 2>&1 | tail -100

# Environment
env | grep -E "(NIX_|HOME|USER|PATH)"
```

### Emergency Contacts

For critical production issues:

1. **System Administrator**: Contact your system admin
2. **Team Lead**: Escalate to team leadership
3. **On-call Engineer**: Use established on-call procedures

---

This troubleshooting guide covers the most common issues you'll encounter. Keep it updated with new problems and solutions as they arise.